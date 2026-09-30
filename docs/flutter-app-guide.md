# Flutter App Guide for Beginners

This guide explains only the Flutter app inside this project. It is written like we are teaching a very curious five-year-old who wants to know how every toy works.

## 1. The Big Picture

Imagine the app is a little restaurant:

- **The screen** is the dining room. It shows buttons, cards, text, and icons.
- **The provider** is the waiter. It remembers what the user is doing and tells the screen when something changes.
- **The repository** is the kitchen. It finds the jobs and sends them back.
- **The entity** is the menu card. It describes what a job looks like.
- **The test** is a friendly inspector. It clicks things to make sure they work.

The app flow is:

```text
User taps or types
        |
        v
JobHomePage sends a request
        |
        v
JobFeedController changes the state
        |
        v
JobRepository finds jobs
        |
        v
Riverpod tells the screen to draw again
```

## 2. Where the Flutter Code Lives

```text
lib/
  main.dart                              Starts the app
  domain/
    entities/
      job.dart                           Describes one job
      job_application.dart               Describes one application
    repositories/
      job_repository.dart                Says what job data must do
  data/
    repositories/
      in_memory_job_repository.dart      Provides demo jobs
    auth/
      secure_token_store.dart            Stores login tokens safely
  presentation/
    pages/
      job_home_page.dart                 Draws the visible app
    providers/
      job_providers.dart                 Controls job search and bookmarks
      application_providers.dart         Controls applications

test/
  widget_test.dart                       Checks the app by clicking it
```

The folders have different jobs. Keeping them separate makes the project easier to understand and easier to change later.

## 3. The App Starts in `main.dart`

File: `lib/main.dart`

The most important line is:

```dart
void main() => runApp(const ProviderScope(child: JobSearchApp()));
```

Read it from the inside out:

1. `JobSearchApp` is our app.
2. `ProviderScope` gives Riverpod a place to keep information.
3. `runApp` puts the app on the phone screen.
4. `main` is the first function Flutter calls.

`JobSearchApp` builds the general app shell:

```dart
return MaterialApp(
  title: 'Job Search',
  theme: ThemeData(...),
  home: const JobHomePage(),
);
```

This means:

- Give the app a name.
- Choose colors, fonts, and sizes.
- Show `JobHomePage` first.

`MaterialApp` is like a box of ready-made Flutter furniture. It gives us navigation, themes, dialogs, buttons, and many other useful things.

## 4. Entities Are Data Shapes

File: `lib/domain/entities/job.dart`

A `Job` is a description of one job:

```dart
class Job {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    // more fields...
  });

  final String id;
  final String title;
  final String company;
}
```

Think of a job as a labeled box:

```text
id          = job-1
title       = Senior Flutter Developer
company     = TechFlow Inc.
location    = San Francisco, CA
workplace   = Remote
```

`final` means the label cannot be changed after the box is created. This is useful because data objects should not quietly change behind our back.

### Why does `Job` have `copyWith`?

A job is mostly fixed, but its bookmark status can change. Instead of damaging the old job, `copyWith` makes a new job with one changed value:

```dart
final updatedJob = oldJob.copyWith(isBookmarked: true);
```

This is like making a photocopy of a worksheet and coloring the bookmark on the copy.

`JobApplication` works similarly. It remembers:

- Which job was used.
- The job title and company.
- The application status.
- When the application was created.

`ApplicationStatus` is an enum. An enum is a small list of allowed words:

```dart
enum ApplicationStatus { submitted, reviewing, interview, offer, rejected }
```

The app cannot accidentally invent a status like `maybe-later` unless we add it to this list.

## 5. Repositories Explain Where Data Comes From

File: `lib/domain/repositories/job_repository.dart`

The repository interface is a promise:

```dart
abstract interface class JobRepository {
  Future<List<Job>> searchJobs({
    String query = '',
    String category = 'All',
    String workplace = 'All',
  });
}
```

It says:

> “Any job data source must know how to search for jobs.”

It does not say whether the jobs come from memory, a web API, or a database. That decision belongs somewhere else.

### The current demo repository

File: `lib/data/repositories/in_memory_job_repository.dart`

The current app uses a small list stored in the program:

```dart
static const _jobs = [
  Job(...),
  Job(...),
];
```

This is excellent for learning and for a screen that works without a server. It is not permanent storage. Closing the app resets the demo data.

When searching, the repository:

1. Makes the search text lowercase.
2. Looks in the job title, company, and location.
3. Checks the selected category.
4. Checks the selected workplace.
5. Returns only jobs that match.

The word `Future` means the answer may arrive a little later. Searching a real server takes time, so Flutter must be ready to wait.

## 6. Riverpod Is the App's Memory

Files:

- `lib/presentation/providers/job_providers.dart`
- `lib/presentation/providers/application_providers.dart`

Riverpod helps widgets share information without passing it through every constructor.

### The job provider

```dart
final jobFeedProvider =
    StateNotifierProvider<JobFeedController, AsyncValue<List<Job>>>(
  (ref) => JobFeedController(ref.read(jobRepositoryProvider)),
);
```

This says:

- Create one `JobFeedController`.
- Give it a job repository.
- Its state is an `AsyncValue<List<Job>>`.

`AsyncValue` has three important moods:

```text
AsyncLoading  = “I am still looking.”
AsyncData     = “Here are the jobs.”
AsyncError    = “Something went wrong.”
```

### The controller

`JobFeedController` remembers:

```dart
String _query = '';
String _category = 'All';
String _workplace = 'All';
```

When the user types, the page calls:

```dart
ref.read(jobFeedProvider.notifier).search(value);
```

The controller saves the text and loads jobs again.

When the user picks a category, it calls:

```dart
ref.read(jobFeedProvider.notifier).selectCategory(category);
```

When the user picks Remote, Hybrid, or On-Site, it calls:

```dart
ref.read(jobFeedProvider.notifier).setWorkplace(workplace);
```

### How bookmarks work

The controller keeps a set of bookmarked job IDs:

```dart
final Set<String> _bookmarkedIds = {};
```

A `Set` is like a bag that keeps each sticker only once. When a bookmark button is tapped, the job ID is added or removed. Then the controller sends a new list to the screen.

This keeps bookmarks while the user searches. In the current demo, the set lives only while the app is running.

### Applications provider

`applicationsProvider` keeps submitted applications in a list. Its `apply` method refuses to add the same job twice:

```dart
if (state.any((application) => application.jobId == job.id)) return;
```

That is a small but important rule: one person should not accidentally apply to the same job twice from this screen.

## 7. The Page Draws the Screen

File: `lib/presentation/pages/job_home_page.dart`

`JobHomePage` is a `ConsumerStatefulWidget` because it needs two things:

- `StatefulWidget`: it remembers the selected bottom tab and search text.
- `ConsumerWidget` behavior: it can read Riverpod providers.

The page watches the job feed:

```dart
final jobs = ref.watch(jobFeedProvider);
```

`watch` means:

> “Please rebuild this part when the provider changes.”

The page then draws the correct state:

```dart
jobs.when(
  loading: () => const CircularProgressIndicator(),
  error: (error, stackTrace) => const Text('Unable to load jobs'),
  data: (items) => /* draw job cards */,
);
```

This is why the user sees a spinner while jobs load and cards when jobs arrive.

## 8. Understanding the Main Screen Pieces

### Search box

The search box has a controller and an `onChanged` callback:

```dart
TextField(
  controller: _searchController,
  onChanged: (value) =>
      ref.read(jobFeedProvider.notifier).search(value),
)
```

Every time the user types a letter, the controller searches again.

- `controller` lets the code read or clear the text.
- `onChanged` runs after the text changes.
- `ref.read(...notifier)` gets the controller that can change state.

### Category chips

The category row uses `ChoiceChip`. When one is selected:

```dart
setState(() => _selectedCategory = category);
ref.read(jobFeedProvider.notifier).selectCategory(category);
```

There are two updates:

1. `setState` changes which chip looks selected.
2. Riverpod searches for matching jobs.

### Job cards

Each `_JobCard` receives one `Job`:

```dart
_JobCard(job: items[index])
```

The card displays the job's title, company, tags, location, salary, and posting age. Its bookmark icon calls:

```dart
ref.read(jobFeedProvider.notifier).toggleBookmark(job.id)
```

The card can also open the details sheet. The details sheet contains the **Apply now** button, which calls:

```dart
ref.read(applicationsProvider.notifier).apply(job);
```

### Bottom navigation

The page remembers the selected tab:

```dart
int _selectedTab = 0;
```

When the user taps a destination:

```dart
onDestinationSelected: (index) =>
    setState(() => _selectedTab = index)
```

The page then decides what to draw:

```text
0 = Home
1 = Saved jobs
2 = Applications
3 = Messages
4 = Profile
```

The Messages and Profile screens are currently friendly informational screens. They are safe places to add real features later.

## 9. Secure Token Storage

File: `lib/data/auth/secure_token_store.dart`

`SecureTokenStore` uses `flutter_secure_storage` instead of ordinary preferences:

```dart
await _storage.write(
  key: _accessTokenKey,
  value: accessToken,
);
```

The operating system protects these values using its secure storage system.

The class can:

- Save an access token and refresh token.
- Read either token.
- Delete both during logout.

This class does not perform login by itself. It is only the locked box where tokens are kept after an authentication flow gives them to the app.

## 10. One Complete User Story

Let us follow the user searching for “Data Analyst”:

1. The user types `Data Analyst` into the `TextField`.
2. `onChanged` calls `JobFeedController.search`.
3. The controller stores the query.
4. The controller calls `load`.
5. `load` calls `InMemoryJobRepository.searchJobs`.
6. The repository finds the matching job.
7. The controller changes its state to `AsyncData`.
8. Riverpod notices the state change.
9. The page rebuilds.
10. The Data Analyst card appears.

The UI does not search by itself. The UI asks the controller, and the controller asks the repository. Each part has one job.

## 11. How the Test Checks the App

File: `test/widget_test.dart`

The test creates the same Riverpod wrapper used by the real app:

```dart
await tester.pumpWidget(
  const ProviderScope(child: JobSearchApp()),
);
```

Then it acts like a tiny robot user:

1. Waits for the screen.
2. Checks that the job title exists.
3. Taps a bookmark.
4. Opens Saved jobs.
5. Returns Home.
6. Types a search.
7. Checks that the correct job appears.

Useful test commands:

```text
flutter analyze
flutter test test/widget_test.dart
```

`flutter analyze` checks code structure and types. The widget test checks behavior.

## 12. How to Run the Flutter App

From the project root:

```text
flutter pub get
flutter run
```

To see available devices:

```text
flutter devices
```

To run on Windows, use a Windows device. To run in a browser, choose Chrome when Flutter asks for a device.

## 13. Safe Beginner Exercises

Try these one at a time:

1. Change the app title in `main.dart`.
2. Add a fifth demo job in `in_memory_job_repository.dart`.
3. Add a new category to `_categories` in `job_home_page.dart`.
4. Change the card color in `_Tag`.
5. Add a new application status to `ApplicationStatus`.
6. Add a test that taps **Applications** and checks for `Applications`.
7. Add a **Clear** icon to the search field that sets the controller text to an empty string.

After each small change, run:

```text
flutter analyze
flutter test test/widget_test.dart
```

## 14. Important Learning Note

The current Flutter app uses in-memory demo data. That means:

- Jobs are built into the app.
- Bookmarks disappear when the app closes.
- Applications disappear when the app closes.
- The secure token helper is ready, but login screens and API wiring are separate work.

That is intentional for learning. The code is small enough to understand. Later, the repository can be replaced with an HTTP repository without changing the page's basic job-search rules.

The main lesson is this:

```text
Widgets show things.
Providers remember things.
Repositories find things.
Entities describe things.
Tests protect things.
```
