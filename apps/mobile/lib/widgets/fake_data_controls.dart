import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/fake_shelter_repository.dart';

class FakeDataControls extends StatelessWidget {
  const FakeDataControls({super.key});

  void _simulate(BuildContext context, String message, void Function() prepare) {
    prepare();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    context.read<AnimalsBloc>().add(const AnimalsRetried());
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ShelterRepository>();
    if (repository is! FakeShelterRepository) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Simuliraj prazan odgovor',
          icon: const Icon(Icons.inbox_outlined),
          onPressed: () => _simulate(context, 'Sledeći odgovor biće prazan.', repository.emptyNextRequest),
        ),
        IconButton(
          tooltip: 'Simuliraj grešku',
          icon: const Icon(Icons.cloud_off_outlined),
          onPressed: () => _simulate(context, 'Sledeći zahtev neće uspeti.', repository.failNextRequest),
        ),
      ],
    );
  }
}
