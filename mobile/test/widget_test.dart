import 'package:flutter_test/flutter_test.dart';
import 'package:roshab_tasks_mobile/main.dart';

void main() {
  testWidgets('Roshab Tasks renders the task app', (tester) async {
    await tester.pumpWidget(const RoshabTasksApp());
    expect(find.text('Roshab Tasks'), findsOneWidget);
  });
}
