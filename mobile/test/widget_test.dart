import 'package:flutter_test/flutter_test.dart';
import 'package:roshup/main.dart';

void main() {
  testWidgets('RoshUP renders the mobile app', (tester) async {
    await tester.pumpWidget(const RoshUPApp());
    expect(find.text('RoshUP'), findsAtLeastNWidgets(1));
  });
}
