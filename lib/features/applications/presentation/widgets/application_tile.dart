import 'package:flutter/material.dart';

import '../../domain/entities/job_application.dart';

class ApplicationTile extends StatelessWidget {
  const ApplicationTile({super.key, required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.business_center_outlined)),
      title: Text(application.jobTitle),
      subtitle: Text(application.company),
      trailing: Text(applicationStatusLabel(application.status)),
    ),
  );
}

String applicationStatusLabel(ApplicationStatus status) => switch (status) {
  ApplicationStatus.submitted => 'Submitted',
  ApplicationStatus.reviewing => 'Reviewing',
  ApplicationStatus.interview => 'Interview',
  ApplicationStatus.offer => 'Offer',
  ApplicationStatus.rejected => 'Closed',
};
