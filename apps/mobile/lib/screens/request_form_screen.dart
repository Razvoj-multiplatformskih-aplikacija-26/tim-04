import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

class RequestFormScreen extends StatefulWidget {
  const RequestFormScreen({super.key, required this.animalId});

  final AnimalId animalId;

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motivationController = TextEditingController();

  @override
  void dispose() {
    _motivationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final motivation = RequestMotivation.parse(_motivationController.text).valueOrNull!;
    context.read<AdoptionRequestBloc>().add(RequestSubmitted(widget.animalId, motivation));
  }

  void _showNotice(BuildContext context, RequestsNotice notice) {
    final message = switch (notice) {
      RequestSaved() => 'Zahtev je poslat. Čeka odluku koordinatora.',
      RequestRefused(:final error) => error.message,
      RequestFailed() => 'Zahtev nije poslat. Pokušajte ponovo.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    context.read<AdoptionRequestBloc>().add(const RequestsNoticeAcknowledged());
    if (notice is RequestSaved) context.go('/requests');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final animal = context.read<AnimalsBloc>().animalById(widget.animalId);
    final name = animal?.name.text ?? 'ovu životinju';
    return BlocConsumer<AdoptionRequestBloc, AdoptionRequestState>(
      listenWhen: (previous, current) => current is RequestsLoaded && current.notice != null,
      listener: (context, state) => _showNotice(context, (state as RequestsLoaded).notice!),
      builder: (context, state) {
        final busy = state is RequestsLoaded && state.busy;
        return Scaffold(
          appBar: AppBar(title: const Text('Zahtev za udomljavanje')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text('Zašto želite da udomite: $name?', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Napišite nešto o sebi, svom domu i tome kako ćete brinuti o životinji.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _motivationController,
                  enabled: !busy,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: RequestMotivation.maxLength,
                  maxLengthEnforcement: MaxLengthEnforcement.none,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Motivacija', alignLabelWithHint: true),
                  validator: (value) => RequestMotivation.parse(value ?? '').errorOrNull?.message,
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FilledButton(
              onPressed: busy ? null : _submit,
              child: busy
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Pošalji zahtev'),
            ),
          ),
        );
      },
    );
  }
}