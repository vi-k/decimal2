import 'dart:math';

import 'package:ansi_escape_codes/ansi_escape_codes.dart';
import 'package:decimal2/decimal2.dart';
import 'package:example/src/tests/big_decimal_test.dart';
import 'package:format/format.dart';

import 'environment.dart';
import 'operations.dart';
import 'packages.dart';
import 'tests.dart';
import 'tests/decimal2_short_test.dart';
import 'tests/decimal2_test.dart';
import 'tests/decimal_test.dart';
import 'tests/decimal_type_test.dart';
import 'tests/fixed_test.dart';
import 'tests/my_benchmark_base.dart';

typedef Summary = Map<(Package, Test), MyBenchmarkBase>;

typedef CreateBigIntTestCallback = MyBenchmarkBase Function(
  List<(BigInt, int)> values,
  Op operation,
  Object result,
);

typedef CreateIntTestCallback = MyBenchmarkBase Function(
  List<(int, int)> values,
  Op operation,
  Object result,
);

void run({
  required Set<Package> packages,
  required Set<Test> tests,
}) {
  _printPackages(packages);
  _printTests(tests);

  // ignore: omit_local_variable_types
  final Summary summary = {};

  for (final test in tests) {
    _printTitle(test);

    final (bigIntValues: bigIntValues, intValues: intValues, result: result) =
        test.data();

    _printValues(bigIntValues, test.operation.sign, result);

    _measureBigIntTestsAndPrint(
      summary,
      packages,
      bigIntValues,
      test,
      result,
    );

    if (intValues != null) {
      _measureIntTestsAndPrint(
        summary,
        packages,
        intValues,
        test,
        result,
      );
    }
  }

  _printSummary(packages, tests, summary);
}

final _bigIntPackages = <Package, CreateBigIntTestCallback>{
  Package.decimal: DecimalTest.new,
  Package.fixed: FixedTest.new,
  Package.decimalType: DecimalTypeTest.new,
  Package.bigDecimal: BigDecimalTest.new,
  Package.decimal2: Decimal2Test.new,
};

final _intPackages = <Package, CreateIntTestCallback>{
  Package.decimal2Short: Decimal2ShortTest.new,
};

void _printPackages(Set<Package> packages) {
  print('${def}Packages:$reset');
  for (final package in packages) {
    print('$accent${package.id}$reset');
  }
}

void _printTests(Set<Test> tests) {
  print('\n${def}Tests:$reset');
  for (final test in tests) {
    print('$accent${test.id}$reset');
  }
}

void _measureBigIntTestsAndPrint(
  Summary results,
  Set<Package> packages,
  List<(BigInt, int)> values,
  Test test,
  Object result,
) {
  for (final MapEntry(key: package, value: create) in _bigIntPackages.entries) {
    if (packages.contains(package)) {
      final benchmark = create(values, test.operation, result);
      results[(package, test)] = benchmark;
      _measureTest(benchmark);
    }
  }
}

void _measureIntTestsAndPrint(
  Summary results,
  Set<Package> packages,
  List<(int, int)> values,
  Test test,
  Object result,
) {
  for (final MapEntry(key: package, value: create) in _intPackages.entries) {
    if (packages.contains(package)) {
      final benchmark = create(values, test.operation, result);
      results[(package, test)] = benchmark;
      _measureTest(benchmark);
    }
  }
}

void _measureTest(MyBenchmarkBase benchmark) {
  try {
    final score = benchmark.measure() / benchmark.operation.numberOfCycles;
    benchmark.score = score;

    final msg = benchmark.resultMessage;
    final package = benchmark.package;

    print(
      '$accent${package.id} $def(${package.type}):'
      ' $accent${format('{:.3f}', score)} µs$reset'
      '${msg == null ? '' : ' $msg'}',
    );
    // ignore: unused_catch_stack
  } on Object catch (e, s) {
    benchmark.error = e.toString();
    print(
      '$accent${benchmark.name} ${accentError}ERROR $error$e$reset',
    );
    // print(s);
  }
}

void _printValues(
  List<(BigInt, int)> values,
  String? op,
  Object result,
) {
  final decimals =
      values.map((e) => Decimal.fromBigInt(e.$1, shiftRight: e.$2));
  if (op != null) {
    print('$def${decimals.join(' $op ')} = $result$reset\n');
  } else {
    for (final d in decimals) {
      print('$def$d$reset');
    }
    print('');
  }
}

void _printTitle(Test test) {
  final title = '${def}Test: $accent${test.id}$def'
      ', tags: $accent${test.tags.join('$def, $accent')}'
      '$reset';

  final titleLen = removeEscapeSequences(title).length;
  final description = test.description.split('\n');
  const descriptionTitle = 'Description: ';
  final descriptionLen = description.fold(0, (l, s) => max(l, s.length));

  final len = max(titleLen, descriptionTitle.length + descriptionLen);

  print('');
  print('$def${'─' * len}$reset');
  print(title);
  print('$def$descriptionTitle$accent${description[0]}$reset');
  for (final d in description.skip(1)) {
    print('$def${' ' * descriptionTitle.length}$accent$d$reset');
  }
  print('');
}

String _sup(int number) => number
    .toString()
    .replaceAll('0', '⁰')
    .replaceAll('1', '¹')
    .replaceAll('2', '²')
    .replaceAll('3', '³')
    .replaceAll('4', '⁴')
    .replaceAll('5', '⁵')
    .replaceAll('6', '⁶')
    .replaceAll('7', '⁷')
    .replaceAll('8', '⁸')
    .replaceAll('9', '⁹');

// String _sub(int number) => number
//     .toString()
//     .replaceAll('0', '₀')
//     .replaceAll('1', '₁')
//     .replaceAll('2', '₂')
//     .replaceAll('3', '₃')
//     .replaceAll('4', '₄')
//     .replaceAll('5', '₅')
//     .replaceAll('6', '₆')
//     .replaceAll('7', '₇')
//     .replaceAll('8', '₈')
//     .replaceAll('9', '₉');

// Summary.
void _printSummary(
  Set<Package> packages,
  Set<Test> tests,
  Summary summary,
) {
  final table = <List<String>>[];
  final widths = List<int>.filled(packages.length + 1, 0);
  final footnotes = <String>[];

  String footnote(String text) {
    final index = footnotes.indexOf(text);
    if (index != -1) {
      return '$warning${_sup(index + 1)}$def';
    }

    footnotes.add(text);
    return '$warning${_sup(footnotes.length)}$def';
  }

  // Заголовок.
  final firstRow = List<String>.filled(packages.length + 1, '');
  firstRow[0] = '';
  widths[0] = max(widths[0], removeEscapeSequences(firstRow[0]).length);

  for (final (index, package) in packages.indexed) {
    var title = '$accent${package.id}$def';
    if (package.excludeFromWinners) {
      title = '$title${footnote('Excluded from winners')}';
    }
    firstRow[index + 1] = title;
    widths[index + 1] =
        max(widths[index + 1], removeEscapeSequences(title).length);
  }
  table.add(firstRow);

  for (final test in tests) {
    final row = List<String>.filled(packages.length + 1, '');
    final title = '$accent${test.id}$def';
    row[0] = title;
    widths[0] = max(widths[0], removeEscapeSequences(title).length);
    table.add(row);
    double? minScore;

    for (final package in packages) {
      final benchmark = summary[(package, test)];
      if (benchmark != null) {
        if (!package.excludeFromWinners && !benchmark.hasError) {
          final score = benchmark.score;
          if (score != null && (minScore == null || score < minScore)) {
            minScore = score;
          }
        }
      }
    }

    for (final (index, package) in packages.indexed) {
      final benchmark = summary[(package, test)];
      String text;

      if (benchmark == null) {
        text = '— ${footnote('Not supported')}';
      } else {
        final err = benchmark.error;
        if (err != null) {
          text = '${error}ERROR$def${footnote('$error$err$def')}';
        } else {
          final score = benchmark.score!;

          final isWinner = !package.excludeFromWinners &&
              minScore != null &&
              (score - minScore).abs() <= minScore * 0.1;

          text = '${isWinner ? '$ok★ ' : ''}'
              '${format('{:.3f} µs', score)}'
              '${isWinner ? def : ''}';
        }
      }

      row[index + 1] = text;
      widths[index + 1] =
          max(widths[index + 1], removeEscapeSequences(text).length);
    }
  }

  print('\n${def}Summary:\n');

  for (final (index, row) in table.indexed) {
    final buf = StringBuffer(def);
    for (final (col, text) in row.indexed) {
      final colWidth = widths[col];
      final textWidth = removeEscapeSequences(text).length;

      if (col == 0) {
        buf
          ..write('| ')
          ..write(text)
          ..write(' ' * (colWidth - textWidth))
          ..write(' |');
      } else {
        buf
          ..write(' ')
          ..write(' ' * (colWidth - textWidth))
          ..write(text)
          ..write(' |');
      }
    }
    buf.write(reset);
    print(buf);

    if (index == 0) {
      final buf = StringBuffer(def);
      for (final (col, _) in row.indexed) {
        final colWidth = widths[col];

        if (col == 0) {
          buf
            ..write('|:')
            ..write('-' * (colWidth + 1))
            ..write('|');
        } else {
          buf
            ..write('-' * (colWidth + 1))
            ..write(':|');
        }
      }
      buf.write(reset);
      print(buf);
    }
  }

  if (footnotes.isNotEmpty) {
    print('');

    for (var (index, footnote) in footnotes.indexed) {
      final escapeSequences = allEscapeSequences(footnote);
      if (escapeSequences.isEmpty) {
        if (!footnote.endsWith('.')) {
          footnote += '.';
        }
      } else {
        var lastSeq = escapeSequences.last;
        if (lastSeq.end != footnote.length) {
          if (!footnote.endsWith('.')) {
            footnote += '.';
          }
        } else {
          var index = escapeSequences.length - 1;
          while (index > 0 && escapeSequences[index - 1].end == lastSeq.start) {
            lastSeq = escapeSequences[index - 1];
            index--;
          }

          if (lastSeq.start > 0 && footnote[lastSeq.start - 1] != '.') {
            footnote = '${footnote.substring(0, lastSeq.start)}.'
                '${footnote.substring(lastSeq.start)}';
          }
        }
      }

      footnote = handlePlainText(footnote, showControlCodes);

      print('$warning${_sup(index + 1)} $accent$footnote$reset');
    }
  }
}
