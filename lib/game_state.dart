import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';
import 'screens/character_selection_screen.dart';
import 'screens/game_screen.dart';

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
  GameState currentState = GameState.menu;
  String? selectedCharacter;

  void changeScreen(GameState state) {
    setState(() {
      currentState = state;
    });
  }

  void selectCharacter(String character) {
    setState(() {
      selectedCharacter = character;
      currentState = GameState.gameplay;
    });
  }

  Widget _buildCurrentScreen() {
    switch (currentState) {
      case GameState.menu:
        return MenuScreen(
          onPlayPressed: () => changeScreen(GameState.characterSelection),
        );
      case GameState.characterSelection:
        return CharacterSelectionScreen(
          onCharacterSelected: selectCharacter,
          onBackPressed: () => changeScreen(GameState.menu),
        );
      case GameState.gameplay:
        return GameScreen(
          selectedCharacter: selectedCharacter!,
          onBackPressed: () => changeScreen(GameState.characterSelection),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildCurrentScreen();
  }
} 