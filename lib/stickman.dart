import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Stickman extends PositionComponent {
  final bool facingLeft;
  final String characterType;
  late final Color characterColor;
  
  // Movement properties
  static const double moveSpeed = 200.0;
  static const double jumpForce = -400.0;
  static const double gravity = 800.0;
  
  Vector2 velocity = Vector2.zero();
  bool isJumping = false;
  bool isAttacking = false;
  bool isSpecialAttacking = false;
  double attackCooldown = 0.0;
  double specialAttackCooldown = 0.0;
  
  // Health system
  double maxHealth = 100.0;
  double currentHealth = 100.0;
  bool isInvulnerable = false;
  double invulnerabilityTime = 0.0;
  
  // Animation states
  double animationTime = 0.0;
  bool isMoving = false;
  bool isBlocking = false;
  bool isHit = false;

  Stickman({
    required Vector2 position,
    this.facingLeft = false,
    required this.characterType,
  }) : super(position: position) {
    size = Vector2(50, 120);
    
    // Set character color and properties based on type
    switch (characterType) {
      case 'Ninja':
        characterColor = Colors.black;
        maxHealth = 80.0; // Ninja is faster but has less health
        break;
      case 'Warrior':
        characterColor = Colors.red;
        maxHealth = 120.0; // Warrior has more health
        break;
      case 'Mage':
        characterColor = Colors.blue;
        maxHealth = 90.0; // Mage has medium health
        break;
      case 'Archer':
        characterColor = Colors.green;
        maxHealth = 85.0; // Archer has medium health
        break;
      default:
        characterColor = Colors.grey;
    }
    currentHealth = maxHealth;
  }

  void move(double direction) {
    velocity.x = direction * moveSpeed;
    isMoving = direction != 0;
  }

  void jump() {
    if (!isJumping) {
      velocity.y = jumpForce;
      isJumping = true;
    }
  }

  void attack() {
    if (attackCooldown <= 0) {
      isAttacking = true;
      attackCooldown = 0.5; // Half second cooldown
    }
  }

  void specialAttack() {
    if (specialAttackCooldown <= 0) {
      isSpecialAttacking = true;
      specialAttackCooldown = 2.0; // 2 second cooldown
    }
  }

  void block() {
    isBlocking = true;
  }

  void stopBlocking() {
    isBlocking = false;
  }

  void takeDamage(double damage) {
    if (!isInvulnerable && !isBlocking) {
      currentHealth = max(0, currentHealth - damage);
      isHit = true;
      isInvulnerable = true;
      invulnerabilityTime = 0.5; // Half second invulnerability
    }
  }

  bool isDead() => currentHealth <= 0;

  @override
  void update(double dt) {
    super.update(dt);
    
    // Apply gravity
    velocity.y += gravity * dt;
    
    // Update position
    position += velocity * dt;
    
    // Ground check
    if (position.y > 400) { // Assuming ground level
      position.y = 400;
      velocity.y = 0;
      isJumping = false;
    }
    
    // Update animation time
    animationTime += dt;
    
    // Update cooldowns
    if (attackCooldown > 0) {
      attackCooldown -= dt;
    }
    if (specialAttackCooldown > 0) {
      specialAttackCooldown -= dt;
    }
    if (isAttacking && attackCooldown <= 0) {
      isAttacking = false;
    }
    if (isSpecialAttacking && specialAttackCooldown <= 0) {
      isSpecialAttacking = false;
    }

    // Update invulnerability
    if (isInvulnerable) {
      invulnerabilityTime -= dt;
      if (invulnerabilityTime <= 0) {
        isInvulnerable = false;
        isHit = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw health bar
    final healthBarWidth = 50.0;
    final healthBarHeight = 5.0;
    final healthPercentage = currentHealth / maxHealth;
    
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, -20, healthBarWidth, healthBarHeight),
      Paint()..color = Colors.grey,
    );
    
    // Health
    canvas.drawRect(
      Rect.fromLTWH(0, -20, healthBarWidth * healthPercentage, healthBarHeight),
      Paint()..color = Colors.green,
    );

    final paint = Paint()
      ..color = isInvulnerable ? characterColor.withOpacity(0.5) : characterColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Calculate animation offsets
    double armSwing = isMoving ? sin(animationTime * 10) * 20 : 0;
    double legSwing = isMoving ? sin(animationTime * 10) * 15 : 0;
    double attackOffset = isAttacking ? 30 : 0;
    double specialAttackOffset = isSpecialAttacking ? 50 : 0;
    double blockOffset = isBlocking ? 45 : 0;
    double hitOffset = isHit ? sin(animationTime * 30) * 5 : 0;

    // Draw head
    canvas.drawCircle(
      Offset(size.x / 2, 20 + hitOffset),
      15,
      paint,
    );

    // Draw body
    canvas.drawLine(
      Offset(size.x / 2, 35 + hitOffset),
      Offset(size.x / 2, 80 + hitOffset),
      paint,
    );

    // Draw arms with animation
    if (isSpecialAttacking) {
      // Special attack animation
      _drawSpecialAttack(canvas, paint, specialAttackOffset);
    } else if (isAttacking) {
      // Normal attack animation
      canvas.drawLine(
        Offset(size.x / 2, 45 + hitOffset),
        Offset(facingLeft ? -attackOffset : size.x + attackOffset, 60 + hitOffset),
        paint,
      );
    } else if (isBlocking) {
      // Block animation
      canvas.drawLine(
        Offset(size.x / 2, 45 + hitOffset),
        Offset(facingLeft ? -blockOffset : size.x + blockOffset, 30 + hitOffset),
        paint,
      );
    } else {
      // Normal arm movement
      canvas.drawLine(
        Offset(size.x / 2, 45 + hitOffset),
        Offset(facingLeft ? -armSwing : size.x + armSwing, 60 + hitOffset),
        paint,
      );
    }
    canvas.drawLine(
      Offset(size.x / 2, 45 + hitOffset),
      Offset(facingLeft ? size.x + armSwing : -armSwing, 60 + hitOffset),
      paint,
    );

    // Draw legs with animation
    canvas.drawLine(
      Offset(size.x / 2, 80 + hitOffset),
      Offset(facingLeft ? -legSwing : size.x / 2, 120 + hitOffset),
      paint,
    );
    canvas.drawLine(
      Offset(size.x / 2, 80 + hitOffset),
      Offset(facingLeft ? size.x / 2 : legSwing, 120 + hitOffset),
      paint,
    );

    // Draw character-specific effects
    if (isAttacking || isSpecialAttacking) {
      _drawAttackEffects(canvas, paint, attackOffset, specialAttackOffset);
    }
  }

  void _drawSpecialAttack(Canvas canvas, Paint paint, double offset) {
    switch (characterType) {
      case 'Ninja':
        // Shadow clone technique
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(
            Offset(facingLeft ? -offset - i * 20 : size.x + offset + i * 20, 60),
            10,
            paint..style = PaintingStyle.stroke,
          );
        }
        break;
      case 'Warrior':
        // Whirlwind attack
        for (var i = 0; i < 8; i++) {
          final angle = i * pi / 4;
          canvas.drawLine(
            Offset(size.x / 2, 45),
            Offset(
              size.x / 2 + cos(angle) * offset,
              45 + sin(angle) * offset,
            ),
            paint,
          );
        }
        break;
      case 'Mage':
        // Fireball
        canvas.drawCircle(
          Offset(facingLeft ? -offset : size.x + offset, 60),
          20,
          paint..style = PaintingStyle.fill,
        );
        break;
      case 'Archer':
        // Multi-shot
        for (var i = -1; i <= 1; i++) {
          canvas.drawLine(
            Offset(facingLeft ? -offset : size.x + offset, 60),
            Offset(
              facingLeft ? -offset - 50 : size.x + offset + 50,
              60 + i * 20,
            ),
            paint,
          );
        }
        break;
    }
  }

  void _drawAttackEffects(Canvas canvas, Paint paint, double attackOffset, double specialOffset) {
    final offset = isSpecialAttacking ? specialOffset : attackOffset;
    switch (characterType) {
      case 'Ninja':
        // Draw ninja star effect
        canvas.drawCircle(
          Offset(facingLeft ? -offset : size.x + offset, 60),
          5,
          paint,
        );
        break;
      case 'Warrior':
        // Draw sword effect
        canvas.drawLine(
          Offset(facingLeft ? -offset : size.x + offset, 60),
          Offset(facingLeft ? -offset - 20 : size.x + offset + 20, 50),
          paint,
        );
        break;
      case 'Mage':
        // Draw magic effect
        canvas.drawCircle(
          Offset(facingLeft ? -offset : size.x + offset, 60),
          10,
          paint..style = PaintingStyle.fill,
        );
        break;
      case 'Archer':
        // Draw arrow effect
        canvas.drawLine(
          Offset(facingLeft ? -offset : size.x + offset, 60),
          Offset(facingLeft ? -offset - 30 : size.x + offset + 30, 60),
          paint,
        );
        break;
    }
  }
}
