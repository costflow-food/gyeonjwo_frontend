import 'package:flutter/material.dart';

import 'app/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '견줘',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFED2635)),
        scaffoldBackgroundColor: const Color(0xFFFCFCFD),
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF191A1B),
          displayColor: const Color(0xFF191A1B),
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
