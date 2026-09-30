# Flutter App Guide: Learn by Building

This guide is for learning how to write this Flutter app yourself. Do not read it only as documentation. Open the project, type the examples, make small changes, and use the tests to check your thinking.

The goal is not to memorize Flutter classes. The goal is to learn a repeatable process:

```text
understand the requirement
        -> model the data
        -> write the behavior
        -> connect the screen
        -> test the result
```

## 1. Start Here

From the project root, run:

```text
flutter pub get
flutter devices
flutter run
```

If Flutter asks for a device, choose a device that is available. You can use Chrome, Windows, Android, or another configured target.

Before changing code, answer these questions:

1. What does the user see?
2. What can the user do?
3. What data must the app remember?
4. What should happen when something fails?

For this app, the first answers are:

- The user sees job cards, search, filters, saved jobs, and applications.
- The user can search, filter, bookmark, open a job, and apply.
- The app remembers the current search, bookmarks, and applications while it is running.
- The screen shows loading or error UI when the data operation is not ready or fails.

## 2. Learn the Project Map

Start with these files in this order:

```text
lib/main.dart
lib/domain/entities/job.dart
lib/domain/repositories/job_repository.dart
lib/data/repositories/in_memory_job_repository.dart
lib/presentation/providers/job_providers.dart
lib/presentation/pages/job_home_page.dart
test/widget_test.dart
```

Each folder has one main responsibility:

- `domain/entities` describes data.
- `domain/repositories` describes what data operations are possible.
- `data/repositories` implements those operations.
- `presentation/providers` stores changing state and coordinates operations.
- `presentation/pages` builds the visible interface.
- `test` checks behavior from a user's point of view.

Do not try to understand every line on the first pass. Follow one value through the app. For example, follow the text `Data Analyst` from the search field to the repository and back to the job card.

## 3. Dart Basics Used in This App

### Variables and types

```dart
String query = '';
int selectedTab = 0;
bool isBookmarked = false;
final categories = ['All', 'Designer'];
```

The type describes what a variable can contain. `String` is text, `int` is a whole number, and `bool` is `true` or `false`.

`final` means the variable can be assigned once:

```dart
final name = 'Amina';
```

Use `final` when the variable itself should not point to a different value later. A `final` list can still contain mutable items, so `final` does not automatically make every object immutable.

### Functions

```dart
String greeting(String name) {
  return 'Hello, $name';
}
```

The part before the function name is the return type. The text inside parentheses is the input. A short function can use `=>`:

```dart
String greeting(String name) => 'Hello, $name';
```

The `$name` syntax inserts a value into a string.

### Classes and constructors

```dart
class Person {
  const Person({required this.name});

  final String name;
}
```

`class` creates a new type. The constructor creates an object of that type. `required` means the caller must provide the named value. `this.name` assigns the constructor argument to the field.

### Null safety

```dart
String title = 'Developer';
String? optionalTitle;
```

`String` cannot be null. `String?` can be null. When you have a nullable value, handle the missing case rather than guessing:

```dart
final label = optionalTitle ?? 'No title';
```

`??` uses the value on the right when the value on the left is null.

### Collections and loops

```dart
final remoteJobs = jobs.where((job) => job.workplace == 'Remote').toList();

for (final job in remoteJobs) {
  print(job.title);
}
```

`where` keeps matching items. `map` transforms items. `toList()` turns the result into a list. Read these methods as a sentence: "from jobs, keep jobs whose workplace is Remote."

### Futures and async code

```dart
Future<List<Job>> loadJobs() async {
  return repository.searchJobs();
}

final jobs = await loadJobs();
```

`Future<T>` means a `T` value will be available later. `async` allows `await`. `await` pauses this function until the future completes without freezing the whole app.

## 4. Understand App Startup

Open `lib/main.dart` and read this line from the inside out:

```dart
void main() => runApp(const ProviderScope(child: JobSearchApp()));
```

1. `JobSearchApp` is the root widget.
2. `ProviderScope` gives Riverpod a place to store provider state.
3. `runApp` tells Flutter which widget is the root of the screen.
4. `main` is the first function Dart runs.

The root widget returns a `MaterialApp`:

```dart
return MaterialApp(
  title: 'Job Search',
  theme: ThemeData(...),
  home: const JobHomePage(),
);
```

`MaterialApp` supplies app-level configuration such as the theme and the first page. `home` is the widget shown first.

### Exercise: make a first change

Change the title text in `main.dart`, run the app, and identify whether the changed value appears in the device title, the page heading, or both. Then restore or intentionally update the other value in `job_home_page.dart`.

Run after the change:

```text
flutter analyze
```

The purpose of this exercise is to notice that two pieces of text can look related while coming from different code locations.

## 5. Model One Job

Open `lib/domain/entities/job.dart`. The `Job` class is the data shape used by the rest of the app:

```dart
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
}
```

When adding a field, ask three questions:

1. What type is it?
2. Must every job provide it?
3. Which screen or behavior uses it?

The `const` constructor and `final` fields make a job object stable after creation. Stable objects are easier to reason about because another part of the app cannot silently change them.

### Why `copyWith` exists

Bookmarking changes one property of a job. The app creates a new job instead of changing the old object:

```dart
final savedJob = job.copyWith(isBookmarked: true);
```

This is the important idea:

```text
old job + one new value = new job
```

### Exercise: add a field

Add a field called `employmentType`, then update all `Job(...)` constructors in the in-memory repository and display the value on the job card. The analyzer will show every constructor call you forgot to update.

This is a useful professional habit: let compiler errors identify the places affected by a data-model change.

## 6. Create a Data Source

Open `lib/domain/repositories/job_repository.dart`. The repository is an interface, or contract:

```dart
abstract interface class JobRepository {
  Future<List<Job>> searchJobs({
    String query = '',
    String category = 'All',
    String workplace = 'All',
  });
}
```

The interface says what the app needs, not how the data is stored. A repository could use a list, an HTTP API, or a database and still satisfy this contract.

Open `lib/data/repositories/in_memory_job_repository.dart`. This implementation stores demo jobs in a list and filters them. Learn the filtering as a sequence:

1. Normalize the search query with lowercase text.
2. Check title, company, and location.
3. Keep the selected category or accept all categories.
4. Keep the selected workplace or accept all workplaces.
5. Return the matching jobs.

The current implementation returns a `Future` even though the data is local. That keeps the interface realistic: a future HTTP implementation will also return data later.

### Exercise: add a job

Add one `Job` to the repository. Before running the app, predict:

- Where will the job appear?
- Which search terms will find it?
- Which category and workplace filters will include it?

Then run the app and test each prediction manually. Add a widget test if the job is important to the app.

## 7. Manage State with Riverpod

Open `lib/presentation/providers/job_providers.dart`. There are two important layers:

```dart
final jobRepositoryProvider = Provider<JobRepository>(
  (ref) => InMemoryJobRepository(),
);
```

This provider creates the repository. The UI does not need to know which repository implementation is being used.

```dart
final jobFeedProvider =
    StateNotifierProvider<JobFeedController, AsyncValue<List<Job>>>(
      (ref) => JobFeedController(ref.read(jobRepositoryProvider)),
    );
```

This provider creates the controller and gives it the repository. The controller owns the job-feed state.

### Read, watch, and change

Inside a Riverpod widget:

```dart
final jobs = ref.watch(jobFeedProvider);
```

`watch` reads the value and rebuilds the widget when it changes.

```dart
ref.read(jobFeedProvider.notifier).search(value);
```

`read` gets a value once. `.notifier` gets the controller so the widget can call an action.

Use this rule:

```text
watch for data the widget displays
read for an action the user just triggered
```

### Understand `AsyncValue`

The controller state can be:

```text
AsyncLoading  -> the operation is running
AsyncData     -> the operation succeeded
AsyncError    -> the operation failed
```

The page handles all three with:

```dart
jobs.when(
  loading: () => const CircularProgressIndicator(),
  error: (error, stackTrace) => const Text('Unable to load jobs'),
  data: (items) => SliverList.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => _JobCard(job: items[index]),
  ),
);
```

### Trace a search

When the user types into the search field:

1. `TextField.onChanged` receives the new text.
2. It calls `jobFeedProvider.notifier.search(value)`.
3. `search` stores the query and calls `load`.
4. `load` asks the repository for matching jobs.
5. The controller changes state to `AsyncData` or `AsyncError`.
6. `ref.watch(jobFeedProvider)` notices the change.
7. Flutter rebuilds the job list.

### Exercise: add a controller action

Add a `clearSearch` method to the controller. Decide whether it should only change the controller state or also clear the `TextEditingController` in the page. You will discover an important boundary: the provider owns job data, while the page owns the text field object.

## 8. Build the Screen

Open `lib/presentation/pages/job_home_page.dart`. `JobHomePage` is a `ConsumerStatefulWidget` because it needs both kinds of behavior:

- `StatefulWidget` behavior for local values such as the selected bottom tab.
- Riverpod behavior for watching and changing shared application state.

The page watches the feed:

```dart
final jobs = ref.watch(jobFeedProvider);
```

The `build` method returns a widget tree. Flutter calls `build` again when watched state or local state changes.

### Local state versus shared state

Keep state local when only this page needs it:

```dart
int _selectedTab = 0;
String _selectedCategory = 'All';
```

Use a provider when multiple widgets need the value or when it represents application behavior:

```dart
final _bookmarkedIds = <String>{};
```

In this app, bookmark state belongs in the job controller because searching and the Saved tab both depend on it.

### Search field

```dart
TextField(
  controller: _searchController,
  onChanged: (value) =>
      ref.read(jobFeedProvider.notifier).search(value),
)
```

The controller reads and edits the text field. The callback sends the changed value to the job controller. The text field does not directly search the repository.

### Category chips and filters

When a category is selected, the page does two things:

```dart
setState(() => _selectedCategory = category);
ref.read(jobFeedProvider.notifier).selectCategory(category);
```

`setState` updates the visual selection. The provider action updates the job data. These are separate because the selected chip is page presentation state while the filtered jobs are application state.

### Job cards and details

The list passes one job to `_JobCard`. The card displays data and sends user actions upward:

```dart
onOpen: () => _showJobDetails(job),
```

The details sheet applies through the applications provider:

```dart
ref.read(applicationsProvider.notifier).apply(job);
```

The page coordinates the action; the provider owns the application list and the rule that prevents duplicate applications.

### Exercise: add a visible job property

Choose one field already present on `Job`, such as `postedLabel` or `salary`, and change how it is displayed. Do not change the repository or provider. This teaches you to identify the smallest layer that owns a presentation-only change.

## 9. Write Tests While You Learn

Open `test/widget_test.dart`. A widget test creates the app and behaves like a user:

```dart
await tester.pumpWidget(
  const ProviderScope(child: JobSearchApp()),
);
await tester.pumpAndSettle();
```

Important test methods:

- `pumpWidget` creates the widget tree.
- `pump` lets Flutter process a small update.
- `pumpAndSettle` waits for animations and pending frames.
- `find.text` searches for visible text.
- `find.byType` searches for a widget type.
- `tester.tap` performs a tap.
- `tester.enterText` enters text into a field.
- `expect` checks what should be true.

The existing test checks a complete story: the initial feed, bookmark behavior, Saved navigation, Home navigation, and search.

### Write a test from a user story

Use this format:

```text
Given the app is open
When the user performs an action
Then the user sees a result
```

Example:

```dart
testWidgets('user can open Applications', (tester) async {
  await tester.pumpWidget(const ProviderScope(child: JobSearchApp()));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Applications').last);
  await tester.pump();

  expect(find.text('Applications'), findsOneWidget);
});
```

Run the focused test with:

```text
flutter test test/widget_test.dart
```

Tests are not only for finished features. Writing a test first forces you to define what success means.

## 10. A Repeatable Feature Workflow

When you want to add a feature, follow this order:

### Step 1: describe the behavior

Write one sentence: "A user can ... and then ..." Avoid implementation words at first.

### Step 2: identify the data

Decide whether you need a new entity field, a new entity, or no data change.

### Step 3: identify the owner

Ask where the behavior belongs:

- Data retrieval: repository.
- Business rule or changing shared state: provider.
- Layout and interaction wiring: page or widget.
- User-visible proof: widget test.

### Step 4: make the smallest code change

Change one layer, run `flutter analyze`, and read the first error before changing another layer.

### Step 5: connect the layers

Pass the value or callback across the existing boundary. Avoid making the page perform repository work directly.

### Step 6: test the behavior

Test the happy path first. Then test an empty result, duplicate action, or error if that case matters.

### Step 7: review your own code

Ask:

- Can I explain every new line?
- Does each class still have one clear job?
- What happens if the list is empty?
- What happens if the operation fails?
- Does the test fail if I remove the feature?

## 11. Learning Exercises in Order

Complete these in sequence. Do not skip to the biggest feature.

1. Change the page heading and find its source.
2. Add a fifth demo job.
3. Add a new category and make filtering work.
4. Display an additional field on a job card.
5. Add a clear-search button.
6. Add a test for the clear-search behavior.
7. Add an empty-state test for a search with no results.
8. Add a new bottom-navigation page with local state.
9. Add a provider action that changes shared state.
10. Replace the in-memory repository with a fake repository used only by a test.

After each exercise, run:

```text
flutter analyze
flutter test test/widget_test.dart
```

Make a small commit or save a short note after each exercise describing what you learned and what confused you. Explaining your own change is part of becoming a programmer.

## 12. Debugging Checklist

When something does not work, do not immediately rewrite it. Ask:

1. Is the code path running? Add a temporary `print` or set a breakpoint.
2. Is the value what I expect? Inspect it before and after the action.
3. Is the widget watching the provider, or only reading it once?
4. Did I call `setState` for page-owned state?
5. Did an async operation finish before I checked the result?
6. Does the error message identify a missing import, type, constructor argument, or null value?
7. Can I reproduce the problem with one small test?

Use these commands:

```text
flutter analyze
flutter test
flutter devices
flutter run
```

Read compiler messages from the top. The first error often causes several later errors.

## 13. What This Demo Does Not Do Yet

The current app uses in-memory data:

- Jobs are created inside the app.
- Bookmarks disappear when the app closes.
- Applications disappear when the app closes.
- `SecureTokenStore` can store tokens, but it does not implement login.
- There is no real API connected to the job repository yet.

This is useful for learning because the data flow is small and visible. When you later add an API, keep the same direction:

```text
page -> provider -> repository -> API
page <- provider <- repository <- API result
```

The page should not need to know whether the repository uses a list or the network.

## 14. The Main Lesson

When you are unsure where to write code, classify the problem first:

```text
What is the data?        -> entity
Where does it come from? -> repository
What rule changes it?    -> provider
How is it displayed?     -> widget/page
How do I prove it works? -> test
```

Then make the smallest change that answers the user's need, run the analyzer, run a focused test, and explain the result in your own words.
