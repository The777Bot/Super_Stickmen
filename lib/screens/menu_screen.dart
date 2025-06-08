import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../theme_provider.dart';

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
  bool _isThemeHovered = false;
  late AnimationController _animationController;
  late Animation<double> _leftWarriorAnimation;
  late Animation<double> _rightWarriorAnimation;
  final List<Particle> _particles = List.generate(50, (index) => Particle());

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
        child: Stack(
          children: [
            // Animated background particles
            ..._particles.map((particle) => AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                particle.update();
                return Positioned(
                  left: particle.x,
                  top: particle.y,
                  child: Container(
                    width: particle.size,
                    height: particle.size,
                    decoration: BoxDecoration(
                      color: (isDarkMode ? Colors.white : Colors.black).withOpacity(particle.opacity),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            )),
            // Theme toggle button
            Positioned(
              top: 20,
              right: 20,
              child: MouseRegion(
                onEnter: (_) => setState(() => _isThemeHovered = true),
                onExit: (_) => setState(() => _isThemeHovered = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.identity()
                    ..scale(_isThemeHovered ? 1.1 : 1.0),
                  child: IconButton(
                    icon: Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => themeProvider.toggleTheme(),
                    tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  ),
                ),
              ),
            ),
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
                      isDarkMode ? Colors.black : Colors.grey.shade800,
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
                      isDarkMode ? Colors.blue : Colors.blue.shade300,
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
                  // Game Logo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      'Super Stickmen',
                      style: TextStyle(
                        fontSize: 48,
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
                  const SizedBox(height: 50),
                  _buildMenuButton(
                    onPressed: widget.onPlayPressed,
                    text: 'Play',
                    icon: Icons.play_arrow,
                    isHovered: _isPlayHovered,
                    onHoverChanged: (value) => setState(() => _isPlayHovered = value),
                    isDarkMode: isDarkMode,
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
                    isDarkMode: isDarkMode,
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
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 50),
                  // Version and Credits
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '© 2024 Super Stickmen',
                    style: TextStyle(
                      color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.5),
                      fontSize: 14,
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

  Widget _buildWarriorImage(String imagePath, Color color, IconData fallbackIcon) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
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
    required bool isDarkMode,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..scale(isHovered ? 1.05 : 1.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            textStyle: const TextStyle(fontSize: 24),
            backgroundColor: (isDarkMode ? Colors.white : Colors.black).withOpacity(isHovered ? 0.9 : 0.8),
            foregroundColor: isDarkMode ? Colors.black : Colors.white,
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
                color: isDarkMode ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                text,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
                  color: isDarkMode ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Particle {
  double x = math.Random().nextDouble() * 1000;
  double y = math.Random().nextDouble() * 1000;
  double size = math.Random().nextDouble() * 4 + 1;
  double speed = math.Random().nextDouble() * 2 + 0.5;
  double opacity = math.Random().nextDouble() * 0.5 + 0.1;
  double direction = math.Random().nextDouble() * 360;

  void update() {
    x += math.cos(direction) * speed;
    y += math.sin(direction) * speed;
    
    if (x < 0) x = 1000;
    if (x > 1000) x = 0;
    if (y < 0) y = 1000;
    if (y > 1000) y = 0;
  }
} 