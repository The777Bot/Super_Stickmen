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
          onGameOver: onGameOver,
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
          'pause_menu': (context, game) {
            final stickmanGame = game as StickmanFightGame;
            if (!stickmanGame.isPaused) return const SizedBox.shrink();

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'PAUSED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  _buildPauseMenuButton(
                    context,
                    'Resume (ESC)',
                    () {
                      stickmanGame.isPaused = false;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPauseMenuButton(
                    context,
                    'Restart',
                    () {
                      // Reset the game
                      stickmanGame.reset();
                      stickmanGame.isPaused = false;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildPauseMenuButton(
                    context,
                    'Main Menu',
                    onBackPressed,
                  ),
                ],
              ),
            );
          },
        },
        initialActiveOverlays: const ['pause_button'],
      ),
    );
  }

  Widget _buildPauseMenuButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 5,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 