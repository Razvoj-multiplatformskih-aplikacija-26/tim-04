import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../../dependencies.dart';
import '../../shortcuts.dart';
import 'animal_details.dart';
import 'animals_filter_bar.dart';
import 'animals_list.dart';
import 'animals_table.dart';
import 'confirm_dialog.dart';

class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({super.key, this.selectedId});

  static const path = '/animals';

  static const wideBreakpoint = 840.0;

  static String pathFor(AnimalId? selected) => selected == null ? path : '$path?selected=${selected.value}';

  final AnimalId? selectedId;

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  late final AnimalsBloc _bloc = context.read<AnimalsBloc>();
  late final BackofficeDependencies _dependencies = context.read<BackofficeDependencies>();

  @override
  void initState() {
    super.initState();
    _bloc.add(AnimalSelected(widget.selectedId));
  }

  @override
  void didUpdateWidget(AnimalsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) _bloc.add(AnimalSelected(widget.selectedId));
  }

  void _select(AnimalId? id) => context.go(AnimalsScreen.pathFor(id));

  void _toggle(AnimalId id) => _select(id == widget.selectedId ? null : id);

  Map<Type, Action<Intent>> _actions() => {
    MoveSelectionIntent: CallbackAction<MoveSelectionIntent>(onInvoke: (intent) => _move(intent.offset)),
    ClearSelectionIntent: GuardedCallbackAction<ClearSelectionIntent>(
      enabled: () => widget.selectedId != null,
      onInvoke: (_) => _select(null),
    ),
    ApproveIntent: GuardedCallbackAction<ApproveIntent>(
      enabled: () => _oldestPending() != null,
      onInvoke: (_) => _approveOldest(),
    ),
    ShowShortcutsIntent: CallbackAction<ShowShortcutsIntent>(onInvoke: (_) => _showShortcuts()),
  };
  void _move(int offset) {
    final state = _bloc.state;
    if (state is! AnimalsLoaded) return;
    final animals = state.animals;
    final current = animals.indexWhere((a) => a.id == widget.selectedId);
    final next = (current + offset).clamp(0, animals.length - 1);
    _select(animals[next].id);
  }

  Animal? get _selectedAnimal => switch (_bloc.state) {
    AnimalsLoaded(:final selected) => selected,
    _ => null,
  };

  AdoptionRequest? _oldestPending() {
    final animal = _selectedAnimal;
    final requests = context.read<AdoptionRequestBloc>().state;
    if (animal == null || !animal.isAdoptable || requests is! RequestsLoaded) return null;
    return competingRequests(animal.id, requests.requests).firstOrNull;
  }

  void _approveOldest() {
    final animal = _selectedAnimal;
    final request = _oldestPending();
    final requests = context.read<AdoptionRequestBloc>().state;
    if (animal == null || request == null || requests is! RequestsLoaded) return;
    _approve(animal, request, requests.requests);
  }

  void _showShortcuts() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prečice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final shortcut in shortcutDescriptions())
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(shortcut.keys, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Expanded(child: Text(shortcut.description)),
                  ],
                ),
              ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zatvori'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdoptionRequestBloc, AdoptionRequestState>(
      listenWhen: (previous, current) => previous is RequestsLoaded && current is RequestsLoaded,
      listener: _onRequestsChanged,
      child: Shortcuts(
        shortcuts: animalsShortcuts(),
        child: Actions(
          actions: _actions(),
          child: Focus(autofocus: true, child: _content()),
        ),
      ),
    );
  }

  /// Approving or rejecting goes through [AdoptionRequestBloc]; the animal's new status (Reserved) has to be reloaded
  /// into [AnimalsBloc] here, and a refused action is explained in a snack bar.
  void _onRequestsChanged(BuildContext context, AdoptionRequestState state) {
    if (state is! RequestsLoaded) return;
    final error = state.error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } else {
      _bloc.add(const AnimalsRefreshed());
    }
  }

  Widget _content() {
    return BlocBuilder<AnimalsBloc, AnimalsState>(
      builder: (context, state) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= AnimalsScreen.wideBreakpoint;
          final selected = state is AnimalsLoaded ? state.selected : null;
          if (!wide && selected != null) return _detailsPage(selected);
          return Scaffold(
            appBar: AppBar(title: const Text('Životinje'), actions: [..._simulateFailure(), const SizedBox(width: 8)]),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state case AnimalsLoaded(:final filter) || AnimalsEmpty(:final filter))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: AnimalsFilterBar(selected: filter, onChanged: (f) => _bloc.add(AnimalsFilterChanged(f))),
                  ),
                Expanded(child: _body(state, wide: wide)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _body(AnimalsState state, {required bool wide}) {
    final now = _dependencies.clock();
    return switch (state) {
      AnimalsLoading() => const LoadingView(),
      AnimalsFailure() => FailureView(onRetry: () => _bloc.add(const AnimalsRetried())),
      AnimalsEmpty(:final filter) => EmptyView(message: 'Nema životinja za filter „${filterLabel(filter)}“.'),
      AnimalsLoaded(:final animals, :final selectedId, :final selected) when wide => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AnimalsTable(animals: animals, selectedId: selectedId, now: now, onSelect: _toggle),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 380,
              child: Card(
                child: selected == null
                    ? const EmptyView(message: 'Izaberite životinju iz tabele da vidite detalje.')
                    : Stack(
                        children: [
                          _details(selected),
                          Positioned(
                            top: 28,
                            right: 28,
                            child: IconButton.filledTonal(
                              tooltip: 'Zatvori detalje',
                              onPressed: () => _select(null),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      AnimalsLoaded(:final animals) => AnimalsList(animals: animals, now: now, onSelect: _select),
    };
  }

  Widget _detailsPage(Animal animal) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => _select(null)),
        title: Text(animal.name.text),
      ),
      body: _details(animal),
    );
  }

  Widget _details(Animal animal) {
    return BlocBuilder<AdoptionRequestBloc, AdoptionRequestState>(
      builder: (context, requests) => AnimalDetails(
        animal: animal,
        requests: requests,
        now: _dependencies.clock(),
        nameOf: _dependencies.nameOf,
        onApprove: (request) => _approve(animal, request, requests is RequestsLoaded ? requests.requests : const []),
        onReject: _reject,
      ),
    );
  }

  List<Widget> _simulateFailure() {
    final fake = _dependencies.fakeRepository;
    if (fake == null) return const [];
    return [
      TextButton.icon(
        onPressed: () {
          fake.failNextRequest();
          _bloc.add(const AnimalsRetried());
        },
        icon: const Icon(Icons.bug_report_outlined),
        label: const Text('Simuliraj grešku'),
      ),
    ];
  }

  Future<void> _approve(Animal animal, AdoptionRequest request, List<AdoptionRequest> all) async {
    // Approving one request rejects every other pending request for the same animal, so the dialog names them.
    final others = [
      for (final r in all)
        if (r.animalId == animal.id && r.status == AdoptionRequestStatus.pending && r.id != request.id)
          _dependencies.nameOf(r.applicantId),
    ];
    final ok = await confirmApproval(
      context,
      animalName: animal.name.text,
      applicant: _dependencies.nameOf(request.applicantId),
      othersRejected: others,
    );
    if (!ok || !mounted) return;
    context.read<AdoptionRequestBloc>().add(RequestApproved(request.id));
  }

  Future<void> _reject(AdoptionRequest request) async {
    final ok = await confirmRejection(context, applicant: _dependencies.nameOf(request.applicantId));
    if (!ok || !mounted) return;
    context.read<AdoptionRequestBloc>().add(RequestRejected(request.id));
  }
}
