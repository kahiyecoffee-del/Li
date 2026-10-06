import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Prediction of a [TextClassifier].
class Prediction {
  const Prediction(this.label, this.probability);

  final String label;
  final double probability;
}

/// Small on-device text classifier (multinomial logistic regression over
/// hashed word + character n-grams, int8 weights). Trained by
/// `tool/ml/train_classifiers.py`; the featurizer here must stay
/// bit-for-bit identical to `tool/ml/featurize.py` (checked by
/// `test/unit/text_classifier_test.dart`).
///
/// Strength: robust to typos, missing Turkish letters, amounts and
/// suffixes. Weakness: it cannot know words it has never seen, so callers
/// only trust predictions at or above [threshold].
class TextClassifier {
  TextClassifier._(this.name, this.classes, this.dims, this.threshold, this._bias, this._weights, this._scale);

  factory TextClassifier.fromJson(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    if (j['format'] != 'lifeos-textclf-v1') throw const FormatException('Unsupported model format');
    final classes = (j['classes'] as List<dynamic>).cast<String>();
    final dims = j['dims'] as int;
    final weights = Int8List.view(base64Decode(j['weights_int8_b64'] as String).buffer);
    if (weights.length != dims * classes.length) throw const FormatException('Weight shape mismatch');
    return TextClassifier._(
      j['name'] as String,
      classes,
      dims,
      (j['threshold'] as num?)?.toDouble() ?? 0.7,
      (j['bias'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      weights,
      (j['scale'] as num).toDouble(),
    );
  }

  final String name;
  final List<String> classes;
  final int dims;

  /// Minimum probability for a prediction to be used.
  final double threshold;
  final List<double> _bias;
  final Int8List _weights;
  final double _scale;

  static final _digits = RegExp(r'\p{Nd}+', unicode: true);
  static final _strip = RegExp(r'[^\p{L}\p{N}\s&]+', unicode: true);
  static final _space = RegExp(r'\s+', unicode: true);

  /// Same normalization as featurize.normalize.
  static String normalize(String text) {
    // All i-variants fold to "i" so Turkish (KIRA/kıra) and English (NETFLIX) both work.
    var t = text.replaceAll('I', 'i').replaceAll('İ', 'i').replaceAll('ı', 'i').toLowerCase();
    t = t.replaceAll(_digits, ' ');
    t = t.replaceAll('_', ' ').replaceAll(_strip, ' ');
    return t.replaceAll(_space, ' ').trim();
  }

  static int fnv1a(String s) {
    var h = 0x811C9DC5;
    for (final b in utf8.encode(s)) {
      h ^= b;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }

  static List<String> tokens(String text) {
    final out = <String>[];
    for (final w in normalize(text).split(' ')) {
      if (w.isEmpty) continue;
      out.add('w:$w');
      final chars = ' $w '.runes.toList();
      for (final n in const [3, 4]) {
        for (var i = 0; i + n <= chars.length; i++) {
          out.add('c:${String.fromCharCodes(chars, i, i + n)}');
        }
      }
    }
    return out;
  }

  /// L2-normalized hashed bag of tokens (insertion order matches Python).
  Map<int, double> features(String text) {
    final counts = <int, int>{};
    for (final t in tokens(text)) {
      final k = fnv1a(t) % dims;
      counts[k] = (counts[k] ?? 0) + 1;
    }
    if (counts.isEmpty) return const {};
    final norm = math.sqrt(counts.values.fold<int>(0, (s, v) => s + v * v));
    return counts.map((k, v) => MapEntry(k, v / norm));
  }

  /// Most likely label with its probability; null for empty input.
  Prediction? predict(String text) {
    final x = features(text);
    if (x.isEmpty) return null;
    final k = classes.length;
    final logits = List<double>.of(_bias);
    x.forEach((j, v) {
      final base = j * k;
      for (var c = 0; c < k; c++) {
        logits[c] += _weights[base + c] * _scale * v;
      }
    });
    final m = logits.reduce(math.max);
    final exps = logits.map((z) => math.exp(z - m)).toList();
    final s = exps.fold<double>(0, (a, b) => a + b);
    var best = 0;
    for (var c = 1; c < k; c++) {
      if (exps[c] > exps[best]) best = c;
    }
    return Prediction(classes[best], exps[best] / s);
  }

  /// Prediction only if confident enough to act on without asking.
  Prediction? confident(String text) {
    final p = predict(text);
    return p != null && p.probability >= threshold ? p : null;
  }
}
