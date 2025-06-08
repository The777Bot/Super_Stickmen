import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../theme_provider.dart';

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
  final Map<String, Map<String, dynamic>> _characterDetails = {
    'Ninja': {
      'description': 'A swift and stealthy warrior who excels in close combat.',
      'abilities': ['Shadow Step', 'Smoke Bomb', 'Dual Strike'],
      'stats': {'Speed': 9, 'Power': 7, 'Defense': 5},
      'color': Colors.black,
      'icon': Icons.person,
    },
    'Warrior': {
      'description': 'A mighty fighter with exceptional strength and durability.',
      'abilities': ['Shield Bash', 'Battle Cry', 'Whirlwind'],
      'stats': {'Speed': 5, 'Power': 9, 'Defense': 8},
      'color': Colors.red,
      'icon': Icons.shield,
    },
    'Mage': {
      'description': 'A powerful spellcaster who harnesses the elements.',
      'abilities': ['Fireball', 'Ice Shield', 'Lightning Bolt'],
      'stats': {'Speed': 6, 'Power': 9, 'Defense': 4},
      'color': Colors.blue,
      'icon': Icons.auto_awesome,
    },
    'Archer': {
      'description': 'A precise marksman with deadly accuracy.',
      'abilities': ['Precise Shot', 'Rain of Arrows', 'Quick Draw'],
      'stats': {'Speed': 8, 'Power': 7, 'Defense': 6},
      'color': Colors.green,
      'icon': Icons.arrow_forward,
    },
  };

  @override
  void initState() {
    super.initState();
    selectedCharacter = widget.selectedCharacter;
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
    for (final character in _characterDetails.keys) {
      _hoverStates[character] = false;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleCharacterSelection(String character) {
    setState(() {
      selectedCharacter = character;
    });
  }

  void _confirmSelection() {
    if (selectedCharacter != null) {
      widget.onCharacterSelected(selectedCharacter!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    Colors.blue.shade900,
                    Colors.purple.shade900,
                  ]
                : [
                    Colors.blue.shade200,
                    Colors.purple.shade200,
                  ],
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
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: widget.onBackPressed,
                  ),
                  Expanded(
                    child: Text(
                      'Choose Your Character',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                        shadows: [
                          Shadow(
                            color: (isDarkMode ? Colors.black : Colors.white).withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Row(
                children: [
                  // Character grid
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: 0.8,
                        children: _characterDetails.keys.map((character) => _buildCharacterCard(character, isDarkMode)).toList(),
                      ),
                    ),
                  ),
                  // Character preview panel
                  if (selectedCharacter != null)
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedCharacter!,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _characterDetails[selectedCharacter]!['description'],
                              style: TextStyle(
                                fontSize: 16,
                                color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              'Abilities:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...(_characterDetails[selectedCharacter]!['abilities'] as List<String>).map(
                              (ability) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: _characterDetails[selectedCharacter]!['color'],
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      ability,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              'Stats:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...(_characterDetails[selectedCharacter]!['stats'] as Map<String, int>).entries.map(
                              (stat) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Text(
                                      '${stat.key}:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: stat.value / 10,
                                        backgroundColor: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.2),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _characterDetails[selectedCharacter]!['color'],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      stat.value.toString(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            Center(
                              child: ElevatedButton(
                                onPressed: _confirmSelection,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                  backgroundColor: _characterDetails[selectedCharacter]!['color'],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Select Character',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterCard(String character, bool isDarkMode) {
    final details = _characterDetails[character]!;
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = _hoverStates[character] ?? false;
        bool isSelected = character == selectedCharacter;
        
        return MouseRegion(
          onEnter: (_) => setState(() => _hoverStates[character] = true),
          onExit: (_) => setState(() => _hoverStates[character] = false),
          child: GestureDetector(
            onTap: () => _handleCharacterSelection(character),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(isHovered ? 0.05 : 0)
                ..rotateY(isHovered ? 0.05 : 0)
                ..scale(isHovered ? 1.05 : 1.0),
              decoration: BoxDecoration(
                color: details['color'].withOpacity(isHovered ? 0.3 : 0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: details['color'].withOpacity(isSelected ? 1.0 : isHovered ? 0.8 : 0.5),
                  width: isSelected ? 3 : isHovered ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: details['color'].withOpacity(isSelected ? 0.5 : isHovered ? 0.3 : 0.1),
                    blurRadius: isSelected ? 20 : isHovered ? 15 : 10,
                    spreadRadius: isSelected ? 2 : isHovered ? 1 : 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Character icon
                  Center(
                    child: Icon(
                      details['icon'],
                      size: 60,
                      color: details['color'].withOpacity(isSelected ? 1.0 : isHovered ? 0.9 : 0.8),
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
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isDarkMode ? Colors.white : Colors.black,
                        shadows: [
                          Shadow(
                            color: (isDarkMode ? Colors.black : Colors.white).withOpacity(0.5),
                            blurRadius: 5,
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Selection indicator
                  if (isSelected)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
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
} 