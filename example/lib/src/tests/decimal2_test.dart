import 'package:decimal2/decimal2.dart';

import '../operations.dart';
import '../packages.dart';
import 'my_benchmark_base.dart';

final class Decimal2Test extends MyBenchmarkBase {
  final List<Decimal> values;
  final List<String> _convertToStringResult;

  Decimal2Test(
    List<(BigInt, int)> list,
    Op operation,
    Object? expectedExerciseResult,
  )   : values = list
            .map(
              (e) => Decimal.fromBigInt(e.$1, shiftRight: e.$2),
            )
            .toList(growable: false),
        _convertToStringResult = List<String>.filled(list.length, ''),
        super(
          Package.decimal2,
          operation,
          expectedExerciseResult,
        );

  @override
  Object add() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result += values[i];
    }

    return result;
  }

  @override
  Object multiply() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result *= values[i];
    }

    return result;
  }

  @override
  Object divide() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result /= values[i];
    }

    return result;
  }

  @override
  Object divideAndView() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result /= values[i];
    }

    return result.toString();
  }

  @override
  List<String> rawView() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      // ignore: unnecessary_parenthesis
      final value = -(-values[i]);
      _convertToStringResult[i] = value.toString();
    }

    return _convertToStringResult;
  }

  @override
  void prepareValues() {
    for (final v in values) {
      v.optimize();
    }
  }

  @override
  List<String> preparedView() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      _convertToStringResult[i] = values[i].toString();
    }

    return _convertToStringResult;
  }
}
