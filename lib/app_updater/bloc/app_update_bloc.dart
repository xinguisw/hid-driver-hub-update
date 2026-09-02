import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:driver_hub/app_updater/bloc/app_update_event.dart';
import 'package:driver_hub/app_updater/bloc/app_update_state.dart';
import 'package:driver_hub/app_updater/models/updater_config.dart';
import 'package:driver_hub/app_updater/services/auto_updater_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// State management BLoC coordinating the application auto-updater subsystem.
///
/// Features concurrency control via [droppable] to ignore duplicate check requests
/// while a check is currently in flight.
class AppUpdateBloc extends Bloc<AppUpdateEvent, AppUpdateState> {
  AppUpdateBloc({
    AutoUpdaterService? autoUpdaterService,
    this._defaultConfig = const UpdaterConfig(),
  })  : _autoUpdaterService = autoUpdaterService ?? AutoUpdaterService(),
        super(const AppUpdateInitial()) {
    on<InitializeUpdaterRequested>(_onInitialize);
    on<CheckForUpdatesRequested>(
      _onCheckForUpdates,
      transformer: droppable(),
    );
    on<SetUpdateIntervalRequested>(_onSetUpdateInterval);
    on<ResetUpdateStateRequested>(_onResetUpdateState);
  }

  final AutoUpdaterService _autoUpdaterService;
  final UpdaterConfig _defaultConfig;

  /// Exposes the underlying updater service for testing or direct inspection.
  AutoUpdaterService get autoUpdaterService => _autoUpdaterService;

  Future<void> _onInitialize(
    InitializeUpdaterRequested event,
    Emitter<AppUpdateState> emit,
  ) async {
    final config = event.config ?? _defaultConfig;
    try {
      await _autoUpdaterService.initialize(config);
    } catch (e) {
      emit(AppUpdateCheckFailure(
        message: e.toString(),
        isManual: false,
      ));
    }
  }

  Future<void> _onCheckForUpdates(
    CheckForUpdatesRequested event,
    Emitter<AppUpdateState> emit,
  ) async {
    emit(AppUpdateChecking(isManual: event.isManual));

    try {
      if (!_autoUpdaterService.isInitialized) {
        await _autoUpdaterService.initialize(_defaultConfig);
      }

      await _autoUpdaterService.checkForUpdates(isManual: event.isManual);

      emit(AppUpdateCheckSuccess(
        isManual: event.isManual,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      emit(AppUpdateCheckFailure(
        message: e.toString(),
        isManual: event.isManual,
      ));
    }
  }

  Future<void> _onSetUpdateInterval(
    SetUpdateIntervalRequested event,
    Emitter<AppUpdateState> emit,
  ) async {
    try {
      await _autoUpdaterService.setScheduledCheckInterval(event.intervalSeconds);
    } catch (e) {
      emit(AppUpdateCheckFailure(
        message: e.toString(),
        isManual: false,
      ));
    }
  }

  void _onResetUpdateState(
    ResetUpdateStateRequested event,
    Emitter<AppUpdateState> emit,
  ) {
    emit(const AppUpdateInitial());
  }
}
