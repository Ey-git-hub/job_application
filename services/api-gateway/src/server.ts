import Fastify, { FastifyReply, FastifyRequest } from 'fastify';
import helmet from '@fastify/helmet';
import sensible from '@fastify/sensible';
import { Redis } from 'ioredis';
import { Pool } from 'pg';
import { jwtVerify, createRemoteJWKSet, JWTPayload } from 'jose';
import { z } from 'zod';

const env = z.object({
  PORT: z.coerce.number().int().positive().default(8080),
  REDIS_URL: z.string().url().default('redis://redis:6379'),
  OIDC_ISSUER: z.string().url(),
  OIDC_AUDIENCE: z.string().min(1),
  DATABASE_URL: z.string().min(1),
}).parse(process.env);

const redis = new Redis(env.REDIS_URL, { enableOfflineQueue: false, maxRetriesPerRequest: 2 });
const db = new Pool({ connectionString: env.DATABASE_URL, max: 20, idleTimeoutMillis: 30000, ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: true } : undefined });
const app = Fastify({ logger: { redact: ['req.headers.authorization', 'req.headers.cookie', '*.email', '*.salary'] } });
const jwks = createRemoteJWKSet(new URL(`${env.OIDC_ISSUER}/.well-known/jwks.json`));

const jobQuery = z.object({ q: z.string().trim().max(120).default(''), location: z.string().trim().max(120).default(''), page: z.coerce.number().int().min(1).max(10000).default(1), pageSize: z.coerce.number().int().min(1).max(50).default(20) });
const idParams = z.object({ id: z.string().uuid() });
const applicationBody = z.object({ jobId: z.string().uuid(), resumeUrl: z.string().url().max(2048) });
const jobBody = z.object({ title: z.string().trim().min(1).max(160), description: z.string().trim().min(1).max(20000), companyId: z.string().uuid(), location: z.string().trim().min(1).max(160), employmentType: z.string().trim().min(1).max(40), workplace: z.enum(['Remote', 'Hybrid', 'On-Site']), salaryMin: z.number().int().nonnegative().optional(), salaryMax: z.number().int().nonnegative().optional() }).refine((value) => value.salaryMax === undefined || value.salaryMin === undefined || value.salaryMax >= value.salaryMin, 'Invalid salary range');

type AuthClaims = JWTPayload & { sub: string; role?: 'JOB_SEEKER' | 'RECRUITER' | 'ADMIN' };
type AuthRequest = FastifyRequest & { user: AuthClaims };

async function authenticate(request: FastifyRequest, reply: FastifyReply): Promise<void> {
  const authorization = request.headers.authorization;
  if (!authorization?.startsWith('Bearer ')) return reply.unauthorized('Authentication required');
  try {
    const token = authorization.slice(7);
    const { payload } = await jwtVerify(token, jwks, { issuer: env.OIDC_ISSUER, audience: env.OIDC_AUDIENCE });
    if (typeof payload.sub !== 'string') throw new Error('Missing subject');
    (request as AuthRequest).user = payload as AuthClaims;
  } catch {
    return reply.unauthorized('Invalid authentication token');
  }
}

async function tokenBucket(request: FastifyRequest, reply: FastifyReply): Promise<void> {
  const key = `rate:${request.ip}`;
  const now = Date.now();
  const script = `local current = redis.call('HMGET', KEYS[1], 'tokens', 'updated')\nlocal tokens = tonumber(current[1]) or 60\nlocal updated = tonumber(current[2]) or ARGV[1]\nlocal elapsed = math.max(0, tonumber(ARGV[1]) - updated)\ntokens = math.min(60, tokens + elapsed * 60 / 60000)\nif tokens < 1 then redis.call('HSET', KEYS[1], 'tokens', tokens, 'updated', ARGV[1]); redis.call('EXPIRE', KEYS[1], 120); return 0 end\nredis.call('HSET', KEYS[1], 'tokens', tokens - 1, 'updated', ARGV[1]); redis.call('EXPIRE', KEYS[1], 120); return 1`;
  const allowed = await redis.eval(script, 1, key, now);
  if (allowed !== 1) return reply.tooManyRequests('Rate limit exceeded');
}

function requireRole(role: AuthClaims['role'], reply: FastifyReply): boolean {
  if (role !== 'RECRUITER' && role !== 'ADMIN') { reply.forbidden('Insufficient permissions'); return false; }
  return true;
}

app.register(helmet, { global: true, contentSecurityPolicy: false });
app.register(sensible);
app.addHook('onRequest', tokenBucket);
app.get('/healthz', async () => ({ status: 'ok' }));
app.get('/readyz', async (_request, reply) => {
  try { await Promise.all([redis.ping(), db.query('SELECT 1')]); return { status: 'ready' }; } catch { return reply.serviceUnavailable('Dependencies unavailable'); }
});

app.get('/v1/jobs', async (request) => {
  const query = jobQuery.parse(request.query);
  const version = await redis.get('jobs:version') ?? '0';
  const cacheKey = `jobs:${version}:${JSON.stringify(query)}`;
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached) as unknown;
  const offset = (query.page - 1) * query.pageSize;
  const search = query.q ? `${query.q}:*` : '';
  const result = await db.query(
    `SELECT id, title, company_id AS "companyId", location, employment_type AS "employmentType", workplace, salary_min AS "salaryMin", salary_max AS "salaryMax", posted_at AS "postedAt"
     FROM jobs
     WHERE status = 'PUBLISHED'
       AND ($1 = '' OR search_document @@ websearch_to_tsquery('simple', $1))
       AND ($2 = '' OR location ILIKE $3)
     ORDER BY posted_at DESC
     LIMIT $4 OFFSET $5`,
    [search, query.location, `%${query.location}%`, query.pageSize, offset],
  );
  const count = await db.query(
    `SELECT count(*)::int AS total FROM jobs WHERE status = 'PUBLISHED' AND ($1 = '' OR search_document @@ websearch_to_tsquery('simple', $1)) AND ($2 = '' OR location ILIKE $3)`,
    [search, query.location, `%${query.location}%`],
  );
  const payload = { data: result.rows, page: query.page, pageSize: query.pageSize, total: count.rows[0]?.total ?? 0 };
  await redis.set(cacheKey, JSON.stringify(payload), 'EX', 30);
  return payload;
});

app.post('/v1/jobs', { preHandler: authenticate }, async (request, reply) => {
  const user = (request as AuthRequest).user;
  if (!requireRole(user.role, reply)) return;
  const body = jobBody.parse(request.body);
  const result = await db.query(
    `INSERT INTO jobs (company_id, title, description, location, employment_type, workplace, salary_min, salary_max, status, posted_at)
     SELECT c.id, $2, $3, $4, $5, $6, $7, $8, 'PUBLISHED', now()
     FROM companies c JOIN users u ON u.id = c.owner_id
     WHERE c.id = $1 AND u.oidc_subject = $9 RETURNING jobs.id`,
    [body.companyId, body.title, body.description, body.location, body.employmentType, body.workplace, body.salaryMin ?? null, body.salaryMax ?? null, user.sub],
  );
  if (result.rowCount !== 1) return reply.forbidden('Company access denied');
  await redis.incr('jobs:version');
  return reply.code(201).send({ id: result.rows[0].id });
});

app.post('/v1/applications', { preHandler: authenticate }, async (request, reply) => {
  const body = applicationBody.parse(request.body);
  const user = (request as AuthRequest).user;
  const idempotencyKey = request.headers['idempotency-key'];
  if (typeof idempotencyKey !== 'string' || !/^[A-Za-z0-9._-]{16,128}$/.test(idempotencyKey)) return reply.badRequest('A valid Idempotency-Key is required');
  const lockKey = `application:${user.sub}:${idempotencyKey}`;
  const acquired = await redis.set(lockKey, '1', 'EX', 86400, 'NX');
  if (acquired !== 'OK') return reply.conflict('Request already processed');
  return reply.code(202).send({ status: 'submitted', jobId: body.jobId });
});

app.put('/v1/bookmarks/:id', { preHandler: authenticate }, async (request, reply) => {
  const { id } = idParams.parse(request.params);
  const user = (request as AuthRequest).user;
  const ownershipKey = `bookmark-owner:${id}`;
  const owner = await redis.get(ownershipKey);
  if (owner !== null && owner !== user.sub) return reply.forbidden('Resource access denied');
  await redis.set(ownershipKey, user.sub, 'EX', 86400, 'NX');
  return reply.code(204).send();
});

app.setErrorHandler((error, request, reply) => {
  request.log.error({ err: error, route: request.routeOptions.url }, 'request failed');
  if (error instanceof z.ZodError) return reply.badRequest('Invalid request');
  if (reply.sent) return;
  return reply.internalServerError('Request could not be completed');
});

const shutdown = async () => { await app.close(); await db.end(); await redis.quit(); process.exit(0); };
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
app.listen({ port: env.PORT, host: '0.0.0.0' }).catch((error) => { app.log.error(error); process.exit(1); });
