///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element

class Translations implements BaseTranslations<AppLocale, Translations> {
  /// Returns the current translations of the given [context].
  ///
  /// Usage:
  /// final t = Translations.of(context);
  static Translations of(BuildContext context) =>
      InheritedLocaleData.of<AppLocale, Translations>(context).translations;

  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  Translations({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) : assert(
         overrides == null,
         'Set "translation_overrides: true" in order to enable this feature.',
       ),
       $meta = TranslationMetadata(
         locale: AppLocale.en,
         overrides: overrides ?? {},
         cardinalResolver: cardinalResolver,
         ordinalResolver: ordinalResolver,
       ) {
    $meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <en>.
  @override
  final TranslationMetadata<AppLocale, Translations> $meta;

  /// Access flat map
  dynamic operator [](String key) => $meta.getTranslation(key);

  late final Translations _root = this; // ignore: unused_field

  // Translations
  late final TranslationsViewsEn views = TranslationsViewsEn.internal(_root);
  late final TranslationsDevicesEn devices = TranslationsDevicesEn.internal(
    _root,
  );
  late final TranslationsSidebarEn sidebar = TranslationsSidebarEn.internal(
    _root,
  );
  late final TranslationsMappingEn mapping = TranslationsMappingEn.internal(
    _root,
  );
  late final TranslationsCommonEn common = TranslationsCommonEn.internal(_root);
  late final TranslationsMouseCanvasEn mouseCanvas =
      TranslationsMouseCanvasEn.internal(_root);
  late final TranslationsPerformanceEn performance =
      TranslationsPerformanceEn.internal(_root);
  late final TranslationsParameterEn parameter =
      TranslationsParameterEn.internal(_root);
  late final TranslationsBacklightEn backlight =
      TranslationsBacklightEn.internal(_root);
  late final TranslationsActionsEn actions = TranslationsActionsEn.internal(
    _root,
  );
  late final TranslationsDeviceSettingEn deviceSetting =
      TranslationsDeviceSettingEn.internal(_root);
  late final TranslationsMacroEn macro = TranslationsMacroEn.internal(_root);
}

// Path: views
class TranslationsViewsEn {
  TranslationsViewsEn.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  late final TranslationsViewsLoginEn login = TranslationsViewsLoginEn.internal(
    _root,
  );
  late final TranslationsViewsHomeEn home = TranslationsViewsHomeEn.internal(
    _root,
  );
}

// Path: devices
class TranslationsDevicesEn {
  TranslationsDevicesEn.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get addDevice => 'Add device';
  String get working => 'Working...';
  String get bluetoothWarning =>
      'The driver cannot recognize Bluetooth connection. Please use a 2.4G receiver or a cable connection';
  String get noDevices => 'No devices';
}

// Path: sidebar
class TranslationsSidebarEn {
  TranslationsSidebarEn.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get buttonMapping => 'Button Mapping';
  String get macroSetting => 'Macro Setting';
  String get performanceSetting => 'Performance Setting';
  String get parameterSetting => 'Parameter Setting';
  String get backlightSetting => 'Backlight Setting';
  String get profileManagement => 'Profile Management';
  String get deviceSetting => 'Device Setting';
  String get mouse => 'mouse';
  String batteryLabel({required Object pct}) => 'Battery ${pct}%';
  String batteryCharging({required Object pct}) => 'Battery ${pct}% charging';
  String get batteryEmpty => 'Battery —';
}

// Path: mapping
class TranslationsMappingEn {
  TranslationsMappingEn.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get mouse => 'Mouse';
  String get keyboard => 'Keyboard';
  String get special => 'Special';
  String get macro => 'Macro';
  String get modifierKey => 'Modifier key';
}

// Path: common
class TranslationsCommonEn {
  TranslationsCommonEn.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get save => 'Save';
  String get cancel => 'Cancel';
  String get confirm => 'Confirm';
  String get resetToDefault => 'Reset to Default';
  String get tip => 'Tip';
  String get settings => 'Settings';
  String get language => 'Language';
  String get lightMode => 'Light Mode';
  String get darkMode => 'Dark Mode';
  String get switchToLightMode => 'Switch to Light Mode';
  String get switchToDarkMode => 'Switch to Dark Mode';
  String get forward => 'Forward';
  String get reverse => 'Reverse';
  String secondsUnit({required Object seconds}) => '${seconds} sec';
  String get done => 'Done';
}

// Path: mouseCanvas
class TranslationsMouseCanvasEn {
  TranslationsMouseCanvasEn.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get imageMissing => 'Mouse image missing';
  String get restoreDefaultKeysTip =>
      'Are you sure you want to restore default keys?';
}

// Path: performance
class TranslationsPerformanceEn {
  TranslationsPerformanceEn.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get dpiSettings => 'DPI settings';
  String get reportRate => 'Report rate';
  String get levels => 'Levels';
  String dpiLevel({required Object level}) => 'DPI ${level}';
  String get dpiStageColor => 'DPI stage color';
}

// Path: parameter
class TranslationsParameterEn {
  TranslationsParameterEn.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get sensorFeature => 'Sensor feature';
  String get otherFeature => 'Other feature';
  String get rippleControl => 'Ripple Control';
  String get angleSnap => 'Angle Snap';
  String get lod => 'LOD';
  String get angleTune => 'Angle Tune';
  String get performance => 'Performance';
  String get wheelDirection => 'Wheel direction';
}

// Path: backlight
class TranslationsBacklightEn {
  TranslationsBacklightEn.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get title => 'Backlight';
  String get mode => 'Mode';
  String get color => 'Color';
  String get powerSaving => 'Power saving';
}

// Path: actions
class TranslationsActionsEn {
  TranslationsActionsEn.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get left => 'Left';
  String get right => 'Right';
  String get middle => 'Middle';
  String get forward => 'Forward';
  String get backward => 'Backward';
  String get dpiCycle => 'DPI cycle';
  String button({required Object id}) => 'Button ${id}';
  String get disable => 'Disable / No action';
  String get buttonOff => 'Button off';
  String get leftClick => 'Left click';
  String get rightClick => 'Right click';
  String get middleClick => 'Middle click';
  String get scrollUp => 'Scroll up';
  String get scrollDown => 'Scroll down';
  String get swingLeft => 'Swing left';
  String get swingRight => 'Swing right';
  String get dpiIncrease => 'DPI increase';
  String get dpiDecrease => 'DPI decrease';
  String get reportRate => 'Report rate';
  String get profileCycle => 'Profile cycle';
  String get sniper => 'Sniper';
  String macroPlay({required Object id}) => 'Macro play (#${id})';
}

// Path: deviceSetting
class TranslationsDeviceSettingEn {
  TranslationsDeviceSettingEn.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get mouseFirmwareVersion => 'Mouse Firmware Version';
  String get dongleFirmwareVersion => 'Dongle Firmware Version';
  String get latestVersion => 'Latest version';
  String get checkUpdates => 'Check updates';
  String get newVersionUpdate => 'New version & update';
}

// Path: macro
class TranslationsMacroEn {
  TranslationsMacroEn.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get startRecording => 'Start Recording';
  String get stopRecording => 'Stop Recording';
  String get record => 'Record';
  String get reset => 'Reset';
  String get noMacrosConfigured => 'No macros configured';
  String get createMacro => 'Create Macro';
  String get selectShortcutEdit => 'Please select a shortcut to edit';
  String get newMacro => 'New Macro';
}

// Path: views.login
class TranslationsViewsLoginEn {
  TranslationsViewsLoginEn.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String get welcome => 'Welcome';
  String get userName => 'Username';
  String get loginButton => 'Login';
}

// Path: views.home
class TranslationsViewsHomeEn {
  TranslationsViewsHomeEn.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations
  String greeting({required Object userName}) => 'Hello, ${userName}!';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on Translations {
  dynamic _flatMapFunction(String path) {
    switch (path) {
      case 'views.login.welcome':
        return 'Welcome';
      case 'views.login.userName':
        return 'Username';
      case 'views.login.loginButton':
        return 'Login';
      case 'views.home.greeting':
        return ({required Object userName}) => 'Hello, ${userName}!';
      case 'devices.addDevice':
        return 'Add device';
      case 'devices.working':
        return 'Working...';
      case 'devices.bluetoothWarning':
        return 'The driver cannot recognize Bluetooth connection. Please use a 2.4G receiver or a cable connection';
      case 'devices.noDevices':
        return 'No devices';
      case 'sidebar.buttonMapping':
        return 'Button Mapping';
      case 'sidebar.macroSetting':
        return 'Macro Setting';
      case 'sidebar.performanceSetting':
        return 'Performance Setting';
      case 'sidebar.parameterSetting':
        return 'Parameter Setting';
      case 'sidebar.backlightSetting':
        return 'Backlight Setting';
      case 'sidebar.profileManagement':
        return 'Profile Management';
      case 'sidebar.deviceSetting':
        return 'Device Setting';
      case 'sidebar.mouse':
        return 'mouse';
      case 'sidebar.batteryLabel':
        return ({required Object pct}) => 'Battery ${pct}%';
      case 'sidebar.batteryCharging':
        return ({required Object pct}) => 'Battery ${pct}% charging';
      case 'sidebar.batteryEmpty':
        return 'Battery —';
      case 'mapping.mouse':
        return 'Mouse';
      case 'mapping.keyboard':
        return 'Keyboard';
      case 'mapping.special':
        return 'Special';
      case 'mapping.macro':
        return 'Macro';
      case 'mapping.modifierKey':
        return 'Modifier key';
      case 'common.save':
        return 'Save';
      case 'common.cancel':
        return 'Cancel';
      case 'common.confirm':
        return 'Confirm';
      case 'common.resetToDefault':
        return 'Reset to Default';
      case 'common.tip':
        return 'Tip';
      case 'common.settings':
        return 'Settings';
      case 'common.language':
        return 'Language';
      case 'common.lightMode':
        return 'Light Mode';
      case 'common.darkMode':
        return 'Dark Mode';
      case 'common.switchToLightMode':
        return 'Switch to Light Mode';
      case 'common.switchToDarkMode':
        return 'Switch to Dark Mode';
      case 'common.forward':
        return 'Forward';
      case 'common.reverse':
        return 'Reverse';
      case 'common.secondsUnit':
        return ({required Object seconds}) => '${seconds} sec';
      case 'common.done':
        return 'Done';
      case 'mouseCanvas.imageMissing':
        return 'Mouse image missing';
      case 'mouseCanvas.restoreDefaultKeysTip':
        return 'Are you sure you want to restore default keys?';
      case 'performance.dpiSettings':
        return 'DPI settings';
      case 'performance.reportRate':
        return 'Report rate';
      case 'performance.levels':
        return 'Levels';
      case 'performance.dpiLevel':
        return ({required Object level}) => 'DPI ${level}';
      case 'performance.dpiStageColor':
        return 'DPI stage color';
      case 'parameter.sensorFeature':
        return 'Sensor feature';
      case 'parameter.otherFeature':
        return 'Other feature';
      case 'parameter.rippleControl':
        return 'Ripple Control';
      case 'parameter.angleSnap':
        return 'Angle Snap';
      case 'parameter.lod':
        return 'LOD';
      case 'parameter.angleTune':
        return 'Angle Tune';
      case 'parameter.performance':
        return 'Performance';
      case 'parameter.wheelDirection':
        return 'Wheel direction';
      case 'backlight.title':
        return 'Backlight';
      case 'backlight.mode':
        return 'Mode';
      case 'backlight.color':
        return 'Color';
      case 'backlight.powerSaving':
        return 'Power saving';
      case 'actions.left':
        return 'Left';
      case 'actions.right':
        return 'Right';
      case 'actions.middle':
        return 'Middle';
      case 'actions.forward':
        return 'Forward';
      case 'actions.backward':
        return 'Backward';
      case 'actions.dpiCycle':
        return 'DPI cycle';
      case 'actions.button':
        return ({required Object id}) => 'Button ${id}';
      case 'actions.disable':
        return 'Disable / No action';
      case 'actions.buttonOff':
        return 'Button off';
      case 'actions.leftClick':
        return 'Left click';
      case 'actions.rightClick':
        return 'Right click';
      case 'actions.middleClick':
        return 'Middle click';
      case 'actions.scrollUp':
        return 'Scroll up';
      case 'actions.scrollDown':
        return 'Scroll down';
      case 'actions.swingLeft':
        return 'Swing left';
      case 'actions.swingRight':
        return 'Swing right';
      case 'actions.dpiIncrease':
        return 'DPI increase';
      case 'actions.dpiDecrease':
        return 'DPI decrease';
      case 'actions.reportRate':
        return 'Report rate';
      case 'actions.profileCycle':
        return 'Profile cycle';
      case 'actions.sniper':
        return 'Sniper';
      case 'actions.macroPlay':
        return ({required Object id}) => 'Macro play (#${id})';
      case 'deviceSetting.mouseFirmwareVersion':
        return 'Mouse Firmware Version';
      case 'deviceSetting.dongleFirmwareVersion':
        return 'Dongle Firmware Version';
      case 'deviceSetting.latestVersion':
        return 'Latest version';
      case 'deviceSetting.checkUpdates':
        return 'Check updates';
      case 'deviceSetting.newVersionUpdate':
        return 'New version & update';
      case 'macro.startRecording':
        return 'Start Recording';
      case 'macro.stopRecording':
        return 'Stop Recording';
      case 'macro.record':
        return 'Record';
      case 'macro.reset':
        return 'Reset';
      case 'macro.noMacrosConfigured':
        return 'No macros configured';
      case 'macro.createMacro':
        return 'Create Macro';
      case 'macro.selectShortcutEdit':
        return 'Please select a shortcut to edit';
      case 'macro.newMacro':
        return 'New Macro';
      default:
        return null;
    }
  }
}
