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
  late Color _headColor;
  late Color _bodyColor;
  late Color _limbColor;
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
    size = Vector2(70, 140);
    _initializeCharacterProperties();
    currentHealth = maxHealth;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Calculate ground position based on game size and stickman size
    _groundY = gameRef.size.y - 40 - size.y; // 120 is the new ground height
    // Ensure stickman starts on the ground
    position.y = _groundY;
  }

  void _initializeCharacterProperties() {
    switch (characterType) {
      case 'Ninja':
        characterColor = Colors.black;
        _headColor = Colors.grey.shade900;
        _bodyColor = Colors.black;
        _limbColor = Colors.teal.shade300;
        specialMoveName = 'Shadow Strike';
        specialMoveDamage = 25.0;
        moveSpeed = 250.0; // Faster movement
        maxSpecialAttackCooldown = 4.0; // Shorter cooldown
        break;
      case 'Warrior':
        characterColor = Colors.red;
        _headColor = Colors.brown.shade800;
        _bodyColor = Colors.red.shade700;
        _limbColor = Colors.yellow.shade700;
        specialMoveName = 'Berserker Rage';
        specialMoveDamage = 30.0;
        maxHealth = 120.0; // More health
        maxSpecialAttackCooldown = 6.0; // Longer cooldown
        break;
      case 'Mage':
        characterColor = Colors.blue;
        _headColor = Colors.deepPurple.shade700;
        _bodyColor = Colors.blue.shade700;
        _limbColor = Colors.lightBlue.shade300;
        specialMoveName = 'Arcane Blast';
        specialMoveDamage = 35.0;
        maxSpecialAttackCooldown = 4.0; // Shorter cooldown
        break;
      case 'Archer':
        characterColor = Colors.green;
        _headColor = Colors.grey.shade700;
        _bodyColor = Colors.green.shade700;
        _limbColor = Colors.brown.shade300;
        specialMoveName = 'Precision Shot';
        specialMoveDamage = 40.0;
        moveSpeed = 220.0; // Balanced movement
        maxSpecialAttackCooldown = 5.0; // Standard cooldown
        break;
      default:
        characterColor = Colors.grey;
        _headColor = Colors.grey.shade700;
        _bodyColor = Colors.grey.shade500;
        _limbColor = Colors.grey.shade300;
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
    print('Stickman moving. isWalking: $isWalking, direction: $direction'); // Debug print
    
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
    specialAttackCooldown = maxSpecialAttackCooldown;
    print('Special Attack Triggered');
  }

  void block() {
    if (isAttacking || isSpecialAttacking) return;
    
    isBlocking = true;
    blockTimer = 0.0;
    print('Block Triggered');
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
      print('Walking: walkTimer=$walkTimer, cycleProgress=${walkTimer / walkCycleDuration}'); // Debug print
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
    // Paint for body and limbs (uses _limbColor for strokes)
    final limbPaint = Paint()
      ..color = _limbColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    // Paint for head fill
    final headFillPaint = Paint()
      ..color = _headColor
      ..style = PaintingStyle.fill;

    // Paint for head glow effect
    final headGlowPaint = Paint()
      ..color = _headColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Paint for body fill
    final bodyPaint = Paint()
      ..color = _bodyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    // Draw head with a slight glow effect
    canvas.drawCircle(
      const Offset(0, -40),
      22,
      headGlowPaint,
    );
    canvas.drawCircle(
      const Offset(0, -40),
      20,
      headFillPaint,
    );

    // Draw body
    canvas.drawLine(
      const Offset(0, -20),
      const Offset(0, 30),
      bodyPaint, // Use bodyPaint for body
    );

    // Draw arms with improved angles
    final armAngle = isAttacking ? 45.0 : 0.0;
    const armLength = 35.0;
    
    // Left arm
    canvas.drawLine(
      const Offset(0, 0),
      Offset(
        facingLeft ? -armLength * math.cos(armAngle * math.pi / 180) : armLength * math.cos(armAngle * math.pi / 180),
        armLength * math.sin(armAngle * math.pi / 180),
      ),
      limbPaint, // Use limbPaint for arms
    );
    
    // Right arm
    canvas.drawLine(
      const Offset(0, 0),
      Offset(
        facingLeft ? armLength * math.cos(armAngle * math.pi / 180) : -armLength * math.cos(armAngle * math.pi / 180),
        armLength * math.sin(armAngle * math.pi / 180),
      ),
      limbPaint, // Use limbPaint for arms
    );

    // Draw legs
    const legLength = 45.0;
    double leftLegSwingAngle = 0.0; // In radians, for swinging forward/backward
    double rightLegSwingAngle = 0.0; // In radians

    if (isWalking) {
      final cycleProgress = walkTimer / walkCycleDuration;
      // Convert degrees to radians directly for math.sin/cos
      final swingAngle = math.sin(cycleProgress * math.pi * 2) * (45.0 * math.pi / 180.0); // Max swing 45 degrees converted to radians
      leftLegSwingAngle = swingAngle;
      rightLegSwingAngle = -swingAngle;
    } else if (isJumping) {
      leftLegSwingAngle = -45.0 * math.pi / 180.0; // Legs tucked when jumping, convert to radians
      rightLegSwingAngle = -45.0 * math.pi / 180.0;
    }

    // Left leg
    final leftLegEndPoint = Offset(
      (facingLeft ? -1 : 1) * legLength * math.sin(leftLegSwingAngle), // X-component: horizontal swing
      30 + legLength * math.cos(leftLegSwingAngle), // Y-component: vertical extension
    );
    canvas.drawLine(
      const Offset(0, 30), // Start from hip
      leftLegEndPoint,
      limbPaint, // Use limbPaint for legs
    );
    print('Left Leg EndPoint: $leftLegEndPoint'); // Debug print

    // Right leg
    final rightLegEndPoint = Offset(
      (facingLeft ? -1 : 1) * legLength * math.sin(rightLegSwingAngle), // X-component: horizontal swing
      30 + legLength * math.cos(rightLegSwingAngle), // Y-component: vertical extension
    );
    canvas.drawLine(
      const Offset(0, 30), // Start from hip
      rightLegEndPoint,
      limbPaint, // Use limbPaint for legs
    );
    print('Right Leg EndPoint: $rightLegEndPoint'); // Debug print

    // Draw special effects based on character type
    _drawSpecialEffects(canvas, limbPaint);
  }

  void _drawSpecialEffects(Canvas canvas, Paint paint) {
    // This method can be expanded to draw character-specific effects
    // For now, it's just a placeholder.
  }
}
