import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../../dependencies.dart';
import '../../format.dart';
import '../../shortcuts.dart';
import 'animal_details.dart';
import 'animals_filter_bar.dart';
import 'animals_list.dart';
import 'animals_table.dart';
import 'confirm_dialog.dart';
import 'intake_dialog.dart';

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

  /// The whole screen (table and filters): the arrows and the other shortcuts work while the focus is here.
  final _screenFocus = FocusNode(debugLabel: 'Animals screen');

  /// The details panel: → moves the focus in, and Tab or ↑/↓ then stay inside until ← or Esc.
  final _detailsFocus = FocusScopeNode(debugLabel: 'Animal details');

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

  @override
  void dispose() {
    _screenFocus.dispose();
    _detailsFocus.dispose();
    super.dispose();
  }

  void _select(AnimalId? id) => context.go(AnimalsScreen.pathFor(id));

  void _toggle(AnimalId id) => _select(id == widget.selectedId ? null : id);

  Map<Type, Action<Intent>> _actions() => {
    MoveSelectionIntent: CallbackAction<MoveSelectionIntent>(onInvoke: (intent) => _move(intent.offset)),
    ClearSelectionIntent: GuardedCallbackAction<ClearSelectionIntent>(
      enabled: () => widget.selectedId != null,
      onInvoke: (_) {
        _screenFocus.requestFocus();
        _select(null);
        return null;
      },
    ),
    FocusDetailsIntent: GuardedCallbackAction<FocusDetailsIntent>(
      enabled: () => widget.selectedId != null && !_detailsFocus.hasFocus,
      onInvoke: (_) => _focusDetails(),
    ),
    FocusTableIntent: GuardedCallbackAction<FocusTableIntent>(
      enabled: () => _detailsFocus.hasFocus,
      onInvoke: (_) => _screenFocus.requestFocus(),
    ),
    ApproveIntent: GuardedCallbackAction<ApproveIntent>(
      enabled: () => _oldestPending() != null,
      onInvoke: (_) => _approveOldest(),
    ),
    ShowShortcutsIntent: CallbackAction<ShowShortcutsIntent>(onInvoke: (_) => _showShortcuts()),
    IntakeIntent: GuardedCallbackAction<IntakeIntent>(enabled: () => _canIntake, onInvoke: (_) => _intake()),
  };

  /// Focuses the button used last time in the panel, or the first one.
  void _focusDetails() {
    final previous = _detailsFocus.focusedChild;
    if (previous != null) {
      previous.requestFocus();
    } else {
      _detailsFocus.nextFocus();
    }
  }

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
    return MultiBlocListener(
      listeners: [
        BlocListener<AdoptionRequestBloc, AdoptionRequestState>(
          listenWhen: (previous, current) => previous is RequestsLoaded && current is RequestsLoaded,
          listener: _onRequestsChanged,
        ),
        BlocListener<AnimalsBloc, AnimalsState>(
          listenWhen: (previous, current) => current is AnimalsLoaded && current.notice != null,
          listener: _onAnimalsNotice,
        ),
      ],
      child: Shortcuts(
        shortcuts: animalsShortcuts(),
        child: Actions(
          actions: _actions(),
          child: Focus(focusNode: _screenFocus, autofocus: true, child: _content()),
        ),
      ),
    );
  }

  void _onRequestsChanged(BuildContext context, AdoptionRequestState state) {
    if (state is! RequestsLoaded) return;
    final notice = state.notice;
    if (notice == null) return;
    switch (notice) {
      case RequestSaved():
        _bloc.add(const AnimalsRefreshed());
      case RequestRefused(:final error):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      case RequestFailed():
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Akcija nije uspela. Pokušaj ponovo.')));
    }
    context.read<AdoptionRequestBloc>().add(const RequestsNoticeAcknowledged());
  }

  void _onAnimalsNotice(BuildContext context, AnimalsState state) {
    if (state is! AnimalsLoaded) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (state.notice) {
      case AnimalSaved(:final animal):
        messenger.showSnackBar(SnackBar(content: Text(_savedMessage(animal))));
        _select(animal.id);
      case AnimalRefused(:final error):
        messenger.showSnackBar(SnackBar(content: Text(error.message)));
      case AnimalSaveFailed():
        messenger.showSnackBar(const SnackBar(content: Text('Čuvanje nije uspelo. Pokušaj ponovo.')));
      case null:
        return;
    }
    _bloc.add(const AnimalsNoticeAcknowledged());
  }

  String _savedMessage(Animal animal) {
    final name = animal.name.text;
    return switch (animal.status) {
      Received() => '$name je primljen/a u utočište.',
      InQuarantine(:final until) => '$name je u karantinu do ${formatDate(until)}',
      ReadyForAdoption() => '$name je spreman/na za udomljavanje.',
      _ => 'Sačuvano: $name.',
    };
  }

  Future<void> _startQuarantine(Animal animal) async {
    final now = _dependencies.clock.now();
    final until = await pickQuarantineEnd(context, animalName: animal.name.text, now: now);
    if (until == null || !mounted) return;
    _bloc.add(QuarantineStarted(animalId: animal.id, by: _dependencies.user, until: until));
  }

  Future<void> _endQuarantine(Animal animal) async {
    final ok = await confirmEndQuarantine(context, animalName: animal.name.text);
    if (!ok || !mounted) return;
    _bloc.add(QuarantineEnded(animalId: animal.id, by: _dependencies.user));
  }

  bool get _canIntake => _bloc.state is AnimalsLoaded || _bloc.state is AnimalsEmpty;

  Future<void> _intake() async {
    final data = await showIntakeDialog(context, enclosures: _bloc.enclosures, now: _dependencies.clock.now());
    if (data == null || !mounted) return;
    _bloc.add(
      AnimalIntakeSubmitted(
        by: _dependencies.user,
        name: data.name,
        species: data.species,
        birthDate: data.birthDate,
        description: data.description,
        enclosureId: data.enclosureId,
      ),
    );
  }

  Widget _content() {
    return BlocBuilder<AnimalsBloc, AnimalsState>(
      builder: (context, state) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= AnimalsScreen.wideBreakpoint;
          final selected = state is AnimalsLoaded ? state.selected : null;
          if (!wide && selected != null) return _detailsPage(selected);
          return Scaffold(
            appBar: AppBar(
              title: const Text('Životinje'),
              actions: [
                ..._simulateFailure(),
                const SizedBox(width: 8),
                Tooltip(
                  message: '$commandKeyLabel N',
                  child: FilledButton.tonalIcon(
                    onPressed: _canIntake ? _intake : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Nova životinja'),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
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
    final now = _dependencies.clock.now();
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
              child: BlocBuilder<AdoptionRequestBloc, AdoptionRequestState>(
                builder: (context, requests) => AnimalsTable(
                  animals: animals,
                  selectedId: selectedId,
                  now: now,
                  onSelect: _toggle,
                  pendingRequests: _pendingByAnimal(requests),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 380,
              // The panel gets a leaf-green outline while the keyboard focus is inside it.
              child: ListenableBuilder(
                listenable: _detailsFocus,
                builder: (context, child) => Card(
                  shape: _detailsFocus.hasFocus
                      ? RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                        )
                      : null,
                  child: child,
                ),
                child: selected == null
                    ? const EmptyView(message: 'Izaberite životinju iz tabele da vidite detalje.')
                    : _detailsScope(
                        Stack(
                          children: [
                            _details(selected),
                            Positioned(
                              top: 28,
                              right: 28,
                              // Esc closes the panel from the keyboard, so Tab and ↑/↓ skip this button.
                              child: ExcludeFocus(
                                child: IconButton.filledTonal(
                                  tooltip: 'Zatvori detalje (Esc)',
                                  onPressed: () => _select(null),
                                  icon: const Icon(Icons.close),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      AnimalsLoaded(:final animals) => AnimalsList(animals: animals, now: now, onSelect: _select),
    };
  }

  /// Counts the pending requests per animal for the table's "Zahtevi" column; empty until the requests load.
  Map<AnimalId, int> _pendingByAnimal(AdoptionRequestState requests) {
    if (requests is! RequestsLoaded) return const {};
    final counts = <AnimalId, int>{};
    for (final request in requests.requests) {
      if (request.status == AdoptionRequestStatus.pending) {
        counts[request.animalId] = (counts[request.animalId] ?? 0) + 1;
      }
    }
    return counts;
  }

  Widget _detailsPage(Animal animal) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => _select(null)),
        title: Text(animal.name.text),
      ),
      body: _detailsScope(_details(animal)),
    );
  }

  Widget _detailsScope(Widget child) {
    return FocusScope(
      node: _detailsFocus,
      child: Shortcuts(shortcuts: detailsShortcuts(), child: child),
    );
  }

  Widget _details(Animal animal) {
    return BlocBuilder<AdoptionRequestBloc, AdoptionRequestState>(
      builder: (context, requests) => AnimalDetails(
        animal: animal,
        requests: requests,
        now: _dependencies.clock.now(),
        nameOf: _dependencies.nameOf,
        onApprove: (request) => _approve(animal, request, requests is RequestsLoaded ? requests.requests : const []),
        onReject: _reject,
        onStartQuarantine: () => _startQuarantine(animal),
        onEndQuarantine: () => _endQuarantine(animal),
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
