import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'stickman_fight_game.dart';

class Stickman extends PositionComponent with HasGameRef<StickmanFightGame> {
  final String characterType;
  bool facingLeft;
  late double currentHealth;
  double maxHealth = 100.0;
  double specialAttackCooldown = 0.0;
  double specialAttackCooldownDuration = 5.0;
  
  // Movement properties
  double moveSpeed = 400.0;
  double jumpForce = 400.0;
  double gravity = 800.0;
  double verticalVelocity = 0.0;
  bool isGrounded = true;
  
  // Animation properties
  bool isAttacking = false;
  bool isSpecialAttacking = false;
  bool isBlocking = false;
  bool isJumping = false;
  double attackTimer = 0.0;
  double specialAttackTimer = 0.0;
  double blockTimer = 0.0;
  double jumpTimer = 0.0;
  double walkTimer = 0.0;
  bool isWalking = false;
  
  // Animation constants
  static const double attackDuration = 0.3;
  static const double specialAttackDuration = 0.5;
  static const double blockDuration = 0.2;
  static const double jumpDuration = 0.4;
  static const double walkCycleDuration = 0.4; // Duration of one complete walk cycle
  
  // Character-specific properties
  late Color characterColor;
  late String specialMoveName;
  late double specialMoveDamage;
  
  // Add combo-related properties
  int comboCount = 0;
  double comboResetTimer = 0.0;
  static const double comboResetDuration = 2.0; // Time window to maintain combo
  double maxSpecialAttackCooldown = 5.0; // Default value, can be overridden in _initializeCharacterProperties
  
  // Add ground position property
  late double _groundY;
  
  Stickman({
    required Vector2 position,
    this.facingLeft = false,
    required this.characterType,
  }) {
    this.position = position;
    size = Vector2(50, 100);
    _initializeCharacterProperties();
    currentHealth = maxHealth;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Calculate ground position based on game size and stickman size
    _groundY = gameRef.size.y - 80 - size.y; // 80 is the new ground height
    // Ensure stickman starts on the ground
    position.y = _groundY;
  }

  void _initializeCharacterProperties() {
    switch (characterType) {
      case 'Ninja':
        characterColor = Colors.black;
        specialMoveName = 'Shadow Strike';
        specialMoveDamage = 25.0;
        moveSpeed = 250.0; // Faster movement
        maxSpecialAttackCooldown = 4.0; // Shorter cooldown
        break;
      case 'Warrior':
        characterColor = Colors.red;
        specialMoveName = 'Berserker Rage';
        specialMoveDamage = 30.0;
        maxHealth = 120.0; // More health
        maxSpecialAttackCooldown = 6.0; // Longer cooldown
        break;
      case 'Mage':
        characterColor = Colors.blue;
        specialMoveName = 'Arcane Blast';
        specialMoveDamage = 35.0;
        maxSpecialAttackCooldown = 4.0; // Shorter cooldown
        break;
      case 'Archer':
        characterColor = Colors.green;
        specialMoveName = 'Precision Shot';
        specialMoveDamage = 40.0;
        moveSpeed = 220.0; // Balanced movement
        maxSpecialAttackCooldown = 5.0; // Standard cooldown
        break;
      default:
        characterColor = Colors.grey;
        specialMoveName = 'Special Attack';
        specialMoveDamage = 20.0;
        maxSpecialAttackCooldown = 5.0; // Default cooldown
    }
  }

  void resetHealth() {
    currentHealth = maxHealth;
  }

  void move(double direction) {
    if (isBlocking) return;
    
    position.x += direction * moveSpeed * 0.016;
    isWalking = direction != 0;
    
    if (direction != 0) {
      facingLeft = direction < 0;
    }
  }

  void jump() {
    if (!isGrounded || isJumping) return;
    
    isJumping = true;
    isGrounded = false;
    verticalVelocity = -jumpForce;
    jumpTimer = 0.0;
  }

  void attack() {
    if (isAttacking || isSpecialAttacking || isBlocking) return;
    
    isAttacking = true;
    attackTimer = 0.0;
    
    // Update combo
    comboResetTimer = comboResetDuration;
    comboCount++;
  }

  void specialAttack() {
    if (isAttacking || isSpecialAttacking || isBlocking || specialAttackCooldown > 0) return;
    
    isSpecialAttacking = true;
    specialAttackTimer = 0.0;
    specialAttackCooldown = specialAttackCooldownDuration;
  }

  void block() {
    if (isAttacking || isSpecialAttacking) return;
    
    isBlocking = true;
    blockTimer = 0.0;
  }

  void stopBlocking() {
    isBlocking = false;
  }

  void resetCombo() {
    comboCount = 0;
    comboResetTimer = 0.0;
  }

  void resetSpecialAttackCooldown() {
    specialAttackCooldown = 0.0;
  }

  void takeDamage(double amount) {
    if (isBlocking) {
      amount *= 0.2; // Block reduces damage by 80%
    }
    currentHealth = math.max(0, currentHealth - amount);
    resetCombo(); // Reset combo when taking damage
  }

  bool isDead() => currentHealth <= 0;

  @override
  void update(double dt) {
    super.update(dt);
    
    // Update combo timer
    if (comboResetTimer > 0) {
      comboResetTimer -= dt;
      if (comboResetTimer <= 0) {
        resetCombo();
      }
    }
    
    // Update cooldowns
    if (specialAttackCooldown > 0) {
      specialAttackCooldown -= dt;
    }
    
    // Update attack timers
    if (isAttacking) {
      attackTimer += dt;
      if (attackTimer >= attackDuration) {
        isAttacking = false;
      }
    }
    
    if (isSpecialAttacking) {
      specialAttackTimer += dt;
      if (specialAttackTimer >= specialAttackDuration) {
        isSpecialAttacking = false;
      }
    }
    
    if (isBlocking) {
      blockTimer += dt;
      if (blockTimer >= blockDuration) {
        isBlocking = false;
      }
    }
    
    // Update jump
    if (isJumping) {
      jumpTimer += dt;
      if (jumpTimer >= jumpDuration) {
        isJumping = false;
      }
    }

    // Update walk animation
    if (isWalking) {
      walkTimer += dt;
      if (walkTimer >= walkCycleDuration) {
        walkTimer = 0.0;
      }
    } else {
      walkTimer = 0.0;
    }
    
    // Apply gravity
    if (!isGrounded) {
      verticalVelocity += gravity * dt;
      position.y += verticalVelocity * dt;
      
      // Check for ground collision
      if (position.y >= _groundY) {
        position.y = _groundY;
        verticalVelocity = 0;
        isGrounded = true;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = characterColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    final headPaint = Paint()
      ..color = characterColor
      ..style = PaintingStyle.fill;

    // Draw head with a slight glow effect
    final glowPaint = Paint()
      ..color = characterColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      const Offset(0, -30),
      18,
      glowPaint,
    );
    canvas.drawCircle(
      const Offset(0, -30),
      15,
      headPaint,
    );

    // Draw body
    canvas.drawLine(
      const Offset(0, -15),
      const Offset(0, 20),
      paint,
    );

    // Draw arms with improved angles
    final armAngle = isAttacking ? 45.0 : 0.0;
    const armLength = 25.0;
    
    // Left arm
    canvas.drawLine(
      const Offset(0, 0),
      Offset(
        -armLength * math.cos(math.pi / 4 + armAngle * math.pi / 180),
        armLength * math.sin(math.pi / 4 + armAngle * math.pi / 180),
      ),
      paint,
    );

    // Right arm
    canvas.drawLine(
      const Offset(0, 0),
      Offset(
        armLength * math.cos(math.pi / 4 - armAngle * math.pi / 180),
        armLength * math.sin(math.pi / 4 - armAngle * math.pi / 180),
      ),
      paint,
    );

    // Draw legs with walking animation
    const legLength = 30.0;
    double leftLegAngle = 0.0;
    double rightLegAngle = 0.0;

    if (isWalking) {
      // Calculate leg angles based on walk cycle
      final cycleProgress = walkTimer / walkCycleDuration;
      final angleOffset = math.sin(cycleProgress * math.pi * 2) * 30.0; // 30 degrees max swing
      leftLegAngle = angleOffset;
      rightLegAngle = -angleOffset;
    } else if (isJumping) {
      leftLegAngle = -30.0;
      rightLegAngle = -30.0;
    }

    // Left leg
    canvas.drawLine(
      const Offset(0, 20),
      Offset(
        -legLength * math.cos(math.pi / 4 + leftLegAngle * math.pi / 180),
        20 + legLength * math.sin(math.pi / 4 + leftLegAngle * math.pi / 180),
      ),
      paint,
    );

    // Right leg
    canvas.drawLine(
      const Offset(0, 20),
      Offset(
        legLength * math.cos(math.pi / 4 - rightLegAngle * math.pi / 180),
        20 + legLength * math.sin(math.pi / 4 - rightLegAngle * math.pi / 180),
      ),
      paint,
    );

    // Draw special effects based on character type
    _drawSpecialEffects(canvas, paint);
  }

  void _drawSpecialEffects(Canvas canvas, Paint basePaint) {
    final effectPaint = Paint()
      ..color = characterColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0; // Increased from 3.0 to 4.0 for thicker effect lines

    switch (characterType) {
      case 'Ninja':
        // Draw ninja mask with thicker lines
        canvas.drawLine(
          const Offset(-12, -25),
          const Offset(12, -25),
          basePaint,
        );
        // Draw sword with glow effect
        if (isAttacking) {
          final swordGlowPaint = Paint()
            ..color = characterColor.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8.0;
          canvas.drawLine(
            const Offset(30, -10),
            const Offset(45, -25),
            swordGlowPaint,
          );
          canvas.drawLine(
            const Offset(30, -10),
            const Offset(40, -20),
            basePaint,
          );
        }
        break;
      case 'Warrior':
        // Draw shield with improved effect
        if (isBlocking) {
          final shieldGlowPaint = Paint()
            ..color = characterColor.withOpacity(0.3)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(
            const Offset(-20, 0),
            18,
            shieldGlowPaint,
          );
          canvas.drawCircle(
            const Offset(-20, 0),
            15,
            effectPaint,
          );
        }
        // Draw sword with glow effect
        if (isAttacking) {
          final swordGlowPaint = Paint()
            ..color = characterColor.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8.0;
          canvas.drawLine(
            const Offset(30, -10),
            const Offset(45, -25),
            swordGlowPaint,
          );
          canvas.drawLine(
            const Offset(30, -10),
            const Offset(40, -20),
            basePaint,
          );
        }
        break;
      case 'Mage':
        // Draw magic staff with improved effects
        if (isAttacking) {
          final staffGlowPaint = Paint()
            ..color = characterColor.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8.0;
          canvas.drawLine(
            const Offset(30, -10),
            const Offset(45, -25),
            staffGlowPaint,
          );
          canvas.drawLine(
            const Offset(30, -10),
            const Offset(40, -20),
            basePaint,
          );
          // Draw enhanced magic effect
          final magicGlowPaint = Paint()
            ..color = characterColor.withOpacity(0.3)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(
            const Offset(40, -20),
            15,
            magicGlowPaint,
          );
          canvas.drawCircle(
            const Offset(40, -20),
            10,
            effectPaint,
          );
        }
        break;
      case 'Archer':
        // Draw bow with improved effects
        if (isAttacking) {
          final bowGlowPaint = Paint()
            ..color = characterColor.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6.0;
          canvas.drawArc(
            const Rect.fromLTWH(20, -25, 25, 25),
            0,
            math.pi,
            false,
            bowGlowPaint,
          );
          canvas.drawArc(
            const Rect.fromLTWH(20, -20, 20, 20),
            0,
            math.pi,
            false,
            basePaint,
          );
          // Draw arrow with glow
          final arrowGlowPaint = Paint()
            ..color = characterColor.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8.0;
          canvas.drawLine(
            const Offset(30, -10),
            const Offset(45, -25),
            arrowGlowPaint,
          );
          canvas.drawLine(
            const Offset(30, -10),
            const Offset(40, -20),
            basePaint,
          );
        }
        break;
    }
  }
}
