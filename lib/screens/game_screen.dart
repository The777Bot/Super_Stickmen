import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../stickman_fight_game.dart';

class GameScreen extends StatelessWidget {
  final String characterType;
  final Function(bool) onGameOver;
  final VoidCallback onBackPressed;

  const GameScreen({
    super.key,
    required this.characterType,
    required this.onGameOver,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: StickmanFightGame(
          playerCharacter: characterType,
        ),
        overlayBuilderMap: {
          'pause_button': (context, game) {
            return Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBackPressed,
              ),
            );
          },
        },
        initialActiveOverlays: const ['pause_button'],
      ),
    );
  }
} 