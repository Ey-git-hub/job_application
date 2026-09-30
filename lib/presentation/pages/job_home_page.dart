import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/job.dart';
import '../../domain/entities/job_application.dart';
import '../providers/application_providers.dart';
import '../providers/job_providers.dart';

class JobHomePage extends ConsumerStatefulWidget {
  const JobHomePage({super.key});

  @override
  ConsumerState<JobHomePage> createState() => _JobHomePageState();
}

class _JobHomePageState extends ConsumerState<JobHomePage> {
  final _searchController = TextEditingController();
  int _selectedTab = 0;
  String _selectedCategory = 'All';
  static const _categories = [
    'All',
    'Software Engineer',
    'Product Manager',
    'UI/UX Designer',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobs = ref.watch(jobFeedProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _tabBody(jobs)),
            _bottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _tabBody(AsyncValue<List<Job>> jobs) {
    if (_selectedTab == 1) {
      return _savedBody(jobs.valueOrNull ?? const []);
    }
    if (_selectedTab == 2) {
      return _applicationsBody();
    }
    if (_selectedTab == 3) {
      return _simpleTab(
        'Messages',
        Icons.chat_bubble_outline,
        'Your recruiter conversations will appear here.',
      );
    }
    if (_selectedTab == 4) {
      return _simpleTab(
        'Profile',
        Icons.person_outline,
        'Manage your profile and job preferences.',
      );
    }
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          sliver: SliverToBoxAdapter(child: _header()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          sliver: SliverToBoxAdapter(child: _categoryStrip()),
        ),
        jobs.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => const SliverFillRemaining(
            child: Center(child: Text('Unable to load jobs')),
          ),
          data: (items) => SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => _JobCard(
                job: items[index],
                onOpen: () => _showJobDetails(items[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Job Search', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  ref.read(jobFeedProvider.notifier).search(value),
              decoration: InputDecoration(
                hintText: 'Search for jobs...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xffd5dbe0)),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _showFilters,
            icon: const Icon(Icons.tune, size: 21),
            tooltip: 'Filter jobs',
          ),
        ],
      ),
    ],
  );

  Widget _categoryStrip() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: _categories.map((category) {
        final selected = category == _selectedCategory;
        return Padding(
          padding: const EdgeInsets.only(right: 7),
          child: ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) {
              setState(() => _selectedCategory = category);
              ref.read(jobFeedProvider.notifier).selectCategory(category);
            },
            labelStyle: TextStyle(
              fontSize: 11,
              color: selected ? Colors.white : const Color(0xff5f6b76),
            ),
            selectedColor: const Color(0xff146ca4),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xffd5dbe0)),
            visualDensity: VisualDensity.compact,
          ),
        );
      }).toList(),
    ),
  );

  Widget _savedBody(List<Job> jobs) {
    final saved = jobs.where((job) => job.isBookmarked).toList();
    return _contentScaffold(
      title: 'Saved jobs',
      child: saved.isEmpty
          ? _emptyState(
              Icons.bookmark_border,
              'No saved jobs',
              'Bookmark a job to find it here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              itemCount: saved.length,
              itemBuilder: (context, index) => _JobCard(job: saved[index]),
            ),
    );
  }

  Widget _applicationsBody() {
    final applications = ref.watch(applicationsProvider);
    return _contentScaffold(
      title: 'Applications',
      child: applications.isEmpty
          ? _emptyState(
              Icons.business_center_outlined,
              'No applications yet',
              'Open a job and apply to start tracking your progress.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              itemCount: applications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _ApplicationTile(application: applications[index]),
            ),
    );
  }

  Widget _contentScaffold({required String title, required Widget child}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(child: child),
        ],
      );

  Widget _simpleTab(String title, IconData icon, String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: const Color(0xff146ca4)),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );

  Widget _emptyState(IconData icon, String title, String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: const Color(0xff146ca4)),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );

  Future<void> _showFilters() async {
    final workplace = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Filter jobs'),
              subtitle: Text('Choose a workplace type'),
            ),
            for (final option in ['All', 'Remote', 'Hybrid', 'On-Site'])
              ListTile(
                leading: const Icon(Icons.work_outline),
                title: Text(option),
                onTap: () => Navigator.pop(context, option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || workplace == null) return;
    ref.read(jobFeedProvider.notifier).setWorkplace(workplace);
  }

  Future<void> _showJobDetails(Job job) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(job.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(job.company, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 14),
              Text('${job.location}  •  ${job.workplace}  •  ${job.salary}'),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  ref.read(applicationsProvider.notifier).apply(job);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Application submitted')),
                  );
                },
                icon: const Icon(Icons.send_outlined),
                label: const Text('Apply now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavigation() => NavigationBar(
    selectedIndex: _selectedTab,
    onDestinationSelected: (index) => setState(() => _selectedTab = index),
    height: 72,
    backgroundColor: Colors.white,
    indicatorColor: const Color(0xffe1f1fa),
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.bookmark_border),
        selectedIcon: Icon(Icons.bookmark),
        label: 'Saved',
      ),
      NavigationDestination(
        icon: Icon(Icons.business_center_outlined),
        selectedIcon: Icon(Icons.business_center),
        label: 'Applications',
      ),
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        selectedIcon: Icon(Icons.chat_bubble),
        label: 'Messages',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ],
  );
}

class _JobCard extends ConsumerWidget {
  const _JobCard({required this.job, this.onOpen});

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
              ].map((tag) => _Tag(label: tag)).toList(),
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

class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.business_center_outlined)),
      title: Text(application.jobTitle),
      subtitle: Text(application.company),
      trailing: Text(_statusLabel(application.status)),
    ),
  );
}

String _statusLabel(ApplicationStatus status) => switch (status) {
  ApplicationStatus.submitted => 'Submitted',
  ApplicationStatus.reviewing => 'Reviewing',
  ApplicationStatus.interview => 'Interview',
  ApplicationStatus.offer => 'Offer',
  ApplicationStatus.rejected => 'Closed',
};

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

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
