import 'dart:math';

class Brain {
  final int inputSize;
  final int hiddenSize;
  final int outputSize;
  late List<double> weights1;
  late List<double> weights2;

  Brain({
    this.inputSize = 8,
    this.hiddenSize = 12,
    this.outputSize = 2,
    List<double>? w1,
    List<double>? w2,
  }) {
    final random = Random();
    if (w1 != null && w2 != null) {
      weights1 = List.from(w1);
      weights2 = List.from(w2);
    } else {
      weights1 = List.generate(hiddenSize * inputSize, (_) => random.nextDouble() * 2 - 1);
      weights2 = List.generate(outputSize * hiddenSize, (_) => random.nextDouble() * 2 - 1);
    }
  }

  List<double> predict(List<double> inputs) {
    // Input to Hidden
    List<double> hidden = List.filled(hiddenSize, 0.0);
    for (int j = 0; j < hiddenSize; j++) {
      for (int i = 0; i < inputSize; i++) {
        hidden[j] += inputs[i] * weights1[j * inputSize + i];
      }
      hidden[j] = tanh(hidden[j]);
    }

    // Hidden to Output
    List<double> outputs = List.filled(outputSize, 0.0);
    for (int j = 0; j < outputSize; j++) {
      for (int i = 0; i < hiddenSize; i++) {
        outputs[j] += hidden[i] * weights2[j * hiddenSize + i];
      }
      outputs[j] = 1 / (1 + exp(-outputs[j]));
    }
    return outputs;
  }

  Brain clone() {
    return Brain(
      inputSize: inputSize,
      hiddenSize: hiddenSize,
      outputSize: outputSize,
      w1: List.from(weights1),
      w2: List.from(weights2),
    );
  }

  void mutate(double rate) {
    final random = Random();
    weights1 = weights1.map((w) {
      return random.nextDouble() < rate ? w + (random.nextDouble() * 0.4 - 0.2) : w;
    }).toList();
    weights2 = weights2.map((w) {
      return random.nextDouble() < rate ? w + (random.nextDouble() * 0.4 - 0.2) : w;
    }).toList();
  }

  double tanh(double x) {
    double e2x = exp(2 * x);
    return (e2x - 1) / (e2x + 1);
  }
}
