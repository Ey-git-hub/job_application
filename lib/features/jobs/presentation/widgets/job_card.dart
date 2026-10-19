import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/job.dart';
import '../providers/job_providers.dart';

class JobCard extends ConsumerWidget {
  const JobCard({super.key, required this.job, this.onOpen});

  final Job job;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xffe1e6ea)),
    ),
    child: InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Color(job.logoColor),
                  radius: 17,
                  child: Text(
                    job.logoLetter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(job.company),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.read(jobFeedProvider.notifier).toggleBookmark(job.id),
                  icon: Icon(
                    job.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: const Color(0xff146ca4),
                    size: 21,
                  ),
                  tooltip: job.isBookmarked ? 'Remove bookmark' : 'Save job',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                job.jobType,
                job.workplace,
                job.salary,
              ].map((tag) => _JobTag(label: tag)).toList(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: Color(0xff5f6b76),
                ),
                const SizedBox(width: 3),
                Text(job.location),
                const Spacer(),
                Text(job.postedLabel),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _JobTag extends StatelessWidget {
  const _JobTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xff146ca4),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
