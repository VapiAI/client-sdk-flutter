import 'package:flutter_test/flutter_test.dart';

import 'package:vapi/Vapi.dart';

void main() {
  group('startCall', () {
    
    test('successfully starts a call with a valid URL', () async {
      // Setup
      var vapi = Vapi(/* configuration or necessary arguments */);
      var roomUrl = 'validRoomUrl'; // Replace with a valid room URL for testing

      // Act & Assert
      expect(() async => await vapi.startCall(roomUrl), returnsNormally);
    });

    test('throws an exception with an invalid URL', () {
      // Setup
      var vapi = Vapi(/* configuration or necessary arguments */);
      var roomUrl = 'invalidRoomUrl'; // An intentionally invalid room URL

      // Act & Assert
      expect(() async => await vapi.startCall(roomUrl), throwsException);
    });

    // Additional tests for other edge cases and exception handling
  });
  }




/*
void main() {
  test('adds one to input values', () {
    final calculator = DidCompile();
    expect(calculator.addOne(2), 3);
    expect(calculator.addOne(-7), -6);
    expect(calculator.addOne(0), 1);
  });
}
*/
