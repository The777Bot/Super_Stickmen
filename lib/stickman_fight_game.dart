import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'stickman.dart';

class StickmanFightGame extends FlameGame with KeyboardEvents, HasCollisionDetection {
  late Stickman player;
  late Stickman computer;
  final String playerCharacter;
  
  // AI properties
  double aiDecisionTimer = 0.0;
  double aiDecisionInterval = 0.3; // Make decisions more frequently
  bool isPlayerAttacking = false;
  bool isPlayerBlocking = false;
  bool isPlayerSpecialAttacking = false;
  
  // Game state
  bool isGameOver = false;
  String? winner;
  int playerScore = 0;
  int computerScore = 0;
  double roundTimer = 60.0; // 60 seconds per round
  bool isRoundOver = false;

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
      position: Vector2(100, size.y - 90),
      characterType: playerCharacter,
    );

    // Create computer opponent with random character
    final computerCharacters = ['Ninja', 'Warrior', 'Mage', 'Archer'];
    final randomCharacter = computerCharacters.firstWhere(
      (char) => char != playerCharacter,
    );
    
    computer = Stickman(
      position: Vector2(size.x - 150, size.y - 90),
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

    // Update round timer
    if (!isRoundOver) {
      roundTimer -= dt;
      if (roundTimer <= 0) {
        isRoundOver = true;
        _handleRoundEnd();
      }
    }

    // Check for game over
    if (player.isDead()) {
      isGameOver = true;
      winner = 'Computer';
      computerScore++;
    } else if (computer.isDead()) {
      isGameOver = true;
      winner = 'Player';
      playerScore++;
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

  void _handleRoundEnd() {
    if (player.currentHealth > computer.currentHealth) {
      playerScore++;
    } else if (computer.currentHealth > player.currentHealth) {
      computerScore++;
    }
    // Reset for next round
    player.resetHealth();
    computer.resetHealth();
    roundTimer = 60.0;
    isRoundOver = false;
  }

  void _keepInBounds(Stickman stickman) {
    // Keep within screen bounds with some padding
    final padding = 20.0;
    if (stickman.position.x < padding) {
      stickman.position.x = padding;
    } else if (stickman.position.x > size.x - stickman.size.x - padding) {
      stickman.position.x = size.x - stickman.size.x - padding;
    }
  }

  void _checkHits() {
    // Check if player's attack hits computer
    if (player.isAttacking || player.isSpecialAttacking) {
      final distance = (player.position - computer.position).length;
      if (distance < 100) {
        final damage = player.isSpecialAttacking ? 20.0 : 5.0; // Reduced damage
        if (!computer.isBlocking) {
          computer.takeDamage(damage);
          _createHitEffect(computer.position);
        }
      }
    }

    // Check if computer's attack hits player
    if (computer.isAttacking || computer.isSpecialAttacking) {
      final distance = (player.position - computer.position).length;
      if (distance < 100) {
        final damage = computer.isSpecialAttacking ? 20.0 : 5.0; // Reduced damage
        if (!player.isBlocking) {
          player.takeDamage(damage);
          _createHitEffect(player.position);
        }
      }
    }
  }

  void _createHitEffect(Vector2 position) {
    final effect = HitEffect(position: position);
    gameWorld.add(effect);
  }

  void updateAI() {
    if (isGameOver || isRoundOver) return;

    // Calculate distance to player
    final distance = (player.position - computer.position).length;
    final random = math.Random();
    
    // Add some randomness to AI decisions
    if (random.nextDouble() < 0.1) {
      // 10% chance to do nothing
      return;
    }
    
    // Basic AI behavior with improved positioning
    if (distance < 80) {
      // Close range behavior
      if (isPlayerAttacking) {
        // If player is attacking, try to block or dodge
        if (random.nextDouble() < 0.7) {
          computer.block();
        } else {
          computer.move(player.facingLeft ? 1 : -1);
        }
      } else if (isPlayerBlocking) {
        // If player is blocking, try to get behind or move away
        if (random.nextDouble() < 0.5) {
          computer.move(player.facingLeft ? 1 : -1);
        } else {
          computer.move(-1);
        }
      } else {
        // If player is vulnerable, attack
        if (computer.specialAttackCooldown <= 0 && random.nextDouble() < 0.3) {
          computer.specialAttack();
        } else {
          computer.attack();
        }
      }
    } else if (distance < 200) {
      // Medium range behavior
      if (isPlayerSpecialAttacking) {
        // If player is using special attack, try to block or dodge
        if (random.nextDouble() < 0.6) {
          computer.block();
        } else {
          computer.move(-1);
        }
      } else if (isPlayerBlocking) {
        // If player is blocking, move away
        computer.move(-1);
      } else {
        // If player is vulnerable, move closer or attack
        if (random.nextDouble() < 0.7) {
          computer.move(1);
        } else if (computer.specialAttackCooldown <= 0) {
          computer.specialAttack();
        }
      }
    } else {
      // Long range behavior
      if (random.nextDouble() < 0.8) {
        computer.move(1); // Move towards player
      } else if (computer.specialAttackCooldown <= 0) {
        computer.specialAttack(); // Try special attack from range
      }
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        // Exit the game
        SystemNavigator.pop();
        return KeyEventResult.handled;
      }
    }

    if (isGameOver || isRoundOver) return KeyEventResult.handled;

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

class HitEffect extends PositionComponent {
  static const double duration = 0.3;
  double _timer = 0.0;
  final Paint _paint = Paint()
    ..color = Colors.yellow
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  HitEffect({required Vector2 position}) {
    this.position = position;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = _timer / duration;
    final radius = 20.0 * (1 - progress);
    final opacity = 1.0 - progress;
    
    _paint.color = Colors.yellow.withOpacity(opacity);
    canvas.drawCircle(
      Offset(0, 0),
      radius,
      _paint,
    );
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

