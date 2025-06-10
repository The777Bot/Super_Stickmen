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
  final Function(bool)? onGameOver;
  
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
  
  // Add background image components
  late SpriteComponent mountains1;
  late SpriteComponent mountains2;
  late SpriteComponent clouds1;
  late SpriteComponent clouds2;

  // Add pause state
  bool isPaused = false;

  StickmanFightGame({
    required this.playerCharacter,
    this.onGameOver,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Load background sprites
    mountains1 = SpriteComponent(
      sprite: await Sprite.load('mountains.png'),
      position: Vector2(0, size.y - 80 - 200), // Position above ground
      size: Vector2(size.x, 200),
    );
    mountains2 = SpriteComponent(
      sprite: await Sprite.load('mountains.png'),
      position: Vector2(size.x, size.y - 80 - 200), // For parallax scrolling
      size: Vector2(size.x, 200),
    );
    clouds1 = SpriteComponent(
      sprite: await Sprite.load('cloud.png'),
      position: Vector2(0, 50),
      size: Vector2(200, 100),
    );
    clouds2 = SpriteComponent(
      sprite: await Sprite.load('cloud.png'),
      position: Vector2(size.x / 2, 80),
      size: Vector2(250, 120),
    );

    // Create world for game elements
    gameWorld = GameWorld();
    add(gameWorld);
    
    // Add background sprites to gameWorld
    gameWorld.add(mountains1);
    gameWorld.add(mountains2);
    gameWorld.add(clouds1);
    gameWorld.add(clouds2);
    
    // Create HUD for UI elements
    gameHud = GameHud();
    add(gameHud);
    
    // Create player stickman based on selected character
    player = Stickman(
      position: Vector2(100, 0), // Will be set to _groundY in Stickman's onLoad
      characterType: playerCharacter,
    );

    // Create computer opponent with random character
    final computerCharacters = ['Ninja', 'Warrior', 'Mage', 'Archer'];
    final randomCharacter = computerCharacters.firstWhere(
      (char) => char != playerCharacter,
    );
    
    computer = Stickman(
      position: Vector2(size.x - 150, 0), // Will be set to _groundY in Stickman's onLoad
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
    if (isPaused) return;
    super.update(dt);
    
    // Update round timer
    if (!isRoundOver) {
      roundTimer -= dt;
      if (roundTimer <= 0) {
        isRoundOver = true;
        _handleRoundEnd();
      }
    }

    // Update parallax for background elements
    final parallaxSpeed = 30.0; // Adjust as needed for desired effect
    mountains1.x -= parallaxSpeed * dt * 0.1; // Slower for distant mountains
    mountains2.x -= parallaxSpeed * dt * 0.1;
    clouds1.x -= parallaxSpeed * dt * 0.5;
    clouds2.x -= parallaxSpeed * dt * 0.5;

    // Reset positions for continuous scrolling
    if (mountains1.x < -size.x) mountains1.x = size.x;
    if (mountains2.x < -size.x) mountains2.x = size.x;
    if (clouds1.x < -size.x) clouds1.x = size.x;
    if (clouds2.x < -size.x) clouds2.x = size.x;

    // Check for game over
    if (player.isDead()) {
      isGameOver = true;
      winner = 'Computer';
      computerScore++;
      onGameOver?.call(false);
    } else if (computer.isDead()) {
      isGameOver = true;
      winner = 'Player';
      playerScore++;
      onGameOver?.call(false);
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
    const padding = 20.0;
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
          _createHitEffect(computer.position, false, player.isSpecialAttacking);
        } else {
          // Play block effect on computer
          _createHitEffect(computer.position, true, false);
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
          _createHitEffect(player.position, false, computer.isSpecialAttacking);
        } else {
          // Play block effect on player
          _createHitEffect(player.position, true, false);
        }
      }
    }
  }

  void _createHitEffect(Vector2 position, bool isBlock, bool isSpecial) {
    final effect = HitEffect(
      position: position,
      isBlock: isBlock,
      isSpecial: isSpecial,
    );
    gameWorld.add(effect);
  }

  void updateAI() {
    if (isGameOver || isRoundOver) return;

    // AI logic (simplified)
    final distance = (player.position - computer.position).length;

    if (distance < 80) {
      // Close range behavior
      final random = math.Random();
      if (random.nextDouble() < 0.4) {
        computer.attack(); // Attack
      } else if (random.nextDouble() < 0.2) {
        computer.block(); // Block
      } else if (computer.specialAttackCooldown <= 0 && random.nextDouble() < 0.3) {
        computer.specialAttack(); // Special attack
      } else {
        computer.move(player.position.x > computer.position.x ? -1 : 1); // Move away
      }
    } else if (distance < 200) {
      // Medium range behavior
      final random = math.Random();
      if (random.nextDouble() < 0.6) {
        computer.move(player.position.x > computer.position.x ? 1 : -1); // Move towards player
      } else if (computer.specialAttackCooldown <= 0 && random.nextDouble() < 0.4) {
        computer.specialAttack(); // Try special attack
      } else {
        computer.attack(); // Attack
      }
    } else {
      // Long range behavior
      final random = math.Random();
      if (random.nextDouble() < 0.8) {
        computer.move(player.position.x > computer.position.x ? 1 : -1); // Move towards player
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
        isPaused = !isPaused;
        return KeyEventResult.handled;
      }
    }

    if (isPaused || isGameOver || isRoundOver) return KeyEventResult.handled;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyA ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        player.move(-2); // Increased speed
      } else if (event.logicalKey == LogicalKeyboardKey.keyD ||
                 event.logicalKey == LogicalKeyboardKey.arrowRight) {
        player.move(2); // Increased speed
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
    }

    if (event is KeyUpEvent) {
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

  void reset() {
    // Reset game state
    isGameOver = false;
    winner = null;
    playerScore = 0;
    computerScore = 0;
    roundTimer = 60.0;
    isRoundOver = false;
    isPaused = false;

    // Reset player and computer
    player.resetHealth();
    player.resetCombo();
    player.resetSpecialAttackCooldown();
    computer.resetHealth();
    computer.resetCombo();
    computer.resetSpecialAttackCooldown();

    // Reset positions
    player.position = Vector2(100, 0);
    computer.position = Vector2(size.x - 150, 0);
  }
}

class HitEffect extends PositionComponent {
  static const double duration = 0.3;
  double _timer = 0.0;
  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  
  final bool isBlock;
  final bool isSpecial;

  HitEffect({
    required Vector2 position,
    this.isBlock = false,
    this.isSpecial = false,
  }) {
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
    
    if (isBlock) {
      // Draw shield effect
      _paint.color = Colors.blue.withOpacity(opacity);
      canvas.drawCircle(
        const Offset(0, 0),
        radius,
        _paint,
      );
      // Draw shield lines
      for (var i = 0; i < 8; i++) {
        final angle = (i * math.pi / 4) + (progress * math.pi);
        final x = math.cos(angle) * radius;
        final y = math.sin(angle) * radius;
        canvas.drawLine(
          const Offset(0, 0),
          Offset(x, y),
          _paint,
        );
      }
    } else if (isSpecial) {
      // Draw special attack effect
      _paint.color = Colors.purple.withOpacity(opacity);
      for (var i = 0; i < 3; i++) {
        final angle = (i * 2 * math.pi / 3) + (progress * math.pi * 2);
        final x = math.cos(angle) * radius;
        final y = math.sin(angle) * radius;
        canvas.drawCircle(
          Offset(x, y),
          radius * 0.5,
          _paint,
        );
      }
    } else {
      // Draw normal hit effect
      _paint.color = Colors.yellow.withOpacity(opacity);
      canvas.drawCircle(
        const Offset(0, 0),
        radius,
        _paint,
      );
      // Draw hit lines
      for (var i = 0; i < 4; i++) {
        final angle = (i * math.pi / 2) + (progress * math.pi);
        final x = math.cos(angle) * radius * 1.5;
        final y = math.sin(angle) * radius * 1.5;
        canvas.drawLine(
          const Offset(0, 0),
          Offset(x, y),
          _paint,
        );
      }
    }
  }
}

class GameWorld extends PositionComponent {
  @override
  void render(Canvas canvas) {
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

    // Mountains and clouds are now handled by SpriteComponents in StickmanFightGame
    // _drawMountains(canvas);
    // _drawClouds(canvas);

    // Draw ground (raised)
    final groundPaint = Paint()
      ..color = const Color(0xFF8B4513); // Brown color for ground
    final groundHeight = 80.0; // Raised ground height
    canvas.drawRect(
      Rect.fromLTWH(0, game.size.y - groundHeight, game.size.x, groundHeight),
      groundPaint,
    );

    // Draw grass on top of ground
    final grassPaint = Paint()
      ..color = const Color(0xFF228B22); // Forest green color
    canvas.drawRect(
      Rect.fromLTWH(0, game.size.y - groundHeight, game.size.x, 5),
      grassPaint,
    );
  }

  // Remove these methods as they are replaced by image assets
  // void _drawMountains(Canvas canvas) { ... }
  // void _drawClouds(Canvas canvas) { ... }
}

class GameHud extends PositionComponent {
  // Add new UI constants
  static const double comboTextSize = 24.0;
  static const double timerTextSize = 32.0;
  static const double cooldownBarHeight = 5.0;
  static const double cooldownBarWidth = 100.0;
  
  @override
  void render(Canvas canvas) {
    final game = parent as StickmanFightGame;
    
    // Draw health bars
    _drawHealthBars(canvas, game);
    
    // Draw round timer
    _drawRoundTimer(canvas, game);
    
    // Draw combo counter
    _drawComboCounter(canvas, game);
    
    // Draw special attack cooldown
    _drawSpecialAttackCooldown(canvas, game);
    
    // Draw controls hint
    _drawControlsHint(canvas, game);

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

  void _drawRoundTimer(Canvas canvas, StickmanFightGame game) {
    final minutes = (game.roundTimer ~/ 60).toString().padLeft(2, '0');
    final seconds = (game.roundTimer % 60).toString().padLeft(2, '0');
    final timeText = '$minutes:$seconds';
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: timeText,
        style: TextStyle(
          color: Colors.white,
          fontSize: timerTextSize,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 5,
              offset: const Offset(2, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (game.size.x - textPainter.width) / 2,
        20,
      ),
    );
  }

  void _drawComboCounter(Canvas canvas, StickmanFightGame game) {
    if (game.player.comboCount > 1) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${game.player.comboCount}x COMBO!',
          style: TextStyle(
            color: Colors.yellow,
            fontSize: comboTextSize,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 5,
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          (game.size.x - textPainter.width) / 2,
          70,
        ),
      );
    }
  }

  void _drawSpecialAttackCooldown(Canvas canvas, StickmanFightGame game) {
    // Draw player's special attack cooldown
    _drawCooldownBar(
      canvas,
      StickmanFightGame.healthBarPadding,
      StickmanFightGame.healthBarPadding + StickmanFightGame.healthBarHeight + 10,
      game.player.specialAttackCooldown,
      game.player.maxSpecialAttackCooldown,
      Colors.blue,
    );

    // Draw computer's special attack cooldown
    _drawCooldownBar(
      canvas,
      game.size.x - StickmanFightGame.healthBarWidth - StickmanFightGame.healthBarPadding,
      StickmanFightGame.healthBarPadding + StickmanFightGame.healthBarHeight + 10,
      game.computer.specialAttackCooldown,
      game.computer.maxSpecialAttackCooldown,
      Colors.red,
    );
  }

  void _drawCooldownBar(
    Canvas canvas,
    double x,
    double y,
    double currentCooldown,
    double maxCooldown,
    Color color,
  ) {
    // Draw background
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(x, y, cooldownBarWidth, cooldownBarHeight),
      bgPaint,
    );

    // Draw cooldown progress
    final cooldownPercentage = currentCooldown / maxCooldown;
    final cooldownPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(x, y, cooldownBarWidth * (1 - cooldownPercentage), cooldownBarHeight),
      cooldownPaint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawRect(
      Rect.fromLTWH(x, y, cooldownBarWidth, cooldownBarHeight),
      borderPaint,
    );
  }

  void _drawControlsHint(Canvas canvas, StickmanFightGame game) {
    final controls = [
      'A/D: Move',
      'SPACE: Jump',
      'J: Attack',
      'K: Block',
      'L: Special',
    ];

    final textPainter = TextPainter(
      text: TextSpan(
        text: controls.join(' | '),
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 14,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 3,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (game.size.x - textPainter.width) / 2,
        game.size.y - 30,
      ),
    );
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
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 10,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (game.size.x - textPainter.width) / 2,
        (game.size.y - textPainter.height) / 2 - 100,
      ),
    );

    // Draw score
    final scoreText = TextPainter(
      text: TextSpan(
        text: 'Score: ${game.playerScore} - ${game.computerScore}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 10,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    scoreText.paint(
      canvas,
      Offset(
        (game.size.x - scoreText.width) / 2,
        (game.size.y - scoreText.height) / 2,
      ),
    );

    // Draw buttons
    _drawGameOverButton(
      canvas,
      game,
      'Play Again',
      (game.size.y - 100) / 2 + 50,
    );

    _drawGameOverButton(
      canvas,
      game,
      'Choose Character',
      (game.size.y - 100) / 2 + 120,
    );
  }

  void _drawGameOverButton(
    Canvas canvas,
    StickmanFightGame game,
    String text,
    double y,
  ) {
    const buttonWidth = 200.0;
    const buttonHeight = 50.0;
    final x = (game.size.x - buttonWidth) / 2;

    // Draw button background
    final buttonPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final buttonRect = Rect.fromLTWH(x, y, buttonWidth, buttonHeight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, const Radius.circular(10)),
      buttonPaint,
    );

    // Draw button border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(buttonRect, const Radius.circular(10)),
      borderPaint,
    );

    // Draw button text
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 5,
              offset: Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        x + (buttonWidth - textPainter.width) / 2,
        y + (buttonHeight - textPainter.height) / 2,
      ),
    );
  }
}

