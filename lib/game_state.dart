import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';
import 'screens/character_selection_screen.dart';
import 'screens/game_screen.dart';
import 'stickman_fight_game.dart';

enum GameState {
  menu,
  characterSelection,
  gameplay,
}

class GameStateManager extends StatefulWidget {
  const GameStateManager({super.key});

  @override
  State<GameStateManager> createState() => _GameStateManagerState();
}

class _GameStateManagerState extends State<GameStateManager> {
  GameState _currentState = GameState.menu;
  String? _selectedCharacter;

  void _handlePlayPressed() {
    setState(() {
      _currentState = GameState.characterSelection;
    });
  }

  void _handleCharacterSelected(String character) {
    setState(() {
      _selectedCharacter = character;
      _currentState = GameState.gameplay;
    });
  }

  void _handleBackPressed() {
    setState(() {
      if (_currentState == GameState.characterSelection) {
        _currentState = GameState.menu;
      } else if (_currentState == GameState.gameplay) {
        _currentState = GameState.characterSelection;
      }
    });
  }

  void _handleGameOver(bool playAgain) {
    setState(() {
      if (playAgain) {
        // Reset the game with the same character
        _currentState = GameState.gameplay;
      } else {
        // Go back to character selection
        _currentState = GameState.characterSelection;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildCurrentScreen();
  }

  Widget _buildCurrentScreen() {
    switch (_currentState) {
      case GameState.menu:
        return MenuScreen(
          onPlayPressed: _handlePlayPressed,
        );
      case GameState.characterSelection:
        return CharacterSelectionScreen(
          onCharacterSelected: _handleCharacterSelected,
          onBackPressed: _handleBackPressed,
        );
      case GameState.gameplay:
        if (_selectedCharacter == null) {
          return const Center(child: Text('Error: No character selected'));
        }
        return GameScreen(
          characterType: _selectedCharacter!,
          onGameOver: _handleGameOver,
          onBackPressed: _handleBackPressed,
        );
    }
  }
} 