import 'dart:math';
import 'package:flutter/material.dart';

const List<String> PREFIXES = ["Neo", "Bio", "Xeno", "Proto", "Aura", "Glow", "Void", "Cilia", "Morph", "Zion"];
const List<String> SUFFIXES = ["Core", "Node", "Helix", "Swarmer", "Strider", "Wraith", "Vex", "Drift", "Pod", "Cell"];

class BodyPart {
  final String type;
  final int index;
  final double angle;

  BodyPart({required this.type, required this.index, required this.angle});

  BodyPart clone() {
    return BodyPart(type: type, index: index, angle: angle);
  }
}

class DNA {
  double speed;
  double size;
  double senseRange;
  double mutationRate;
  double hue;
  Color color;
  double metabolism;
  int segments;
  List<BodyPart> parts;
  String name;

  DNA({
    required this.speed,
    required this.size,
    required this.senseRange,
    required this.mutationRate,
    required this.hue,
    required this.color,
    required this.metabolism,
    required this.segments,
    required this.parts,
    required this.name,
  });

  DNA clone() {
    return DNA(
      speed: speed,
      size: size,
      senseRange: senseRange,
      mutationRate: mutationRate,
      hue: hue,
      color: color,
      metabolism: metabolism,
      segments: segments,
      parts: parts.map((p) => p.clone()).toList(),
      name: name,
    );
  }
}

class Genetics {
  static final _random = Random();

  static DNA randomDNA() {
    final hue = _random.nextDouble() * 360;
    return DNA(
      speed: _random.nextDouble() * 1.5 + 0.6,
      size: _random.nextDouble() * 6 + 4,
      senseRange: _random.nextDouble() * 80 + 50,
      mutationRate: 0.06,
      hue: hue,
      color: HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor(),
      metabolism: _random.nextDouble() * 0.08 + 0.03,
      segments: _random.nextInt(3) + 2,
      parts: generateRandomParts(3),
      name: generateSpeciesName(hue),
    );
  }

  static List<BodyPart> generateRandomParts(int max) {
    List<BodyPart> parts = [];
    const partTypes = ['mouth', 'flagella', 'spike', 'cilia', 'electric', 'venom', 'armor'];
    int numParts = _random.nextInt(max) + 1;

    for (int i = 0; i < numParts; i++) {
      parts.push(BodyPart(
        type: partTypes[_random.nextInt(partTypes.length)],
        index: _random.nextInt(3),
        angle: _random.nextDouble() * pi * 2,
      ));
    }
    return parts;
  }

  static String generateSpeciesName(double hue) {
    int pIdx = ((hue / 360) * PREFIXES.length).floor().clamp(0, PREFIXES.length - 1);
    int sIdx = _random.nextInt(SUFFIXES.length);
    return "\${PREFIXES[pIdx]}-\${SUFFIXES[sIdx]}";
  }

  static DNA crossover(DNA dnaA, DNA dnaB) {
    final hue = _random.nextDouble() > 0.5 ? dnaA.hue : dnaB.hue;
    return DNA(
      speed: _random.nextDouble() > 0.5 ? dnaA.speed : dnaB.speed,
      size: _random.nextDouble() > 0.5 ? dnaA.size : dnaB.size,
      senseRange: _random.nextDouble() > 0.5 ? dnaA.senseRange : dnaB.senseRange,
      mutationRate: _random.nextDouble() > 0.5 ? dnaA.mutationRate : dnaB.mutationRate,
      hue: hue,
      color: HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor(),
      metabolism: _random.nextDouble() > 0.5 ? dnaA.metabolism : dnaB.metabolism,
      segments: _random.nextDouble() > 0.5 ? dnaA.segments : dnaB.segments,
      parts: _random.nextDouble() > 0.5 
          ? dnaA.parts.map((p) => p.clone()).toList() 
          : dnaB.parts.map((p) => p.clone()).toList(),
      name: dnaA.name,
    );
  }

  static void mutate(DNA dna) {
    if (_random.nextDouble() < dna.mutationRate) {
      dna.speed += (_random.nextDouble() * 0.2 - 0.1);
      dna.size += (_random.nextDouble() * 1.2 - 0.6);
      dna.hue = (dna.hue + (_random.nextDouble() * 30 - 15) + 360) % 360;
      dna.color = HSLColor.fromAHSL(1.0, dna.hue, 0.6, 0.5).toColor();

      if (_random.nextDouble() < 0.15) {
        if (dna.parts.length < 6) {
          dna.parts.add(generateRandomParts(1)[0]);
        }
      }

      if (_random.nextDouble() < 0.06) {
        dna.segments = (dna.segments + 1).clamp(2, 10);
      }
      if (_random.nextDouble() < 0.03) {
        dna.name = generateSpeciesName(dna.hue);
      }
    }
  }
}

extension ListExtensions<T> on List<T> {
  void push(T element) {
    this.add(element);
  }
}
