///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$views$en views = Translations$views$en.internal(_root);
	late final Translations$devices$en devices = Translations$devices$en.internal(_root);
	late final Translations$sidebar$en sidebar = Translations$sidebar$en.internal(_root);
	late final Translations$mapping$en mapping = Translations$mapping$en.internal(_root);
	late final Translations$common$en common = Translations$common$en.internal(_root);
	late final Translations$mouseCanvas$en mouseCanvas = Translations$mouseCanvas$en.internal(_root);
	late final Translations$performance$en performance = Translations$performance$en.internal(_root);
	late final Translations$parameter$en parameter = Translations$parameter$en.internal(_root);
	late final Translations$backlight$en backlight = Translations$backlight$en.internal(_root);
	late final Translations$actions$en actions = Translations$actions$en.internal(_root);
	late final Translations$deviceSetting$en deviceSetting = Translations$deviceSetting$en.internal(_root);
	late final Translations$macro$en macro = Translations$macro$en.internal(_root);
}

// Path: views
class Translations$views$en {
	Translations$views$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$views$login$en login = Translations$views$login$en.internal(_root);
	late final Translations$views$home$en home = Translations$views$home$en.internal(_root);
}

// Path: devices
class Translations$devices$en {
	Translations$devices$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Add device'
	String get addDevice => 'Add device';

	/// en: 'Working...'
	String get working => 'Working...';

	/// en: 'The driver cannot recognize Bluetooth connection. Please use a 2.4G receiver or a cable connection'
	String get bluetoothWarning => 'The driver cannot recognize Bluetooth connection. Please use a 2.4G receiver or a cable connection';

	/// en: 'No devices'
	String get noDevices => 'No devices';
}

// Path: sidebar
class Translations$sidebar$en {
	Translations$sidebar$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Button Mapping'
	String get buttonMapping => 'Button Mapping';

	/// en: 'Macro Setting'
	String get macroSetting => 'Macro Setting';

	/// en: 'Performance Setting'
	String get performanceSetting => 'Performance Setting';

	/// en: 'Parameter Setting'
	String get parameterSetting => 'Parameter Setting';

	/// en: 'Backlight Setting'
	String get backlightSetting => 'Backlight Setting';

	/// en: 'Profile Management'
	String get profileManagement => 'Profile Management';

	/// en: 'Device Setting'
	String get deviceSetting => 'Device Setting';

	/// en: 'mouse'
	String get mouse => 'mouse';

	/// en: 'Battery {pct}%'
	String batteryLabel({required Object pct}) => 'Battery ${pct}%';

	/// en: 'Battery {pct}% charging'
	String batteryCharging({required Object pct}) => 'Battery ${pct}% charging';

	/// en: 'Battery —'
	String get batteryEmpty => 'Battery —';
}

// Path: mapping
class Translations$mapping$en {
	Translations$mapping$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Mouse'
	String get mouse => 'Mouse';

	/// en: 'Keyboard'
	String get keyboard => 'Keyboard';

	/// en: 'Special'
	String get special => 'Special';

	/// en: 'Macro'
	String get macro => 'Macro';

	/// en: 'Modifier key'
	String get modifierKey => 'Modifier key';
}

// Path: common
class Translations$common$en {
	Translations$common$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Confirm'
	String get confirm => 'Confirm';

	/// en: 'Reset to Default'
	String get resetToDefault => 'Reset to Default';

	/// en: 'Tip'
	String get tip => 'Tip';

	/// en: 'Settings'
	String get settings => 'Settings';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Light Mode'
	String get lightMode => 'Light Mode';

	/// en: 'Dark Mode'
	String get darkMode => 'Dark Mode';

	/// en: 'Switch to Light Mode'
	String get switchToLightMode => 'Switch to Light Mode';

	/// en: 'Switch to Dark Mode'
	String get switchToDarkMode => 'Switch to Dark Mode';

	/// en: 'Forward'
	String get forward => 'Forward';

	/// en: 'Reverse'
	String get reverse => 'Reverse';

	/// en: '{seconds} sec'
	String secondsUnit({required Object seconds}) => '${seconds} sec';

	/// en: 'Done'
	String get done => 'Done';
}

// Path: mouseCanvas
class Translations$mouseCanvas$en {
	Translations$mouseCanvas$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Mouse image missing'
	String get imageMissing => 'Mouse image missing';

	/// en: 'Are you sure you want to restore default keys?'
	String get restoreDefaultKeysTip => 'Are you sure you want to restore default keys?';
}

// Path: performance
class Translations$performance$en {
	Translations$performance$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'DPI settings'
	String get dpiSettings => 'DPI settings';

	/// en: 'Report rate'
	String get reportRate => 'Report rate';

	/// en: 'Levels'
	String get levels => 'Levels';

	/// en: 'DPI {level}'
	String dpiLevel({required Object level}) => 'DPI ${level}';

	/// en: 'DPI stage color'
	String get dpiStageColor => 'DPI stage color';
}

// Path: parameter
class Translations$parameter$en {
	Translations$parameter$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Sensor feature'
	String get sensorFeature => 'Sensor feature';

	/// en: 'Other feature'
	String get otherFeature => 'Other feature';

	/// en: 'Ripple Control'
	String get rippleControl => 'Ripple Control';

	/// en: 'Angle Snap'
	String get angleSnap => 'Angle Snap';

	/// en: 'LOD'
	String get lod => 'LOD';

	/// en: 'Angle Tune'
	String get angleTune => 'Angle Tune';

	/// en: 'Performance'
	String get performance => 'Performance';

	/// en: 'Wheel direction'
	String get wheelDirection => 'Wheel direction';
}

// Path: backlight
class Translations$backlight$en {
	Translations$backlight$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Backlight'
	String get title => 'Backlight';

	/// en: 'Mode'
	String get mode => 'Mode';

	/// en: 'Color'
	String get color => 'Color';

	/// en: 'Power saving'
	String get powerSaving => 'Power saving';
}

// Path: actions
class Translations$actions$en {
	Translations$actions$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Left'
	String get left => 'Left';

	/// en: 'Right'
	String get right => 'Right';

	/// en: 'Middle'
	String get middle => 'Middle';

	/// en: 'Forward'
	String get forward => 'Forward';

	/// en: 'Backward'
	String get backward => 'Backward';

	/// en: 'DPI cycle'
	String get dpiCycle => 'DPI cycle';

	/// en: 'Button {id}'
	String button({required Object id}) => 'Button ${id}';

	/// en: 'Disable / No action'
	String get disable => 'Disable / No action';

	/// en: 'Button off'
	String get buttonOff => 'Button off';

	/// en: 'Left click'
	String get leftClick => 'Left click';

	/// en: 'Right click'
	String get rightClick => 'Right click';

	/// en: 'Middle click'
	String get middleClick => 'Middle click';

	/// en: 'Scroll up'
	String get scrollUp => 'Scroll up';

	/// en: 'Scroll down'
	String get scrollDown => 'Scroll down';

	/// en: 'Swing left'
	String get swingLeft => 'Swing left';

	/// en: 'Swing right'
	String get swingRight => 'Swing right';

	/// en: 'DPI increase'
	String get dpiIncrease => 'DPI increase';

	/// en: 'DPI decrease'
	String get dpiDecrease => 'DPI decrease';

	/// en: 'Report rate'
	String get reportRate => 'Report rate';

	/// en: 'Profile cycle'
	String get profileCycle => 'Profile cycle';

	/// en: 'Sniper'
	String get sniper => 'Sniper';

	/// en: 'Macro play (#{id})'
	String macroPlay({required Object id}) => 'Macro play (#${id})';
}

// Path: deviceSetting
class Translations$deviceSetting$en {
	Translations$deviceSetting$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Mouse Firmware Version'
	String get mouseFirmwareVersion => 'Mouse Firmware Version';

	/// en: 'Dongle Firmware Version'
	String get dongleFirmwareVersion => 'Dongle Firmware Version';

	/// en: 'Latest version'
	String get latestVersion => 'Latest version';

	/// en: 'Check updates'
	String get checkUpdates => 'Check updates';

	/// en: 'New version & update'
	String get newVersionUpdate => 'New version & update';
}

// Path: macro
class Translations$macro$en {
	Translations$macro$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Start Recording'
	String get startRecording => 'Start Recording';

	/// en: 'Stop Recording'
	String get stopRecording => 'Stop Recording';

	/// en: 'Record'
	String get record => 'Record';

	/// en: 'Reset'
	String get reset => 'Reset';

	/// en: 'No macros configured'
	String get noMacrosConfigured => 'No macros configured';

	/// en: 'Create Macro'
	String get createMacro => 'Create Macro';

	/// en: 'Please select a shortcut to edit'
	String get selectShortcutEdit => 'Please select a shortcut to edit';

	/// en: 'New Macro'
	String get newMacro => 'New Macro';
}

// Path: views.login
class Translations$views$login$en {
	Translations$views$login$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Welcome'
	String get welcome => 'Welcome';

	/// en: 'Username'
	String get userName => 'Username';

	/// en: 'Login'
	String get loginButton => 'Login';
}

// Path: views.home
class Translations$views$home$en {
	Translations$views$home$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Hello, {userName}!'
	String greeting({required Object userName}) => 'Hello, ${userName}!';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'views.login.welcome' => 'Welcome',
			'views.login.userName' => 'Username',
			'views.login.loginButton' => 'Login',
			'views.home.greeting' => ({required Object userName}) => 'Hello, ${userName}!',
			'devices.addDevice' => 'Add device',
			'devices.working' => 'Working...',
			'devices.bluetoothWarning' => 'The driver cannot recognize Bluetooth connection. Please use a 2.4G receiver or a cable connection',
			'devices.noDevices' => 'No devices',
			'sidebar.buttonMapping' => 'Button Mapping',
			'sidebar.macroSetting' => 'Macro Setting',
			'sidebar.performanceSetting' => 'Performance Setting',
			'sidebar.parameterSetting' => 'Parameter Setting',
			'sidebar.backlightSetting' => 'Backlight Setting',
			'sidebar.profileManagement' => 'Profile Management',
			'sidebar.deviceSetting' => 'Device Setting',
			'sidebar.mouse' => 'mouse',
			'sidebar.batteryLabel' => ({required Object pct}) => 'Battery ${pct}%',
			'sidebar.batteryCharging' => ({required Object pct}) => 'Battery ${pct}% charging',
			'sidebar.batteryEmpty' => 'Battery —',
			'mapping.mouse' => 'Mouse',
			'mapping.keyboard' => 'Keyboard',
			'mapping.special' => 'Special',
			'mapping.macro' => 'Macro',
			'mapping.modifierKey' => 'Modifier key',
			'common.save' => 'Save',
			'common.cancel' => 'Cancel',
			'common.confirm' => 'Confirm',
			'common.resetToDefault' => 'Reset to Default',
			'common.tip' => 'Tip',
			'common.settings' => 'Settings',
			'common.language' => 'Language',
			'common.lightMode' => 'Light Mode',
			'common.darkMode' => 'Dark Mode',
			'common.switchToLightMode' => 'Switch to Light Mode',
			'common.switchToDarkMode' => 'Switch to Dark Mode',
			'common.forward' => 'Forward',
			'common.reverse' => 'Reverse',
			'common.secondsUnit' => ({required Object seconds}) => '${seconds} sec',
			'common.done' => 'Done',
			'mouseCanvas.imageMissing' => 'Mouse image missing',
			'mouseCanvas.restoreDefaultKeysTip' => 'Are you sure you want to restore default keys?',
			'performance.dpiSettings' => 'DPI settings',
			'performance.reportRate' => 'Report rate',
			'performance.levels' => 'Levels',
			'performance.dpiLevel' => ({required Object level}) => 'DPI ${level}',
			'performance.dpiStageColor' => 'DPI stage color',
			'parameter.sensorFeature' => 'Sensor feature',
			'parameter.otherFeature' => 'Other feature',
			'parameter.rippleControl' => 'Ripple Control',
			'parameter.angleSnap' => 'Angle Snap',
			'parameter.lod' => 'LOD',
			'parameter.angleTune' => 'Angle Tune',
			'parameter.performance' => 'Performance',
			'parameter.wheelDirection' => 'Wheel direction',
			'backlight.title' => 'Backlight',
			'backlight.mode' => 'Mode',
			'backlight.color' => 'Color',
			'backlight.powerSaving' => 'Power saving',
			'actions.left' => 'Left',
			'actions.right' => 'Right',
			'actions.middle' => 'Middle',
			'actions.forward' => 'Forward',
			'actions.backward' => 'Backward',
			'actions.dpiCycle' => 'DPI cycle',
			'actions.button' => ({required Object id}) => 'Button ${id}',
			'actions.disable' => 'Disable / No action',
			'actions.buttonOff' => 'Button off',
			'actions.leftClick' => 'Left click',
			'actions.rightClick' => 'Right click',
			'actions.middleClick' => 'Middle click',
			'actions.scrollUp' => 'Scroll up',
			'actions.scrollDown' => 'Scroll down',
			'actions.swingLeft' => 'Swing left',
			'actions.swingRight' => 'Swing right',
			'actions.dpiIncrease' => 'DPI increase',
			'actions.dpiDecrease' => 'DPI decrease',
			'actions.reportRate' => 'Report rate',
			'actions.profileCycle' => 'Profile cycle',
			'actions.sniper' => 'Sniper',
			'actions.macroPlay' => ({required Object id}) => 'Macro play (#${id})',
			'deviceSetting.mouseFirmwareVersion' => 'Mouse Firmware Version',
			'deviceSetting.dongleFirmwareVersion' => 'Dongle Firmware Version',
			'deviceSetting.latestVersion' => 'Latest version',
			'deviceSetting.checkUpdates' => 'Check updates',
			'deviceSetting.newVersionUpdate' => 'New version & update',
			'macro.startRecording' => 'Start Recording',
			'macro.stopRecording' => 'Stop Recording',
			'macro.record' => 'Record',
			'macro.reset' => 'Reset',
			'macro.noMacrosConfigured' => 'No macros configured',
			'macro.createMacro' => 'Create Macro',
			'macro.selectShortcutEdit' => 'Please select a shortcut to edit',
			'macro.newMacro' => 'New Macro',
			_ => null,
		};
	}
}
