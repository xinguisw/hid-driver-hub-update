// Off-web stub for web HID events. Real impl is web_hid_events.dart, selected
// by the conditional import in hid_events.dart. Must expose the same symbols.
import '../hid_event_handle.dart';

HidEventSubscription startWebHidListeners({
  required void Function(String path, int vendorId, int productId) onConnect,
  required void Function(String path, int vendorId, int productId) onDisconnect,
}) {
  return const HidEventSubscription.noop();
}
