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

enum ApplicationStatus { submitted, reviewing, interview, offer, rejected }
