import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/job.dart';
import '../../domain/entities/job_application.dart';

final applicationsProvider =
    StateNotifierProvider<ApplicationsController, List<JobApplication>>(
      (ref) => ApplicationsController(),
    );

class ApplicationsController extends StateNotifier<List<JobApplication>> {
  ApplicationsController() : super(const []);

  void apply(Job job) {
    if (state.any((application) => application.jobId == job.id)) return;
    state = [
      ...state,
      JobApplication(
        id: 'application-${job.id}',
        jobId: job.id,
        jobTitle: job.title,
        company: job.company,
        status: ApplicationStatus.submitted,
        appliedAt: DateTime.now(),
      ),
    ];
  }
}
