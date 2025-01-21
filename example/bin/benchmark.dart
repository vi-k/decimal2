import 'package:example/benchmark.dart';

void printUsage() {
  print('Usage: dart benchmark.dart [-]id [-]id ...');

  print('\nWhere id:\n');

  print('all - all packages and all tests');
  print('all-packages - all packages');
  print('all-tests - all tests');

  print('\nPackages:');
  final groups = <String, List<Package>>{};
  for (final package in Package.values) {
    final group = package.group;
    if (group == null) {
      groups[package.id] = [];
    } else {
      final list = groups[group];
      if (list == null) {
        groups[group] = [package];
      } else {
        list.add(package);
      }
    }
  }

  for (final entry in groups.entries) {
    if (entry.value.isEmpty) {
      print(entry.key);
    } else {
      print('${entry.key} (${entry.value.map((e) => e.id).join(', ')})');
    }
  }

  print('\nTests:');
  for (final op in Op.values) {
    final tests = Test.byOperation(op.id);
    print('${op.id} (${tests.map((e) => e.id).join(', ')})');
  }

  print('\nExamples:');
  print('\nAll packages and all tests:');
  print('> dart benchmark.dart all');
  print('\nTest "divide" for all packages');
  print('> dart benchmark.dart all-packages divide');
  print('\nAll tests for all packages excluding "decimal2"');
  print('> dart benchmark.dart all -decimal2');
}

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.isNotEmpty && arguments[0] == '--help') {
    printUsage();
    return;
  }

  final packages = <Package>{};
  final tests = <Test>{};

  for (final arg in arguments) {
    switch (arg) {
      case 'all':
        packages.addAll(Package.values);
        tests.addAll(Test.values);

      case 'all-packages':
        packages.addAll(Package.values);

      case 'all-tests':
        tests.addAll(Test.values);

      default:
        final exclude = arg.startsWith('-');
        final id = exclude ? arg.substring(1) : arg;

        final package = Package.byId(id);
        if (package != null) {
          exclude ? packages.remove(package) : packages.add(package);
          continue;
        }

        final packagesByGroup = Package.byGroup(id);
        if (packagesByGroup.isNotEmpty) {
          exclude
              ? packages.removeAll(packagesByGroup)
              : packages.addAll(packagesByGroup);
          continue;
        }

        final test = Test.byId(id);
        if (test != null) {
          exclude ? tests.remove(test) : tests.add(test);
          continue;
        }

        final testByOperations = Test.byOperation(id);
        if (testByOperations.isNotEmpty) {
          exclude
              ? tests.removeAll(testByOperations)
              : tests.addAll(testByOperations);
          continue;
        }

        print('Unknown argument: $arg\n');
        printUsage();
        return;
    }
  }

  run(
    packages: packages,
    tests: tests,
  );
}
