import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_state.dart';
import 'theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SuperStickmenApp(),
    ),
  );
}

class SuperStickmenApp extends StatelessWidget {
  const SuperStickmenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Super Stickmen',
          theme: themeProvider.theme,
          home: const GameStateManager(),
        );
      },
    );
  }
}
