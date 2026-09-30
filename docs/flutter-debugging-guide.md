# Flutter Debugging Guide for Beginners

This guide is about fixing bugs in a Flutter app you did not build.

You do not need to understand the whole app before fixing one problem. A bug is usually one small broken connection. Your job is to find that connection, make the smallest useful change, and check that the bug is gone.

## 1. The Debugging Mindset

When something breaks, do not start by changing random code.

Use this small loop:

```text
See the problem
    -> reproduce it
    -> read the error
    -> find the responsible file
    -> make one small change
    -> run the same check again
```

Think like a detective:

- What did I expect?
- What actually happened?
- What is the smallest difference between them?
- Which file is closest to that difference?
- What quick test could prove my idea wrong?

You do not need to know the entire codebase. You need to know where the broken behavior is decided.

## 2. First Read the Error, Not the Whole Project

Flutter errors often look enormous. Usually the useful part is near the top.

Look for these pieces:

```text
Error type:      What kind of problem is it?
Message:         What does Flutter say is wrong?
File and line:   Where did it notice the problem?
Stack trace:     What was happening before the problem?
```

Example:

```text
The method 'search' isn't defined for the type 'JobFeedController'.
lib/presentation/pages/job_home_page.dart:52:45
```

Translate it into normal language:

> The page tried to call `search`, but the controller does not have a method with that name. Start in the page and then inspect the controller.

Do not begin at the last line of a long stack trace. The first useful error message usually gives you the best direction.

## 3. The Three Most Useful Commands

Run these from the project root:

```text
flutter analyze
flutter test test/widget_test.dart
flutter devices
```

### `flutter analyze`

This is the spelling checker for Dart. It catches:

- Missing imports
- Wrong variable names
- Incorrect types
- Missing methods
- Unused code and lint problems

Run it first when the app will not compile.

### `flutter test test/widget_test.dart`

This runs the automated behavior check for this project. It is especially useful after changing search, bookmarks, navigation, or application behavior.

### `flutter devices`

This tells you whether Flutter can see Windows, Chrome, an emulator, or a physical phone.

If no device is available, your code may be fine but Flutter has nowhere to run it.

## 4. Find the Right File Quickly

Use the feature name as your first clue.

| Problem                   | Start here                                                         |
| ------------------------- | ------------------------------------------------------------------ |
| App does not start        | `lib/main.dart`                                                    |
| Job cards look wrong      | `lib/presentation/pages/job_home_page.dart`                        |
| Search returns wrong jobs | `lib/presentation/providers/job_providers.dart` and the repository |
| Jobs are missing          | `lib/data/repositories/in_memory_job_repository.dart`              |
| Bookmark does not change  | `job_providers.dart` and `_JobCard`                                |
| Apply button does nothing | `job_home_page.dart` and `application_providers.dart`              |
| Login token problem       | `lib/data/auth/secure_token_store.dart`                            |
| Test fails                | `test/widget_test.dart` and the file named in the failure          |

A useful rule is:

> Start where the symptom is visible. Then move one step toward the code that decides the behavior.

For example, a missing job is visible on the page, but the repository decides which jobs exist. Read the page first, then the provider, then the repository.

## 5. Search the Code Instead of Guessing

In VS Code:

- Press `Ctrl+Shift+F` to search the whole project.
- Search for the exact error word or button label.
- Search for a function name such as `toggleBookmark`.
- Hold `Ctrl` and click a method name to jump to its definition.

Useful searches in this app include:

```text
jobFeedProvider
toggleBookmark
searchJobs
applicationsProvider
_showJobDetails
```

When you find a name, inspect both:

1. Where it is defined.
2. Where it is called.

A method can be perfectly written but called with the wrong value.

## 6. Understand a Stack Trace Without Fear

A stack trace is a breadcrumb trail. It says which functions were active when the problem happened.

Example idea:

```text
JobHomePage.build
  -> ref.watch(jobFeedProvider)
    -> JobFeedController.load
      -> repository.searchJobs
```

Read it from the first application file you recognize. Ignore framework lines at first.

These are usually the most useful lines:

```text
lib/presentation/pages/job_home_page.dart:28
lib/presentation/providers/job_providers.dart:22
lib/data/repositories/in_memory_job_repository.dart:45
```

Framework lines such as `framework.dart` explain Flutter internals, but they are rarely where you should edit.

## 7. A Practical Bug-Fixing Recipe

Use this recipe for almost every bug:

### Step 1: Describe the bug in one sentence

Bad description:

> The app is broken.

Better description:

> After selecting Remote, the Data Analyst card still appears even though it is Hybrid.

### Step 2: Reproduce it twice

Do the same actions again. If the result changes, the bug may involve timing or old state.

### Step 3: Write expected and actual behavior

```text
Expected: Only Remote jobs are shown.
Actual:   Hybrid jobs are still shown.
```

### Step 4: Find the decision point

For the workplace example, inspect:

- The filter button in `job_home_page.dart`.
- `setWorkplace` in `job_providers.dart`.
- The `workplace` condition in `in_memory_job_repository.dart`.

### Step 5: Make one small edit

Do not change five files at once. If the fix fails, you want to know which change caused it.

### Step 6: Run the smallest useful check

For a repository search change, run a repository or widget test. For a type error, run `flutter analyze`.

### Step 7: Try the original bug again

A passing analyzer does not prove the button behaves correctly. Repeat the exact steps that originally failed.

## 8. Common Flutter Errors in Plain English

### “Target of URI doesn't exist”

Example:

```text
Error: Not found: 'package:flutter_riverpod/flutter_riverpod.dart'
```

Meaning: Dart cannot find the package or file.

Try:

```text
flutter pub get
```

Then check that the package is listed in `pubspec.yaml`.

### “The method X isn't defined”

Meaning: You called a function that does not exist on that object.

Check:

- Is the spelling exactly right?
- Are you calling the method on the correct object?
- Did the method get renamed?
- Is the import missing?

### “A value of type A can't be assigned to B”

Meaning: The code is handing one kind of thing to a place that expects another kind.

Example:

```dart
String title = 42;
```

A `String` is words. `42` is a number. Change the value or change the declared type intentionally.

### “Null check operator used on a null value”

Meaning: Code used `!` to promise that something exists, but it did not exist.

Risky:

```dart
final title = job!.title;
```

Safer thinking:

```dart
if (job == null) {
  return;
}
final title = job.title;
```

Do not remove `!` blindly. First find out why the value is missing.

### “Bad state: No ProviderScope found”

Meaning: A widget tried to use Riverpod without being inside `ProviderScope`.

The app starts correctly with:

```dart
runApp(const ProviderScope(child: JobSearchApp()));
```

Tests must also include `ProviderScope` when they pump widgets that use providers.

### “setState() called after dispose()”

Meaning: A screen was closed, but delayed work tried to update it afterward.

Look for:

- Timers
- Network calls
- Futures
- Stream listeners

Before using `setState` after an await, check whether the widget is still alive:

```dart
if (!mounted) return;
setState(() {});
```

## 9. Debugging Riverpod State

Riverpod problems are often state problems, not drawing problems.

Ask these questions:

1. Did the user action call the provider?
2. Did the controller receive the correct value?
3. Did the controller change `state`?
4. Is the widget using `watch` or only `read`?
5. Does the new state contain the expected data?

### `watch` versus `read`

```dart
ref.watch(jobFeedProvider)
```

Use `watch` when the screen should rebuild when the value changes.

```dart
ref.read(jobFeedProvider.notifier).search(value)
```

Use `read` when you want to call a method or read something once without subscribing to changes.

A common bug is using `read` to display data. The first value appears, but the screen never updates.

### Inspect state with a temporary print

For a short investigation:

```dart
print('Search query: $value');
```

Then remove or replace it with proper logging after the bug is understood. Never print access tokens, passwords, private user data, or full error objects in production logs.

## 10. Debugging the Job Search Flow

The search path in this app is:

```text
TextField
  -> JobFeedController.search
    -> JobFeedController.load
      -> JobRepository.searchJobs
        -> AsyncData
          -> jobFeedProvider
            -> JobHomePage rebuilds
```

If typing does nothing, inspect in this order:

1. Is the `TextField`'s `onChanged` running?
2. Does it call `search(value)`?
3. Does `search` update `_query`?
4. Does `load` pass `_query` to `searchJobs`?
5. Does the repository compare the query correctly?
6. Is the page watching `jobFeedProvider`?

This order moves from the user's action toward the data source. Stop as soon as you find the broken link.

## 11. Debugging Bookmark Problems

Bookmark flow:

```text
Bookmark icon tapped
  -> toggleBookmark(job.id)
    -> _bookmarkedIds changes
      -> new AsyncData is created
        -> card icon changes
```

If the icon does not change:

- Confirm the tap reaches `toggleBookmark`.
- Confirm the ID is the same ID used by the job.
- Confirm `state.valueOrNull` is not null.
- Confirm a new `AsyncData` is assigned.

If the icon changes but Saved jobs is empty:

- Check that Saved filters jobs using `isBookmarked`.
- Check whether the Saved view is reading the same provider state.
- Check whether a search filter hides the saved job.

## 12. Debugging Layout Problems

When widgets overlap or disappear:

- Check whether a `Column` contains a large child without `Expanded`.
- Check whether a `ListView` is inside another scrolling widget.
- Check whether a long text needs wrapping.
- Check the screen on both a narrow and wide device.
- Look for overflow messages such as `A RenderFlex overflowed`.

A yellow-and-black stripe means Flutter ran out of space. It is not a decoration; it is a warning.

Useful first fixes depend on the situation:

```dart
Expanded(child: longWidget)
```

or:

```dart
SingleChildScrollView(child: longColumn)
```

Do not add both randomly. Decide which widget should own the scrolling.

## 13. Debugging Tests

A test failure is a very small bug report. Read:

```text
Expected: what the test wanted
Actual:   what the test found
Location: the test line that failed
```

Example:

```text
Expected: exactly one matching candidate
Actual:   Found 2 widgets with text "Data Analyst"
```

This does not necessarily mean the app is wrong. It may mean the test found the text once in the search field and once in the job card.

A better test can target the exact widget type or a key instead of a broad text search.

When a test uses Riverpod, remember:

```dart
await tester.pumpWidget(
  const ProviderScope(child: JobSearchApp()),
);
```

When a screen loads asynchronous data:

```dart
await tester.pumpAndSettle();
```

Use `pump` when you want to advance one frame. Use `pumpAndSettle` when you want animations and pending work to finish.

## 14. Breakpoints and the VS Code Debugger

A breakpoint is a pause button for code.

To use one in VS Code:

1. Click next to a line number.
2. Start the app in Debug mode.
3. Perform the action that causes the bug.
4. When execution pauses, inspect variables.
5. Use Step Over to move one line at a time.

Good breakpoint places in this app include:

- The `onChanged` callback of the search field.
- The first line of `JobFeedController.load`.
- The repository filtering code.
- The `toggleBookmark` method.
- The application controller's `apply` method.

At a breakpoint, ask:

```text
What is the value of query?
What is the length of jobs?
What is the current job ID?
What is the current provider state?
```

A breakpoint is often better than adding many print statements because it lets you inspect values without changing the program.

## 15. Fixing Bugs in Code You Did Not Write

Use this safe approach:

### Read locally first

Read the function that failed and a few lines around it. Do not read the whole project immediately.

### Preserve existing behavior

Before changing code, notice what already works. A fix for filtering should not accidentally remove bookmarks.

### Find a nearby pattern

If another screen handles loading or errors correctly, follow its style.

### Make the smallest useful edit

Small edits are easier to review and undo.

### Validate immediately

Run the check that can disprove your idea. If the problem is a compile error, analyze. If it is a search behavior problem, run the search test.

### Explain the fix in plain language

A good explanation sounds like:

> The filter button changed the selected label but never told the controller to reload jobs. I connected it to `setWorkplace`, so the repository now receives the selected workplace.

## 16. A Bug Journal Template

When learning, keep a small note for every bug:

```text
Date:
Symptom:
Expected behavior:
Actual behavior:
First useful error:
Responsible file:
Root cause:
Smallest fix:
Validation command:
What I learned:
```

Example:

```text
Symptom: Search test found two Data Analyst widgets.
Expected: The test should identify the job title.
Actual: It also matched the text inside the search field.
Root cause: The test used a broad text finder.
Smallest fix: Find a plain Text widget with exact data.
Validation: flutter test test/widget_test.dart
What I learned: A failing test may need a more precise test, not an app change.
```

## 17. The Golden Rules

1. Reproduce the bug before changing code.
2. Read the first useful error message.
3. Start at the file closest to the symptom.
4. Follow data from the button to the provider to the repository.
5. Change one small thing at a time.
6. Run the smallest check that can disprove your idea.
7. Never hide an error just to make the screen look quiet.
8. Never log passwords, tokens, or private user data.
9. Keep a passing test for every important bug you fix.
10. You do not need to understand the whole app to fix one broken path.

The goal is not to memorize every Flutter feature. The goal is to become good at asking:

> “What exactly happened, where is that decision made, and what small check will prove my fix works?”
