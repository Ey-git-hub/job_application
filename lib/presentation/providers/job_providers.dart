import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_job_repository.dart';
import '../../domain/entities/job.dart';
import '../../domain/repositories/job_repository.dart';

final jobRepositoryProvider = Provider<JobRepository>(
  (ref) => InMemoryJobRepository(),
);
final jobFeedProvider =
    StateNotifierProvider<JobFeedController, AsyncValue<List<Job>>>(
      (ref) => JobFeedController(ref.read(jobRepositoryProvider)),
    );

class JobFeedController extends StateNotifier<AsyncValue<List<Job>>> {
  JobFeedController(this._repository) : super(const AsyncLoading()) {
    load();
  }

  final JobRepository _repository;
  final Set<String> _bookmarkedIds = {};
  String _query = '';
  String _category = 'All';
  String _workplace = 'All';

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      final jobs = await _repository.searchJobs(
        query: _query,
        category: _category,
        workplace: _workplace,
      );
      _bookmarkedIds.addAll(
        jobs.where((job) => job.isBookmarked).map((job) => job.id),
      );
      state = AsyncData([
        for (final job in jobs)
          job.copyWith(isBookmarked: _bookmarkedIds.contains(job.id)),
      ]);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> search(String value) async {
    _query = value;
    await load();
  }

  Future<void> selectCategory(String category) async {
    _category = category;
    await load();
  }

  Future<void> setWorkplace(String workplace) async {
    _workplace = workplace;
    await load();
  }

  void toggleBookmark(String id) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (_bookmarkedIds.contains(id)) {
      _bookmarkedIds.remove(id);
    } else {
      _bookmarkedIds.add(id);
    }
    state = AsyncData([
      for (final job in current)
        job.copyWith(isBookmarked: _bookmarkedIds.contains(job.id)),
    ]);
  }
}
