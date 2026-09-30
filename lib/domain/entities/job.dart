class Job {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.postedLabel,
    required this.jobType,
    required this.workplace,
    required this.salary,
    required this.logoLetter,
    required this.logoColor,
    this.isBookmarked = false,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final String postedLabel;
  final String jobType;
  final String workplace;
  final String salary;
  final String logoLetter;
  final int logoColor;
  final bool isBookmarked;

  Job copyWith({bool? isBookmarked}) => Job(
    id: id,
    title: title,
    company: company,
    location: location,
    postedLabel: postedLabel,
    jobType: jobType,
    workplace: workplace,
    salary: salary,
    logoLetter: logoLetter,
    logoColor: logoColor,
    isBookmarked: isBookmarked ?? this.isBookmarked,
  );
}
