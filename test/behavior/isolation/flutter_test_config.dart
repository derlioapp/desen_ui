import 'dart:async';

/// A consumer's test config: no reset of Desen's keyboard modality between
/// tests, so these tests see what an app's own test suite sees.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await testMain();
}
