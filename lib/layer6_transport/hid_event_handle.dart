/// Handle returned by [HidEvents.start]. Call [stop] to remove listeners.
class HidEventSubscription {
  final void Function() _stop;
  const HidEventSubscription(this._stop);
  const HidEventSubscription.noop() : _stop = _noopStop;
  static void _noopStop() {}
  void stop() => _stop();
}
