import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import '../../format.dart';

typedef IntakeData = ({String name, Species species, DateTime birthDate, String description, EnclosureId enclosureId});

Future<IntakeData?> showIntakeDialog(
  BuildContext context, {
  required List<EnclosureId> enclosures,
  required DateTime now,
}) {
  return showDialog<IntakeData>(
    context: context,
    builder: (context) => IntakeDialog(enclosures: enclosures, now: now),
  );
}

class IntakeDialog extends StatefulWidget {
  const IntakeDialog({super.key, required this.enclosures, required this.now});

  final List<EnclosureId> enclosures;
  final DateTime now;

  @override
  State<IntakeDialog> createState() => _IntakeDialogState();
}

class _IntakeDialogState extends State<IntakeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  Species _species = Species.dog;
  late EnclosureId? _enclosure = widget.enclosures.firstOrNull;
  late DateTime _birthDate = DateTime(widget.now.year - 1, widget.now.month, widget.now.day);

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(widget.now.year - 40),
      lastDate: widget.now,
      helpText: 'Datum rođenja',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  void _submit() {
    // validate() runs every validator below and shows its message under the field; false means something is wrong.
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop<IntakeData>(context, (
      name: _name.text,
      species: _species,
      birthDate: _birthDate,
      description: _description.text.trim(),
      enclosureId: _enclosure!,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Prijem nove životinje'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Ime'),
                  // P1: the same rule the domain checks, so the message appears before saving.
                  validator: (value) => AnimalName.parse(value ?? '').errorOrNull?.message,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Species>(
                  initialValue: _species,
                  decoration: const InputDecoration(labelText: 'Vrsta'),
                  items: [
                    for (final species in Species.values) DropdownMenuItem(value: species, child: Text(species.label)),
                  ],
                  onChanged: (value) => setState(() => _species = value ?? _species),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EnclosureId>(
                  initialValue: _enclosure,
                  decoration: const InputDecoration(labelText: 'Prostor'),
                  items: [
                    for (final enclosure in widget.enclosures)
                      DropdownMenuItem(value: enclosure, child: Text(enclosure.value)),
                  ],
                  onChanged: (value) => setState(() => _enclosure = value),
                  validator: (value) => value == null ? 'Izaberite prostor.' : null,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickBirthDate,
                  icon: const Icon(Icons.cake_outlined),
                  label: Text('Rođena: ${formatDate(_birthDate)}'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Opis', alignLabelWithHint: true),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Otkaži')),
        FilledButton(onPressed: _submit, child: const Text('Primi')),
      ],
    );
  }
}
