import '../../domain/entities/job.dart';
import '../../domain/repositories/job_repository.dart';

class InMemoryJobRepository implements JobRepository {
  static const _jobs = [
    Job(
      id: 'job-1',
      title: 'Senior Flutter Developer',
      company: 'TechFlow Inc.',
      location: 'San Francisco, CA',
      postedLabel: '2 days ago',
      jobType: 'Full-Time',
      workplace: 'Remote',
      salary: '\$120k - \$150k',
      logoLetter: 'T',
      logoColor: 0xff1689c7,
      isBookmarked: true,
    ),
    Job(
      id: 'job-2',
      title: 'Product UI/UX Designer',
      company: 'Innovate Apps',
      location: 'New York, NY',
      postedLabel: '3 hours ago',
      jobType: 'Contract',
      workplace: 'On-Site',
      salary: '\$95k - \$125k',
      logoLetter: 'i',
      logoColor: 0xffe8912d,
    ),
    Job(
      id: 'job-3',
      title: 'Data Analyst',
      company: 'DataSphere',
      location: 'Austin, TX',
      postedLabel: '5 days ago',
      jobType: 'Full-Time',
      workplace: 'Hybrid',
      salary: '\$85k - \$110k',
      logoLetter: 'D',
      logoColor: 0xff1c9b72,
      isBookmarked: true,
    ),
    Job(
      id: 'job-4',
      title: 'Cloud Infrastructure Engineer',
      company: 'Global Systems',
      location: 'Seattle, WA',
      postedLabel: '1 week ago',
      jobType: 'Full-Time',
      workplace: 'Remote',
      salary: '\$130k - \$165k',
      logoLetter: 'G',
      logoColor: 0xff7028a0,
    ), Job(
      id: 'job-5',
      title: 'Senior backend Developer',
      company: 'TechFlow Inc.',
      location: 'Addis ababa, MEXICO',
      postedLabel: '3 days ago',
      jobType: 'Part-Time',
      workplace: 'Remote',
      salary: '\$120k - \$150k',
      logoLetter: 'T',
      logoColor: 0xff1689c7,
      isBookmarked: true,
    )
  ];

  @override
  Future<List<Job>> searchJobs({
    String query = '',
    String category = 'All',
    String workplace = 'All',
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    return _jobs.where((job) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          '${job.title} ${job.company} ${job.location}'.toLowerCase().contains(
            normalizedQuery,
          );
      final matchesCategory =
          category == 'All' ||
          job.title.toLowerCase().contains(category.toLowerCase());
      final matchesWorkplace = workplace == 'All' || job.workplace == workplace;
      return matchesQuery && matchesCategory && matchesWorkplace;
    }).toList();
  }
}
