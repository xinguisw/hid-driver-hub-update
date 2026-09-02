import 'package:driver_hub/app_updater/bloc/app_update_bloc.dart';
import 'package:driver_hub/app_updater/bloc/app_update_event.dart';
import 'package:driver_hub/app_updater/bloc/app_update_state.dart';
import 'package:driver_hub/i18n/strings.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A theme-aware button that dispatches update checks via [AppUpdateBloc]
/// and renders a progress spinner while checking.
///
/// Strictly uses vector icons and avoids emojis for visual consistency.
/// Automatically hides itself on Web via [kIsWeb] guard.
class UpdaterActionButton extends StatelessWidget {
  const UpdaterActionButton({
    super.key,
    this.appUpdateBloc,
  });

  /// Optional injected bloc instance. If omitted, looks up from context.
  final AppUpdateBloc? appUpdateBloc;

  @override
  Widget build(BuildContext context) {
    // Hide updater button entirely in web browser sandbox
    if (kIsWeb) {
      return const SizedBox.shrink();
    }
    if (appUpdateBloc != null) {
      return BlocProvider<AppUpdateBloc>.value(
        value: appUpdateBloc!,
        child: const _UpdaterActionButtonContent(),
      );
    }

    try {
      context.read<AppUpdateBloc>();
      return const _UpdaterActionButtonContent();
    } catch (_) {
      return BlocProvider<AppUpdateBloc>(
        create: (_) => AppUpdateBloc(),
        child: const _UpdaterActionButtonContent(),
      );
    }
  }
}

class _UpdaterActionButtonContent extends StatelessWidget {
  const _UpdaterActionButtonContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<AppUpdateBloc, AppUpdateState>(
      listener: (context, state) {
        if (state is AppUpdateCheckFailure && state.isManual) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                t.appSettings.updateCheckFailed(error: state.message),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: theme.colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        final isChecking = state is AppUpdateChecking;

        return OutlinedButton.icon(
          onPressed: isChecking
              ? null
              : () {
                  context.read<AppUpdateBloc>().add(
                        const CheckForUpdatesRequested(isManual: true),
                      );
                },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            side: BorderSide(
              color: isDark ? Colors.white24 : Colors.black12,
              width: 1,
            ),
            backgroundColor: isDark
                ? Colors.white.withAlpha(12)
                : Colors.black.withAlpha(8),
          ),
          icon: isChecking
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                )
              : Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
          label: Text(
            isChecking
                ? t.appSettings.checkingForUpdates
                : t.appSettings.checkForUpdates,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        );
      },
    );
  }
}
