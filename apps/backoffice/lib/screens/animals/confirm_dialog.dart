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
