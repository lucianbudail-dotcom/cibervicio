import 'dart:math';
import 'package:flutter/material.dart';
import 'brain.dart';
import 'genetics.dart';
import 'world.dart';

class BodyNode {
  double x;
  double y;
  double prevX;
  double prevY;
  BodyNode(this.x, this.y) : prevX = x, prevY = y;
}

class Body {
  List<BodyNode> nodes = [];
  double spacing;

  Body(double x, double y, int segments, this.spacing) {
    for (int i = 0; i < segments; i++) {
      nodes.add(BodyNode(x, y));
    }
  }

  void update(double headX, double headY) {
    nodes[0].x = headX;
    nodes[0].y = headY;

    for (int i = 1; i < nodes.length; i++) {
      var node = nodes[i];
      var prev = nodes[i - 1];

      double dx = node.x - prev.x;
      double dy = node.y - prev.y;
      double dist = sqrt(dx * dx + dy * dy);

      if (dist > spacing) {
        double angle = atan2(dy, dx);
        node.x = prev.x + cos(angle) * spacing;
        node.y = prev.y + sin(angle) * spacing;
      }
    }
  }
}

class CreatureStats {
  double speedMult = 1.0;
  double senseMult = 1.0;
  int armor = 0;
  bool venom = false;
  bool electric = false;
}

class Creature {
  Offset position;
  Offset velocity;
  Offset acceleration = Offset.zero;

  DNA dna;
  late Brain brain;
  late Body body;

  double energy = 100;
  bool alive = true;
  double age = 0;
  double fitness = 0;
  double stunned = 0;
  double swimTimer = 0;

  Creature(double x, double y, this.dna, [Brain? brain])
      : position = Offset(x, y),
        velocity = Offset((Random().nextDouble() - 0.5) * 2, (Random().nextDouble() - 0.5) * 2) {
    this.brain = brain ?? Brain();
    body = Body(x, y, dna.segments, dna.size * 1.5);
    swimTimer = Random().nextDouble() * pi * 2;
  }

  void update(double dt, World world) {
    if (!alive) return;
    age += dt;

    if (stunned > 0) {
      stunned -= dt;
      velocity = velocity * 0.9;
      syncBody();
      return;
    }

    swimTimer += dt * 5;

    CreatureStats stats = calculateStats();
    handleMetabolism(dt, world, stats);
    if (!alive) return;

    var nearest = sense(world, stats.senseMult);
    thinkAndMove(nearest, stats);
    physics(dt, world);
    handleInteractions(world, stats);
  }

  CreatureStats calculateStats() {
    var stats = CreatureStats();
    for (var p in dna.parts) {
      if (p.type == 'flagella') stats.speedMult += 0.3;
      if (p.type == 'cilia') stats.senseMult += 0.4;
      if (p.type == 'armor') stats.armor += 5;
      if (p.type == 'venom') stats.venom = true;
      if (p.type == 'electric') stats.electric = true;
    }
    return stats;
  }

  void handleMetabolism(double dt, World world, CreatureStats stats) {
    double seasonCost = world.currentSeason == 'Winter' ? 1.9 : 1.0;
    double drainage = (dna.metabolism + (dna.segments * 0.015) + (dna.parts.length * 0.005)) * seasonCost;
    energy -= drainage * dt;

    for (var h in world.hazards) {
      if (h.type == 'ACID') {
        double d = (Offset(h.x, h.y) - position).distance;
        if (d < h.radius) energy -= 0.5 * dt;
      }
      if (h.type == 'EMP') {
        double d = (Offset(h.x, h.y) - position).distance;
        if (d < h.radius) stunned = 20;
      }
    }

    if (energy <= 0) alive = false;
  }

  Map<String, dynamic> sense(World world, double senseMult) {
    double range = dna.senseRange * senseMult;
    return {
      'food': world.getNearestFood(position, range),
      'mate': world.getNearestMate(this, range),
      'other': world.getNearestTarget(this, range),
    };
  }

  void thinkAndMove(Map<String, dynamic> nearest, CreatureStats stats) {
    double range = dna.senseRange * stats.senseMult;
    
    Food? food = nearest['food'];
    Creature? mate = nearest['mate'];
    Creature? other = nearest['other'];

    List<double> inputs = [
      food != null ? (food.x - position.dx) / range : 0,
      food != null ? (food.y - position.dy) / range : 0,
      mate != null ? (mate.position.dx - position.dx) / range : 0,
      mate != null ? (mate.position.dy - position.dy) / range : 0,
      other != null ? (other.position.dx - position.dx) / range : 0,
      other != null ? (other.position.dy - position.dy) / range : 0,
      velocity.dx / (dna.speed * stats.speedMult),
      velocity.dy / (dna.speed * stats.speedMult)
    ];

    var outputs = brain.predict(inputs);
    double angle = (outputs[0] - 0.5) * pi * 2;
    double thrust = outputs[1] * dna.speed * stats.speedMult;

    double wiggle = sin(swimTimer) * 0.2;
    acceleration += Offset(cos(angle + wiggle) * thrust, sin(angle + wiggle) * thrust);
  }

  void physics(double dt, World world) {
    velocity += acceleration;

    double mag = velocity.distance;
    double limit = dna.speed * 2;
    if (mag > limit) {
      velocity = (velocity / mag) * limit;
    }

    position += velocity;
    acceleration = Offset.zero;

    double dx = position.dx - world.center.dx;
    double dy = position.dy - world.center.dy;
    double dist = sqrt(dx * dx + dy * dy);

    if (dist > world.radius - dna.size) {
      double angle = atan2(dy, dx);
      position = Offset(
        world.center.dx + cos(angle) * (world.radius - dna.size),
        world.center.dy + sin(angle) * (world.radius - dna.size)
      );

      double normalX = dx / dist;
      double normalY = dy / dist;
      double dot = velocity.dx * normalX + velocity.dy * normalY;
      velocity = Offset(velocity.dx - 2 * dot * normalX, velocity.dy - 2 * dot * normalY);
      velocity *= 0.8;
    }

    syncBody();
  }

  void syncBody() {
    body.update(position.dx, position.dy);
  }

  void handleInteractions(World world, CreatureStats stats) {
    Food? nearestFood = world.getNearestFood(position, dna.size * 2);
    if (nearestFood != null) {
      world.removeFood(nearestFood);
      energy = min(energy + 45, 350);
      fitness += 10;
    }

    Creature? target = world.getNearestTarget(this, dna.size * 3);
    if (target != null && target.alive) {
      double dist = (target.position - position).distance;

      if (dna.parts.any((p) => p.type == 'spike') && dist < dna.size * 2) {
        target.energy -= max(2, 12 - target.calculateStats().armor);
        fitness += 5;
      }

      if (stats.electric && dist < dna.size * 4) {
        if (Random().nextDouble() < 0.05) {
          target.stunned = 30;
          energy -= 2;
        }
      }
    }

    if (stats.venom && Random().nextDouble() < 0.1) {
      world.addHazard(position.dx, position.dy, 'ACID', 15, 60);
    }
  }
}
