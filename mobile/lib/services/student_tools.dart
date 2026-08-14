class StudentTools {
  static double gpa(List<double> grades, List<double> credits) {
    if (grades.isEmpty || grades.length != credits.length) return 0;
    final totalCredits = credits.fold<double>(0, (a, b) => a + b);
    if (totalCredits == 0) return 0;
    final points = List.generate(grades.length, (i) => grades[i] * credits[i]).fold<double>(0, (a, b) => a + b);
    return points / totalCredits;
  }

  static double attendance(int attended, int total) {
    if (total <= 0) return 0;
    return attended.clamp(0, total) / total * 100;
  }

  static int classesNeededForTarget({required int attended, required int total, required double target}) {
    if (total <= 0 || target <= 0 || target > 100) return 0;
    var extra = 0;
    while ((attended + extra) / (total + extra) * 100 < target && extra < 10000) {
      extra++;
    }
    return extra;
  }

  static Duration countdown(DateTime target) {
    final diff = target.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}
