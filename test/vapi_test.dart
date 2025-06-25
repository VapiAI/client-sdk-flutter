import 'package:flutter_test/flutter_test.dart';
import 'package:vapi/vapi.dart';

void main() {
  group('VapiClient', () {
    test('can be instantiated with public key', () {
      expect(() => VapiClient('test-public-key'), returnsNormally);
    });

    test('platformInitialized completes', () async {
      // This should complete immediately on mobile platforms
      // and after SDK loads on web
      await expectLater(
        VapiClient.platformInitialized.future,
        completes,
      );
    });
  });
}
