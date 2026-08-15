import 'package:flutter_test/flutter_test.dart';
import 'package:roshup/services/student_tools.dart';

void main() {
  test('calculates weighted GPA', () {
    expect(StudentTools.gpa([4, 3], [3, 3]), closeTo(3.5, 0.001));
  });

  test('calculates attendance percentage', () {
    expect(StudentTools.attendance(18, 20), closeTo(90, 0.001));
  });

  test('finds classes needed for target attendance', () {
    expect(StudentTools.classesNeededForTarget(attended: 15, total: 20, target: 80), 5);
  });
}
