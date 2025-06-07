import 'package:flutter/material.dart';

class MenuScreen extends StatefulWidget {
  final VoidCallback onPlayPressed;

  const MenuScreen({
    super.key,
    required this.onPlayPressed,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  bool _isPlayHovered = false;
  bool _isSettingsHovered = false;
  bool _isExitHovered = false;
  late AnimationController _animationController;
  late Animation<double> _leftWarriorAnimation;
  late Animation<double> _rightWarriorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _leftWarriorAnimation = Tween<double>(begin: -20, end: 20).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _rightWarriorAnimation = Tween<double>(begin: 20, end: -20).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
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
        child: Stack(
          children: [
            // Left Warrior
            Positioned(
              left: -50,
              top: 100,
              child: AnimatedBuilder(
                animation: _leftWarriorAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _leftWarriorAnimation.value),
                    child: _buildWarriorImage(
                      'assets/images/ninja_warrior.png',
                      Colors.black,
                      Icons.person,
                    ),
                  );
                },
              ),
            ),
            // Right Warrior
            Positioned(
              right: -50,
              top: 100,
              child: AnimatedBuilder(
                animation: _rightWarriorAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _rightWarriorAnimation.value),
                    child: _buildWarriorImage(
                      'assets/images/mage_warrior.png',
                      Colors.blue,
                      Icons.auto_awesome,
                    ),
                  );
                },
              ),
            ),
            // Main Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Super Stickmen',
                    style: TextStyle(
                      fontSize: 48,
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
                  const SizedBox(height: 50),
                  _buildMenuButton(
                    onPressed: widget.onPlayPressed,
                    text: 'Play',
                    icon: Icons.play_arrow,
                    isHovered: _isPlayHovered,
                    onHoverChanged: (value) => setState(() => _isPlayHovered = value),
                  ),
                  const SizedBox(height: 20),
                  _buildMenuButton(
                    onPressed: () {
                      // TODO: Implement settings
                    },
                    text: 'Settings',
                    icon: Icons.settings,
                    isHovered: _isSettingsHovered,
                    onHoverChanged: (value) => setState(() => _isSettingsHovered = value),
                  ),
                  const SizedBox(height: 20),
                  _buildMenuButton(
                    onPressed: () {
                      // Exit the game
                      Navigator.of(context).pop();
                    },
                    text: 'Exit',
                    icon: Icons.exit_to_app,
                    isHovered: _isExitHovered,
                    onHoverChanged: (value) => setState(() => _isExitHovered = value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarriorImage(String imagePath, Color color, IconData fallbackIcon) {
    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Try to load the image, fallback to icon if not found
          Center(
            child: Image.asset(
              imagePath,
              width: 250,
              height: 350,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  fallbackIcon,
                  size: 200,
                  color: color.withOpacity(0.8),
                );
              },
            ),
          ),
          // Add a glow effect
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: RadialGradient(
                  colors: [
                    color.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
    required bool isHovered,
    required ValueChanged<bool> onHoverChanged,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            textStyle: const TextStyle(fontSize: 24),
            backgroundColor: Colors.white.withOpacity(isHovered ? 0.9 : 0.8),
            foregroundColor: isHovered ? Colors.blue.shade700 : Colors.blue,
            elevation: isHovered ? 8 : 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: isHovered ? Colors.blue.shade700 : Colors.blue,
              ),
              const SizedBox(width: 10),
              Text(
                text,
                style: TextStyle(
                  color: isHovered ? Colors.blue.shade700 : Colors.blue,
                  shadows: isHovered
                      ? [
                          Shadow(
                            color: Colors.blue.withOpacity(0.5),
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