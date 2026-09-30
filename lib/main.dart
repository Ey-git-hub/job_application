import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/pages/job_home_page.dart';

void main() => runApp(const ProviderScope(child: JobSearchApp()));

class JobSearchApp extends StatelessWidget {
  const JobSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xff17202a);
    return MaterialApp(
      title: 'Job Application',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff8fafc),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff146ca4))
            .copyWith(
              primary: const Color(0xff146ca4),
              onSurface: ink,
              surface: Colors.white,
            ),
        fontFamily: 'Avenir',
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          bodyMedium: TextStyle(fontSize: 12, color: Color(0xff5f6b76)),
        ),
      ),
      home: const JobHomePage(),
    );
  }
}
