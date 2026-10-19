import 'package:job_application/features/applications/domain/entities/application_status.dart';

class JobApplication {
  const JobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.status,
    required this.appliedAt,
  });

  final String id;
  final String jobId;
  final String jobTitle;
  final String company;
  final ApplicationStatus status;
  final DateTime appliedAt;
}


