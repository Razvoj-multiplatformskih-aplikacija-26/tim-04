/// `3. 8. 2026.`
String formatDate(DateTime date) => '${date.day}. ${date.month}. ${date.year}.';

String formatAge(int months) {
  final years = months ~/ 12;
  final rest = months % 12;
  if (years == 0) return '$rest mes.';
  if (rest == 0) return '$years god.';
  return '$years god. i $rest mes.';
}
