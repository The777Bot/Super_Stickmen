import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'dart:math' as math;

class Stickman extends PositionComponent {
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
  
  // Animation constants
  static const double attackDuration = 0.3;
  static const double specialAttackDuration = 0.5;
  static const double blockDuration = 0.2;
  static const double jumpDuration = 0.4;
  
  // Character-specific properties
  late Color characterColor;
  late String specialMoveName;
  late double specialMoveDamage;
  
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

  void _initializeCharacterProperties() {
    switch (characterType) {
      case 'Ninja':
        characterColor = Colors.black;
        specialMoveName = 'Shadow Strike';
        specialMoveDamage = 25.0;
        moveSpeed = 250.0; // Faster movement
        break;
      case 'Warrior':
        characterColor = Colors.red;
        specialMoveName = 'Berserker Rage';
        specialMoveDamage = 30.0;
        maxHealth = 120.0; // More health
        break;
      case 'Mage':
        characterColor = Colors.blue;
        specialMoveName = 'Arcane Blast';
        specialMoveDamage = 35.0;
        specialAttackCooldownDuration = 4.0; // Shorter cooldown
        break;
      case 'Archer':
        characterColor = Colors.green;
        specialMoveName = 'Precision Shot';
        specialMoveDamage = 40.0;
        moveSpeed = 220.0; // Balanced movement
        break;
      default:
        characterColor = Colors.grey;
        specialMoveName = 'Special Attack';
        specialMoveDamage = 20.0;
    }
  }

  void resetHealth() {
    currentHealth = maxHealth;
  }

  void move(double direction) {
    if (isBlocking) return;
    
    position.x += direction * moveSpeed * 0.016;
    
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

  void takeDamage(double amount) {
    if (isBlocking) {
      amount *= 0.2; // Block reduces damage by 80%
    }
    currentHealth = math.max(0, currentHealth - amount);
  }

  bool isDead() => currentHealth <= 0;

  @override
  void update(double dt) {
    super.update(dt);
    
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
    
    // Apply gravity
    if (!isGrounded) {
      verticalVelocity += gravity * dt;
      position.y += verticalVelocity * dt;
      
      // Check for ground collision
      if (position.y >= 500) { // Ground level
        position.y = 500;
        verticalVelocity = 0;
        isGrounded = true;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw character body
    final bodyPaint = Paint()
      ..color = characterColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // Draw character based on state
    if (isAttacking) {
      _drawAttackingStickman(canvas, bodyPaint);
    } else if (isSpecialAttacking) {
      _drawSpecialAttackingStickman(canvas, bodyPaint);
    } else if (isBlocking) {
      _drawBlockingStickman(canvas, bodyPaint);
    } else if (isJumping) {
      _drawJumpingStickman(canvas, bodyPaint);
    } else {
      _drawNormalStickman(canvas, bodyPaint);
    }
    
    // Draw special attack cooldown indicator
    if (specialAttackCooldown > 0) {
      _drawCooldownIndicator(canvas);
    }
  }

  void _drawNormalStickman(Canvas canvas, Paint paint) {
    // Head
    canvas.drawCircle(Offset(0, -40), 10, paint);
    
    // Body
    canvas.drawLine(Offset(0, -30), Offset(0, 20), paint);
    
    // Arms
    canvas.drawLine(Offset(0, -20), Offset(-15, 0), paint);
    canvas.drawLine(Offset(0, -20), Offset(15, 0), paint);
    
    // Legs
    canvas.drawLine(Offset(0, 20), Offset(-15, 40), paint);
    canvas.drawLine(Offset(0, 20), Offset(15, 40), paint);
  }

  void _drawAttackingStickman(Canvas canvas, Paint paint) {
    // Head
    canvas.drawCircle(Offset(0, -40), 10, paint);
    
    // Body
    canvas.drawLine(Offset(0, -30), Offset(0, 20), paint);
    
    // Arms (attacking pose)
    canvas.drawLine(Offset(0, -20), Offset(-15, 0), paint);
    canvas.drawLine(Offset(0, -20), Offset(30, -10), paint);
    
    // Legs
    canvas.drawLine(Offset(0, 20), Offset(-15, 40), paint);
    canvas.drawLine(Offset(0, 20), Offset(15, 40), paint);
    
    // Attack effect
    final effectPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(20, -15), width: 40, height: 40),
      0,
      math.pi,
      false,
      effectPaint,
    );
  }

  void _drawSpecialAttackingStickman(Canvas canvas, Paint paint) {
    // Head
    canvas.drawCircle(Offset(0, -40), 10, paint);
    
    // Body
    canvas.drawLine(Offset(0, -30), Offset(0, 20), paint);
    
    // Arms (special attack pose)
    canvas.drawLine(Offset(0, -20), Offset(-20, -10), paint);
    canvas.drawLine(Offset(0, -20), Offset(40, -20), paint);
    
    // Legs
    canvas.drawLine(Offset(0, 20), Offset(-15, 40), paint);
    canvas.drawLine(Offset(0, 20), Offset(15, 40), paint);
    
    // Special attack effect
    final effectPaint = Paint()
      ..color = characterColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset(30, -20), 20, effectPaint);
  }

  void _drawBlockingStickman(Canvas canvas, Paint paint) {
    // Head
    canvas.drawCircle(Offset(0, -40), 10, paint);
    
    // Body
    canvas.drawLine(Offset(0, -30), Offset(0, 20), paint);
    
    // Arms (blocking pose)
    canvas.drawLine(Offset(0, -20), Offset(-20, 0), paint);
    canvas.drawLine(Offset(0, -20), Offset(20, 0), paint);
    
    // Legs
    canvas.drawLine(Offset(0, 20), Offset(-15, 40), paint);
    canvas.drawLine(Offset(0, 20), Offset(15, 40), paint);
    
    // Block effect
    final effectPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(0, 0), 30, effectPaint);
  }

  void _drawJumpingStickman(Canvas canvas, Paint paint) {
    // Head
    canvas.drawCircle(Offset(0, -40), 10, paint);
    
    // Body
    canvas.drawLine(Offset(0, -30), Offset(0, 20), paint);
    
    // Arms (jumping pose)
    canvas.drawLine(Offset(0, -20), Offset(-20, -30), paint);
    canvas.drawLine(Offset(0, -20), Offset(20, -30), paint);
    
    // Legs
    canvas.drawLine(Offset(0, 20), Offset(-15, 30), paint);
    canvas.drawLine(Offset(0, 20), Offset(15, 30), paint);
  }

  void _drawCooldownIndicator(Canvas canvas) {
    final cooldownPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    final progress = specialAttackCooldown / specialAttackCooldownDuration;
    final angle = 2 * math.pi * progress;
    
    canvas.drawArc(
      Rect.fromCenter(center: Offset(0, -50), width: 20, height: 20),
      -math.pi / 2,
      angle,
      true,
      cooldownPaint,
    );
  }
}
