import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../stickman_fight_game.dart';

class GameScreen extends StatelessWidget {
  final String selectedCharacter;
  final VoidCallback onBackPressed;

  const GameScreen({
    super.key,
    required this.selectedCharacter,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fighting as $selectedCharacter'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackPressed,
        ),
      ),
      body: GameWidget(
        game: StickmanFightGame(
          playerCharacter: selectedCharacter,
        ),
      ),
    );
  }
} 