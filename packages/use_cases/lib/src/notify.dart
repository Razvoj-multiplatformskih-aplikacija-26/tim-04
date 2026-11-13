Future<void> notifySafely(Future<void> Function() send) async {
  try {
    await send();
  } catch (_) {}
}
