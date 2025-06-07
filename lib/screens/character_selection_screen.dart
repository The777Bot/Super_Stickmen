import 'package:flutter/material.dart';

class CharacterSelectionScreen extends StatelessWidget {
  final Function(String) onCharacterSelected;
  final VoidCallback onBackPressed;

  const CharacterSelectionScreen({
    super.key,
    required this.onCharacterSelected,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final characters = [
      {'name': 'Ninja', 'color': Colors.black},
      {'name': 'Warrior', 'color': Colors.red},
      {'name': 'Mage', 'color': Colors.blue},
      {'name': 'Archer', 'color': Colors.green},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Character'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackPressed,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.purple],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Choose Your Fighter',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: characters.map((character) {
                  return GestureDetector(
                    onTap: () => onCharacterSelected(character['name'] as String),
                    child: Container(
                      width: 150,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: character['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            character['name'] as String,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 