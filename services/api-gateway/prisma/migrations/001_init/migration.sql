CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE user_role AS ENUM ('JOB_SEEKER', 'RECRUITER', 'ADMIN');
CREATE TYPE job_status AS ENUM ('DRAFT', 'PUBLISHED', 'ARCHIVED');
CREATE TYPE application_status AS ENUM ('SUBMITTED', 'REVIEWING', 'INTERVIEW', 'OFFER', 'REJECTED');

CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), oidc_subject text NOT NULL UNIQUE,
  email text NOT NULL UNIQUE, display_name text NOT NULL, role user_role NOT NULL DEFAULT 'JOB_SEEKER', created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), owner_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  name text NOT NULL, logo_url text, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), company_id uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  title text NOT NULL, description text NOT NULL, location text NOT NULL, employment_type text NOT NULL,
  workplace text NOT NULL, salary_min integer, salary_max integer, status job_status NOT NULL DEFAULT 'DRAFT',
  posted_at timestamptz, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
  search_document tsvector GENERATED ALWAYS AS (to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(description, '') || ' ' || coalesce(location, ''))) STORED
);
CREATE TABLE bookmarks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  job_id uuid NOT NULL REFERENCES jobs(id) ON DELETE CASCADE, created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(user_id, job_id)
);
CREATE TABLE applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  job_id uuid NOT NULL REFERENCES jobs(id) ON DELETE CASCADE, resume_url text NOT NULL,
  status application_status NOT NULL DEFAULT 'SUBMITTED', applied_at timestamptz NOT NULL DEFAULT now(), UNIQUE(user_id, job_id)
);
CREATE INDEX jobs_search_idx ON jobs USING GIN(search_document);
CREATE INDEX jobs_published_idx ON jobs(status, posted_at DESC);
CREATE INDEX jobs_company_idx ON jobs(company_id);
CREATE INDEX bookmarks_user_idx ON bookmarks(user_id, created_at DESC);
CREATE INDEX applications_user_idx ON applications(user_id, applied_at DESC);
CREATE INDEX applications_job_status_idx ON applications(job_id, status);
