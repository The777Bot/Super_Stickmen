import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';
import 'screens/character_selection_screen.dart';
import 'screens/game_screen.dart';
import 'game_state.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Super Stickmen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const GameStateManager(),
    ),
  );
}
