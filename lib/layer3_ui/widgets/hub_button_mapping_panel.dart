import 'package:flutter/material.dart';

/// Button Mapping right pane — empty skeleton until editors land.
///
/// L3 only. **Only** for the Button Mapping hub page. Opens when the user
/// taps a **callout label** on [HubMouseCanvas] (not the placement dot).
class HubButtonMappingPanel extends StatelessWidget {
  const HubButtonMappingPanel({
    super.key,
    this.selectedButtonId,
  });

  /// Button id from canvas **label** tap; null = not driven.
  final int? selectedButtonId;

  static const double width = 256;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: const ColoredBox(
        // why: empty skeleton — mapping UI later; panel is button-mapping only
        color: Colors.transparent,
        child: SizedBox.expand(),
      ),
    );
  }
}
