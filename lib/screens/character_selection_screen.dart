import 'package:flutter/material.dart';

class CharacterSelectionScreen extends StatefulWidget {
  final Function(String) onCharacterSelected;
  final VoidCallback onBackPressed;

  const CharacterSelectionScreen({
    super.key,
    required this.onCharacterSelected,
    required this.onBackPressed,
  });

  @override
  State<CharacterSelectionScreen> createState() => _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final characters = [
      {'name': 'Ninja', 'color': Colors.black, 'icon': Icons.person},
      {'name': 'Warrior', 'color': Colors.red, 'icon': Icons.shield},
      {'name': 'Mage', 'color': Colors.blue, 'icon': Icons.auto_awesome},
      {'name': 'Archer', 'color': Colors.green, 'icon': Icons.arrow_forward},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Character'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackPressed,
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
                  return _buildCharacterCard(
                    name: character['name'] as String,
                    color: character['color'] as Color,
                    icon: character['icon'] as IconData,
                    onSelected: () => widget.onCharacterSelected(character['name'] as String),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterCard({
    required String name,
    required Color color,
    required IconData icon,
    required VoidCallback onSelected,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 150,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_isHovered ? 0.3 : 0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _isHovered ? Colors.yellow : Colors.white,
              width: _isHovered ? 3 : 2,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: _isHovered
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: _isHovered
                      ? [
                          Shadow(
                            color: color,
                            blurRadius: 10,
                          )
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 