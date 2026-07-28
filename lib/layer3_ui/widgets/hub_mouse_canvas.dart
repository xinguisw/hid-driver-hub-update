import 'package:flutter/material.dart';

/// Center hub pane — large mouse image (button-mapping canvas later).
///
/// L3 only. Independent dart: image now; hotspots later from catalog.
class HubMouseCanvas extends StatelessWidget {
  const HubMouseCanvas({
    super.key,
    required this.imageLarge,
  });

  /// Catalog large asset path ([DiscoveredCardState.imageLarge]).
  final String imageLarge;

  @override
  Widget build(BuildContext context) {
    // why: full-bleed large asset was too big; cap to half the pane
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth * 0.5;
        final maxH = constraints.maxHeight * 0.5;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxW,
              maxHeight: maxH,
            ),
            child: Image.asset(
              imageLarge,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Text('Mouse image missing'),
            ),
          ),
        );
      },
    );
  }
}
