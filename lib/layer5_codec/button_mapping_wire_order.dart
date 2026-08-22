/// Shared B2 button-map slot translation.
///
/// The app keeps the six physical buttons in logical UI order:
/// Left, Right, Middle, Forward, Backward, DPI cycle.
///
/// Hardware B2 wire order matches logical UI slot order directly:
/// Slot 0 = Left, Slot 1 = Right, Slot 2 = Middle, Slot 3 = Forward, Slot 4 = Backward, Slot 5 = DPI.
const List<int> _uiToWireIndex = [0, 1, 2, 3, 4, 5];

/// Reorder logical UI entries into the device's B2 wire-slot order.
List<T> buttonMappingUiToWire<T>(List<T> uiEntries) {
  _checkButtonMappingLength(uiEntries, 'uiEntries');
  return [for (final index in _uiToWireIndex) uiEntries[index]];
}

/// Reorder device B2 wire entries into logical UI order.
List<T> buttonMappingWireToUi<T>(List<T> wireEntries) {
  return buttonMappingUiToWire(wireEntries);
}

void _checkButtonMappingLength<T>(List<T> entries, String name) {
  if (entries.length != _uiToWireIndex.length) {
    throw ArgumentError.value(
      entries.length,
      '$name.length',
      'button mapping requires exactly ${_uiToWireIndex.length} slots',
    );
  }
}
