import 'dart:math';
import 'package:flutter/material.dart';
import 'creature.dart';
import 'genetics.dart';
import 'brain.dart';

class Food {
  double x;
  double y;
  double id;
  Food(this.x, this.y, this.id);
}

class Hazard {
  double x;
  double y;
  String type;
  double radius;
  double duration;
  Hazard(this.x, this.y, this.type, this.radius, this.duration);
}

class World {
  double width;
  double height;
  late Offset center;
  late double radius;

  List<Creature> creatures = [];
  List<Food> food = [];
  List<Hazard> hazards = [];

  double reproEnergy = 135;
  int seasonIndex = 0;
  double seasonTimer = 0;
  double seasonDuration = 5000;

  Function(String)? onLog;
  String incidentMsg = "";
  final Random _random = Random();

  static const List<String> SEASONS = ['Spring', 'Summer', 'Autumn', 'Winter'];

  World(this.width, this.height) {
    center = Offset(width / 2, height / 2);
    radius = min(width, height) * 0.44;
  }

  void resize(double w, double h) {
    width = w;
    height = h;
    center = Offset(w / 2, h / 2);
    radius = min(w, h) * 0.44;
  }

  String get currentSeason => SEASONS[seasonIndex];

  void log(String msg) {
    if (onLog != null) onLog!(msg);
  }

  void spawnInitial(int count) {
    for (int i = 0; i < count; i++) {
      double angle = _random.nextDouble() * pi * 2;
      double r = _random.nextDouble() * radius * 0.8;
      creatures.add(Creature(
        center.dx + cos(angle) * r,
        center.dy + sin(angle) * r,
        Genetics.randomDNA(),
      ));
    }
  }

  void spawnFood(int count) {
    for (int i = 0; i < count; i++) {
      double angle = _random.nextDouble() * pi * 2;
      double r = _random.nextDouble() * radius;
      food.add(Food(
        center.dx + cos(angle) * r,
        center.dy + sin(angle) * r,
        _random.nextDouble(),
      ));
    }
  }

  void addHazard(double x, double y, String type, double r, double dur) {
    hazards.add(Hazard(x, y, type, r, dur));
  }

  void removeFood(Food f) {
    food.remove(f);
  }

  Food? getNearestFood(Offset pos, double range) {
    Food? nearest;
    double minDist = range;
    for (var f in food) {
      double d = (Offset(f.x, f.y) - pos).distance;
      if (d < minDist) {
        minDist = d;
        nearest = f;
      }
    }
    return nearest;
  }

  Creature? getNearestMate(Creature creature, double range) {
    Creature? nearest;
    double minDist = range;
    for (var other in creatures) {
      if (other == creature || !other.alive || other.energy < 80) continue;
      double dist = (other.position - creature.position).distance;
      if (dist < minDist && other.dna.name == creature.dna.name) {
        minDist = dist;
        nearest = other;
      }
    }
    return nearest;
  }

  Creature? getNearestTarget(Creature creature, double range) {
    Creature? nearest;
    double minDist = range;
    for (var other in creatures) {
      if (other == creature || !other.alive) continue;
      double dist = (other.position - creature.position).distance;
      if (dist < minDist) {
        minDist = dist;
        nearest = other;
      }
    }
    return nearest;
  }

  void update(double dt) {
    updateSeason(dt);

    for (int i = hazards.length - 1; i >= 0; i--) {
      hazards[i].duration -= dt;
      if (hazards[i].duration <= 0) hazards.removeAt(i);
    }

    for (int i = creatures.length - 1; i >= 0; i--) {
      var c = creatures[i];
      c.update(dt, this);

      if (!c.alive) {
        creatures.removeAt(i);
        continue;
      }

      if (c.energy > reproEnergy) {
        reproduce(c);
      }
    }

    int foodLimit = getFoodLimit();
    if (food.length < foodLimit && _random.nextDouble() < getFoodSpawnChance()) {
      spawnFood(1);
    }

    if (creatures.length < 5) {
      spawnInitial(2);
    }
  }

  void updateSeason(double dt) {
    seasonTimer += dt;
    if (seasonTimer > seasonDuration) {
      seasonTimer = 0;
      seasonIndex = (seasonIndex + 1) % SEASONS.length;
      log("Ciclo Estacional: \$currentSeason");

      if (_random.nextDouble() < 0.7) triggerIncident();
    }
  }

  void triggerIncident() {
    int roll = _random.nextInt(4);
    switch (roll) {
      case 0:
        incidentMsg = "PULSO ELÉCTRICO";
        addHazard(center.dx, center.dy, 'EMP', radius * 0.8, 100);
        break;
      case 1:
        incidentMsg = "DERRAME ÁCIDO";
        double angle = _random.nextDouble() * pi * 2;
        double r = _random.nextDouble() * radius;
        addHazard(center.dx + cos(angle) * r, center.dy + sin(angle) * r, 'ACID', 80, 400);
        break;
      case 2:
        incidentMsg = "SUPERABUNDANCIA";
        spawnFood(30);
        break;
      case 3:
        incidentMsg = "OXI-SHOCK";
        for (var c in creatures) {
          c.energy += 20;
        }
        break;
    }
    log("INCIDENTE: \$incidentMsg");
    Future.delayed(const Duration(seconds: 3), () {
      incidentMsg = "";
    });
  }

  int getFoodLimit() {
    switch (currentSeason) {
      case 'Spring': return 160;
      case 'Summer': return 130;
      case 'Autumn': return 60;
      case 'Winter': return 15;
      default: return 100;
    }
  }

  double getFoodSpawnChance() {
    switch (currentSeason) {
      case 'Spring': return 0.5;
      case 'Summer': return 0.3;
      case 'Autumn': return 0.15;
      case 'Winter': return 0.05;
      default: return 0.2;
    }
  }

  void reproduce(Creature parent) {
    Creature? partner = getNearestMate(parent, 50);
    if (partner != null) {
      parent.energy -= 75;
      partner.energy -= 75;
      DNA childDNA = Genetics.crossover(parent.dna, partner.dna);
      Genetics.mutate(childDNA);
      var child = Creature(parent.position.dx, parent.position.dy, childDNA, parent.brain.clone());
      child.brain.mutate(childDNA.mutationRate);
      creatures.add(child);
    } else if (parent.energy > 230) {
      parent.energy -= 130;
      DNA childDNA = parent.dna.clone();
      Genetics.mutate(childDNA);
      var child = Creature(parent.position.dx, parent.position.dy, childDNA, parent.brain.clone());
      child.brain.mutate(childDNA.mutationRate);
      creatures.add(child);
    }
  }
}
