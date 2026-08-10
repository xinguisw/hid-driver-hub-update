/// Shared B2 button-map slot translation.
///
/// The app keeps the six physical buttons in logical UI order:
/// Left, Right, Middle, Forward, Backward, DPI cycle.
///
/// The B2 firmware block used by these mice stores the two side-button
/// entries in the opposite wire positions. Keep this permutation in the
/// protocol layer so every model using this six-slot structure follows the
/// same read/write boundary; no product-name special case is needed.
const List<int> _uiToWireIndex = [0, 1, 2, 4, 3, 5];

/// Reorder logical UI entries into the device's B2 wire-slot order.
List<T> buttonMappingUiToWire<T>(List<T> uiEntries) {
  _checkButtonMappingLength(uiEntries, 'uiEntries');
  return [for (final index in _uiToWireIndex) uiEntries[index]];
}

/// Reorder device B2 wire entries into logical UI order.
List<T> buttonMappingWireToUi<T>(List<T> wireEntries) {
  // This permutation is its own inverse: swapping slots 4 and 5 twice
  // restores the original order.
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
