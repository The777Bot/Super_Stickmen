import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'stickman.dart';

class StickmanFightGame extends FlameGame with KeyboardEvents, HasCollisionDetection {
  late Stickman player;
  late Stickman computer;
  final String playerCharacter;
  
  // AI properties
  double aiDecisionTimer = 0.0;
  double aiDecisionInterval = 0.5; // Make a decision every half second
  bool isPlayerAttacking = false;
  bool isPlayerBlocking = false;
  bool isPlayerSpecialAttacking = false;
  
  // Game state
  bool isGameOver = false;
  String? winner;

  // UI constants
  static const double healthBarHeight = 30.0;
  static const double healthBarWidth = 200.0;
  static const double healthBarPadding = 20.0;

  // World and UI components
  late GameWorld gameWorld;
  late GameHud gameHud;

  StickmanFightGame({required this.playerCharacter});

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Create world for game elements
    gameWorld = GameWorld();
    add(gameWorld);
    
    // Create HUD for UI elements
    gameHud = GameHud();
    add(gameHud);
    
    // Create player stickman based on selected character
    player = Stickman(
      position: Vector2(100, size.y - 150),
      characterType: playerCharacter,
    );

    // Create computer opponent with random character
    final computerCharacters = ['Ninja', 'Warrior', 'Mage', 'Archer'];
    final randomCharacter = computerCharacters.firstWhere(
      (char) => char != playerCharacter,
    );
    
    computer = Stickman(
      position: Vector2(size.x - 150, size.y - 150),
      facingLeft: true,
      characterType: randomCharacter,
    );

    gameWorld.add(player);
    gameWorld.add(computer);
  }

  @override
  Color backgroundColor() => const Color(0xFF87CEEB); // Sky blue background

  @override
  void update(double dt) {
    super.update(dt);
    
    if (isGameOver) return;

    // Check for game over
    if (player.isDead()) {
      isGameOver = true;
      winner = 'Computer';
    } else if (computer.isDead()) {
      isGameOver = true;
      winner = 'Player';
    }
    
    // Keep characters in bounds
    _keepInBounds(player);
    _keepInBounds(computer);
    
    // Check for hits
    _checkHits();
    
    // Update AI decision timer
    aiDecisionTimer += dt;
    if (aiDecisionTimer >= aiDecisionInterval) {
      aiDecisionTimer = 0;
      updateAI();
    }
  }

  void _keepInBounds(Stickman stickman) {
    // Keep within screen bounds
    if (stickman.position.x < 0) {
      stickman.position.x = 0;
    } else if (stickman.position.x > size.x - stickman.size.x) {
      stickman.position.x = size.x - stickman.size.x;
    }
  }

  void _checkHits() {
    // Check if player's attack hits computer
    if (player.isAttacking || player.isSpecialAttacking) {
      final distance = (player.position - computer.position).length;
      if (distance < 100) {
        final damage = player.isSpecialAttacking ? 30.0 : 10.0;
        computer.takeDamage(damage);
      }
    }

    // Check if computer's attack hits player
    if (computer.isAttacking || computer.isSpecialAttacking) {
      final distance = (player.position - computer.position).length;
      if (distance < 100) {
        final damage = computer.isSpecialAttacking ? 30.0 : 10.0;
        player.takeDamage(damage);
      }
    }
  }

  void updateAI() {
    if (isGameOver) return;

    // Calculate distance to player
    final distance = (player.position - computer.position).length;
    
    // Basic AI behavior
    if (distance < 100) {
      // Close range behavior
      if (isPlayerAttacking) {
        // If player is attacking, try to block
        computer.block();
      } else if (isPlayerBlocking) {
        // If player is blocking, try to get behind
        computer.move(player.facingLeft ? 1 : -1);
      } else {
        // If player is vulnerable, attack
        if (computer.specialAttackCooldown <= 0) {
          computer.specialAttack();
        } else {
          computer.attack();
        }
      }
    } else if (distance < 200) {
      // Medium range behavior
      if (isPlayerSpecialAttacking) {
        // If player is using special attack, try to block
        computer.block();
      } else if (isPlayerBlocking) {
        // If player is blocking, move away
        computer.move(-1);
      } else {
        // If player is vulnerable, move closer
        computer.move(1);
      }
    } else {
      // Long range behavior
      computer.move(1); // Move towards player
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (isGameOver) return KeyEventResult.handled;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        player.move(-1);
      } else if (event.logicalKey == LogicalKeyboardKey.keyD ||
                 event.logicalKey == LogicalKeyboardKey.arrowRight) {
        player.move(1);
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        player.jump();
      } else if (event.logicalKey == LogicalKeyboardKey.keyJ) {
        player.attack();
        isPlayerAttacking = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyK) {
        player.block();
        isPlayerBlocking = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
        player.specialAttack();
        isPlayerSpecialAttacking = true;
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.keyD ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        player.move(0);
      } else if (event.logicalKey == LogicalKeyboardKey.keyJ) {
        isPlayerAttacking = false;
      } else if (event.logicalKey == LogicalKeyboardKey.keyK) {
        player.stopBlocking();
        isPlayerBlocking = false;
      } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
        isPlayerSpecialAttacking = false;
      }
    }

    return super.onKeyEvent(event, keysPressed);
  }
}

class GameWorld extends PositionComponent {
  @override
  void render(Canvas canvas) {
    // Draw background
    _drawBackground(canvas);
  }

  void _drawBackground(Canvas canvas) {
    final game = parent as StickmanFightGame;
    
    // Draw sky gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF87CEEB), Color(0xFFE0F7FA)],
      ).createShader(Rect.fromLTWH(0, 0, game.size.x, game.size.y));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      skyPaint,
    );

    // Draw ground
    final groundPaint = Paint()
      ..color = const Color(0xFF8B4513); // Brown color for ground
    canvas.drawRect(
      Rect.fromLTWH(0, game.size.y - 50, game.size.x, 50),
      groundPaint,
    );

    // Draw grass on top of ground
    final grassPaint = Paint()
      ..color = const Color(0xFF228B22); // Forest green color
    canvas.drawRect(
      Rect.fromLTWH(0, game.size.y - 50, game.size.x, 5),
      grassPaint,
    );

    // Draw some decorative elements
    _drawClouds(canvas);
  }

  void _drawClouds(Canvas canvas) {
    final game = parent as StickmanFightGame;
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.8);

    // Draw a few clouds
    for (var i = 0; i < 3; i++) {
      final x = (game.size.x / 3) * i;
      final y = 50.0 + (i * 30.0);
      
      // Draw cloud circles
      canvas.drawCircle(Offset(x, y), 20, cloudPaint);
      canvas.drawCircle(Offset(x + 15, y - 10), 15, cloudPaint);
      canvas.drawCircle(Offset(x + 30, y), 20, cloudPaint);
      canvas.drawCircle(Offset(x + 15, y + 10), 15, cloudPaint);
    }
  }
}

class GameHud extends PositionComponent {
  @override
  void render(Canvas canvas) {
    final game = parent as StickmanFightGame;
    
    // Draw health bars
    _drawHealthBars(canvas, game);

    if (game.isGameOver) {
      _drawGameOver(canvas, game);
    }
  }

  void _drawHealthBars(Canvas canvas, StickmanFightGame game) {
    // Draw player health bar
    _drawHealthBar(
      canvas,
      StickmanFightGame.healthBarPadding,
      StickmanFightGame.healthBarPadding,
      game.player.currentHealth,
      game.player.maxHealth,
      game.player.characterType,
      false,
    );

    // Draw computer health bar
    _drawHealthBar(
      canvas,
      game.size.x - StickmanFightGame.healthBarWidth - StickmanFightGame.healthBarPadding,
      StickmanFightGame.healthBarPadding,
      game.computer.currentHealth,
      game.computer.maxHealth,
      game.computer.characterType,
      true,
    );
  }

  void _drawHealthBar(
    Canvas canvas,
    double x,
    double y,
    double currentHealth,
    double maxHealth,
    String characterName,
    bool isComputer,
  ) {
    // Draw background
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(x, y, StickmanFightGame.healthBarWidth, StickmanFightGame.healthBarHeight),
      bgPaint,
    );

    // Draw health
    final healthPercentage = currentHealth / maxHealth;
    final healthPaint = Paint()
      ..color = _getHealthColor(healthPercentage)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(x, y, StickmanFightGame.healthBarWidth * healthPercentage, StickmanFightGame.healthBarHeight),
      healthPaint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawRect(
      Rect.fromLTWH(x, y, StickmanFightGame.healthBarWidth, StickmanFightGame.healthBarHeight),
      borderPaint,
    );

    // Draw character name
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${isComputer ? "CPU " : ""}$characterName',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(x, y - 20),
    );
  }

  Color _getHealthColor(double percentage) {
    if (percentage > 0.6) return Colors.green;
    if (percentage > 0.3) return Colors.orange;
    return Colors.red;
  }

  void _drawGameOver(Canvas canvas, StickmanFightGame game) {
    // Draw semi-transparent overlay
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      overlayPaint,
    );

    // Draw game over text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Game Over!\n${game.winner} Wins!',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (game.size.x - textPainter.width) / 2,
        (game.size.y - textPainter.height) / 2,
      ),
    );
  }
}

