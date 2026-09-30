import '../entities/job.dart';

abstract interface class JobRepository {
  Future<List<Job>> searchJobs({
    String query = '',
    String category = 'All',
    String workplace = 'All',
  });
}
