import 'package:flutter/material.dart';

class CharacterSelectionScreen extends StatefulWidget {
  final Function(String) onCharacterSelected;
  final VoidCallback onBackPressed;
  final String? selectedCharacter;

  const CharacterSelectionScreen({
    super.key,
    required this.onCharacterSelected,
    required this.onBackPressed,
    this.selectedCharacter,
  });

  @override
  State<CharacterSelectionScreen> createState() => _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> with SingleTickerProviderStateMixin {
  String? selectedCharacter;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  final Map<String, bool> _hoverStates = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize hover states
    for (final character in ['Ninja', 'Warrior', 'Mage', 'Archer']) {
      _hoverStates[character] = false;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.purple],
          ),
        ),
        child: Column(
          children: [
            // Back button and title
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: widget.onBackPressed,
                  ),
                  const Expanded(
                    child: Text(
                      'Choose Your Character',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
            // Character grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.8,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    _buildCharacterCard('Ninja'),
                    _buildCharacterCard('Warrior'),
                    _buildCharacterCard('Mage'),
                    _buildCharacterCard('Archer'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterCard(String character) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: () => widget.onCharacterSelected(character),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 160,
              height: 200,
              decoration: BoxDecoration(
                color: _getCharacterColor(character).withOpacity(isHovered ? 0.3 : 0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _getCharacterColor(character).withOpacity(isHovered ? 1.0 : 0.5),
                  width: isHovered ? 3 : 2,
                ),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                          color: _getCharacterColor(character).withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  // Character icon
                  Center(
                    child: Icon(
                      _getCharacterIcon(character),
                      size: 60,
                      color: _getCharacterColor(character).withOpacity(isHovered ? 1.0 : 0.8),
                    ),
                  ),
                  // Character name
                  Positioned(
                    bottom: 15,
                    left: 0,
                    right: 0,
                    child: Text(
                      character,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 5,
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Selection indicator
                  if (character == widget.selectedCharacter)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getCharacterIcon(String character) {
    switch (character) {
      case 'Ninja':
        return Icons.person;
      case 'Warrior':
        return Icons.shield;
      case 'Mage':
        return Icons.auto_awesome;
      case 'Archer':
        return Icons.arrow_forward;
      default:
        return Icons.person;
    }
  }

  Color _getCharacterColor(String character) {
    switch (character) {
      case 'Ninja':
        return Colors.black;
      case 'Warrior':
        return Colors.red;
      case 'Mage':
        return Colors.blue;
      case 'Archer':
        return Colors.green;
      default:
        return Colors.white;
    }
  }
} 