import 'package:flutter/material.dart';

Future<bool> confirmApproval(
  BuildContext context, {
  required String animalName,
  required String applicant,
  required List<String> othersRejected,
}) async {
  final consequence = othersRejected.isEmpty
      ? ''
      : '\n\nAutomatski će biti odbijeni zahtevi: ${othersRejected.join(', ')}.';
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Odobriti zahtev za $animalName?'),
      content: Text('$animalName će biti rezervisan/a za: $applicant.$consequence'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Otkaži')),
        FilledButton(autofocus: true, onPressed: () => Navigator.pop(context, true), child: const Text('Odobri')),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> confirmRejection(BuildContext context, {required String applicant}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Odbiti zahtev?'),
      content: Text('Zahtev korisnika $applicant biće odbijen.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Otkaži')),
        FilledButton(autofocus: true, onPressed: () => Navigator.pop(context, true), child: const Text('Odbij')),
      ],
    ),
  );
  return result ?? false;
}

/// Asks until when the quarantine lasts; two weeks is the usual length. Null when cancelled.
Future<DateTime?> pickQuarantineEnd(BuildContext context, {required String animalName, required DateTime now}) {
  final today = DateTime(now.year, now.month, now.day);
  return showDatePicker(
    context: context,
    initialDate: today.add(const Duration(days: 14)),
    firstDate: today.add(const Duration(days: 1)),
    lastDate: today.add(const Duration(days: 90)),
    helpText: 'Karantin za $animalName traje do',
  );
}

Future<bool> confirmEndQuarantine(BuildContext context, {required String animalName}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Završiti karantin za $animalName?'),
      content: Text('$animalName će biti spreman/na za udomljavanje i moći će da prima zahteve.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Otkaži')),
        FilledButton(autofocus: true, onPressed: () => Navigator.pop(context, true), child: const Text('Završi')),
      ],
    ),
  );
  return result ?? false;
}
