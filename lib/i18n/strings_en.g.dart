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
	late final Translations$windowControls$en windowControls = Translations$windowControls$en.internal(_root);
	late final Translations$mapping$en mapping = Translations$mapping$en.internal(_root);
	late final Translations$common$en common = Translations$common$en.internal(_root);
	late final Translations$mouseCanvas$en mouseCanvas = Translations$mouseCanvas$en.internal(_root);
	late final Translations$performance$en performance = Translations$performance$en.internal(_root);
	late final Translations$parameter$en parameter = Translations$parameter$en.internal(_root);
	late final Translations$backlight$en backlight = Translations$backlight$en.internal(_root);
	late final Translations$actions$en actions = Translations$actions$en.internal(_root);
	late final Translations$deviceSetting$en deviceSetting = Translations$deviceSetting$en.internal(_root);
	late final Translations$macro$en macro = Translations$macro$en.internal(_root);
	late final Translations$appSettings$en appSettings = Translations$appSettings$en.internal(_root);
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

	/// en: 'Device status'
	String get deviceStatus => 'Device status';

	/// en: '{deviceName}: battery low'
	String batteryLow({required Object deviceName}) => '${deviceName}: battery low';
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

	/// en: 'Back'
	String get back => 'Back';
}

// Path: windowControls
class Translations$windowControls$en {
	Translations$windowControls$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Minimize'
	String get minimize => 'Minimize';

	/// en: 'Maximize'
	String get maximize => 'Maximize';

	/// en: 'Restore'
	String get restore => 'Restore';

	/// en: 'Close'
	String get close => 'Close';
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

	/// en: 'Any key'
	String get anyKey => 'Any key';

	/// en: 'Mouse Action'
	String get mouseAction => 'Mouse Action';

	/// en: 'Mouse Wheel Action'
	String get mouseWheelAction => 'Mouse Wheel Action';

	/// en: 'Multimedia'
	String get multimedia => 'Multimedia';

	/// en: 'Consumer'
	String get consumer => 'Consumer';

	/// en: 'Combination Keys'
	String get combinationKeys => 'Combination Keys';

	/// en: 'Letter & Symbol & Number keys'
	String get letterSymbolNumberKeys => 'Letter & Symbol & Number keys';

	/// en: 'Numeric Keypad Keys'
	String get numericKeypadKeys => 'Numeric Keypad Keys';

	/// en: 'No Macros Configured'
	String get noMacrosConfigured => 'No Macros Configured';
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

	/// en: 'Done'
	String get done => 'Done';

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

	/// en: 'Back'
	String get back => 'Back';
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

	/// en: 'DPI Settings'
	String get dpiSettings => 'DPI Settings';

	/// en: 'Configure sensitivity stages, color identifiers, and active levels'
	String get dpiSettingsSubtitle => 'Configure sensitivity stages, color identifiers, and active levels';

	/// en: 'Polling Rate'
	String get reportRate => 'Polling Rate';

	/// en: 'Choose how frequently the mouse reports data to your computer'
	String get reportRateSubtitle => 'Choose how frequently the mouse reports data to your computer';

	/// en: 'Levels'
	String get levels => 'Levels';

	/// en: 'DPI {level}'
	String dpiLevel({required Object level}) => 'DPI ${level}';

	/// en: 'DPI stage color'
	String get dpiStageColor => 'DPI stage color';

	/// en: 'Add Stage'
	String get addStage => 'Add Stage';

	/// en: 'Remove Stage'
	String get removeStage => 'Remove Stage';

	/// en: 'Delete DPI stage {level}'
	String deleteStage({required Object level}) => 'Delete DPI stage ${level}';
}

// Path: parameter
class Translations$parameter$en {
	Translations$parameter$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Sensor features'
	String get sensorFeature => 'Sensor features';

	/// en: 'Advanced optical sensor tuning and calibration'
	String get sensorFeatureSubtitle => 'Advanced optical sensor tuning and calibration';

	/// en: 'Device features'
	String get otherFeature => 'Device features';

	/// en: 'Response times, power management and mechanics'
	String get otherFeatureSubtitle => 'Response times, power management and mechanics';

	/// en: 'Ripple Control'
	String get rippleControl => 'Ripple Control';

	/// en: 'Smooths micro-movements to reduce cursor jitter at high DPI.'
	String get rippleControlDesc => 'Smooths micro-movements to reduce cursor jitter at high DPI.';

	/// en: 'Angle Snap'
	String get angleSnap => 'Angle Snap';

	/// en: 'Locks horizontal or vertical lines to clean straight axes.'
	String get angleSnapDesc => 'Locks horizontal or vertical lines to clean straight axes.';

	/// en: 'Lift-Off Distance'
	String get lod => 'Lift-Off Distance';

	/// en: 'Sensor cut-off tracking height when the mouse is lifted.'
	String get lodDesc => 'Sensor cut-off tracking height when the mouse is lifted.';

	/// en: 'Angle Snapping & Tune'
	String get angleTune => 'Angle Snapping & Tune';

	/// en: 'Rotates tracking coordinate axis to match hand grip tilt.'
	String get angleTuneDesc => 'Rotates tracking coordinate axis to match hand grip tilt.';

	/// en: 'Decrease angle'
	String get decreaseAngle => 'Decrease angle';

	/// en: 'Increase angle'
	String get increaseAngle => 'Increase angle';

	/// en: 'Performance Mode'
	String get performance => 'Performance Mode';

	/// en: 'Balances sensor frame-rate between maximum responsiveness and battery endurance.'
	String get performanceDesc => 'Balances sensor frame-rate between maximum responsiveness and battery endurance.';

	/// en: 'Low Performance (Eco)'
	String get performanceEco => 'Low Performance (Eco)';

	/// en: 'Office Mouse'
	String get performanceOffice => 'Office Mouse';

	/// en: 'High Performance (Gaming)'
	String get performanceGaming => 'High Performance (Gaming)';

	/// en: 'Mode {wire}'
	String performanceMode({required Object wire}) => 'Mode ${wire}';

	/// en: 'Button debounce delay'
	String get debounce => 'Button debounce delay';

	/// en: 'Filters out unintended double-clicks caused by mechanical contact bounce.'
	String get debounceDesc => 'Filters out unintended double-clicks caused by mechanical contact bounce.';

	/// en: 'Wheel direction'
	String get wheelDirection => 'Wheel direction';

	/// en: 'Inverts scroll direction to match your personal preference.'
	String get wheelDirectionDesc => 'Inverts scroll direction to match your personal preference.';

	/// en: 'Forward (Standard)'
	String get wheelForward => 'Forward (Standard)';

	/// en: 'Reverse (Inverted)'
	String get wheelReverse => 'Reverse (Inverted)';

	/// en: 'Sleep timer'
	String get sleepTimer => 'Sleep timer';

	/// en: 'Inactivity timeout before entering ultra-low power standby mode.'
	String get sleepTimerDesc => 'Inactivity timeout before entering ultra-low power standby mode.';
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

	/// en: 'Select dynamic lighting pattern or static illumination effect'
	String get modeDesc => 'Select dynamic lighting pattern or static illumination effect';

	/// en: 'Select Mode'
	String get selectModeHint => 'Select Mode';

	/// en: 'Color'
	String get color => 'Color';

	/// en: 'Fine-tune static color saturation, hue, and brightness'
	String get colorDescEnabled => 'Fine-tune static color saturation, hue, and brightness';

	/// en: 'Selected mode manages colors automatically'
	String get colorDescDisabled => 'Selected mode manages colors automatically';

	/// en: 'Brightness'
	String get brightness => 'Brightness';

	/// en: 'Adjust the luminous intensity of the backlight LEDs.'
	String get brightnessDesc => 'Adjust the luminous intensity of the backlight LEDs.';

	/// en: 'Speed'
	String get speed => 'Speed';

	/// en: 'Adjust the animation cycle velocity for active dynamic effects.'
	String get speedDesc => 'Adjust the animation cycle velocity for active dynamic effects.';

	/// en: 'Power saving'
	String get powerSaving => 'Power saving';

	/// en: 'Inactivity timeout before turning off lighting to preserve battery.'
	String get powerSavingDesc => 'Inactivity timeout before turning off lighting to preserve battery.';

	late final Translations$backlight$modes$en modes = Translations$backlight$modes$en.internal(_root);
}

// Path: actions
class Translations$actions$en {
	Translations$actions$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Left Button'
	String get left => 'Left Button';

	/// en: 'Right Button'
	String get right => 'Right Button';

	/// en: 'Middle Button'
	String get middle => 'Middle Button';

	/// en: 'Forward Button'
	String get forward => 'Forward Button';

	/// en: 'Backward Button'
	String get backward => 'Backward Button';

	/// en: 'DPI Cycle'
	String get dpiCycle => 'DPI Cycle';

	/// en: 'Button {id}'
	String button({required Object id}) => 'Button ${id}';

	/// en: 'Disable'
	String get disable => 'Disable';

	/// en: 'Button off'
	String get buttonOff => 'Button off';

	/// en: 'Left Button'
	String get leftClick => 'Left Button';

	/// en: 'Right Button'
	String get rightClick => 'Right Button';

	/// en: 'Middle Button'
	String get middleClick => 'Middle Button';

	/// en: 'Wheel Up'
	String get scrollUp => 'Wheel Up';

	/// en: 'Wheel Down'
	String get scrollDown => 'Wheel Down';

	/// en: 'Wheel Up'
	String get wheelUp => 'Wheel Up';

	/// en: 'Wheel Down'
	String get wheelDown => 'Wheel Down';

	/// en: 'Tilt Left'
	String get tiltLeft => 'Tilt Left';

	/// en: 'Tilt Right'
	String get tiltRight => 'Tilt Right';

	/// en: 'Tilt Left'
	String get swingLeft => 'Tilt Left';

	/// en: 'Tilt Right'
	String get swingRight => 'Tilt Right';

	/// en: 'DPI +'
	String get dpiIncrease => 'DPI +';

	/// en: 'DPI -'
	String get dpiDecrease => 'DPI -';

	/// en: 'DPI +'
	String get dpiUp => 'DPI +';

	/// en: 'DPI -'
	String get dpiDown => 'DPI -';

	/// en: 'Report Rate Cycle'
	String get reportRate => 'Report Rate Cycle';

	/// en: 'Report Rate Cycle'
	String get reportRateCycle => 'Report Rate Cycle';

	/// en: 'Profile Cycle'
	String get profileCycle => 'Profile Cycle';

	/// en: 'Sniper'
	String get sniper => 'Sniper';

	/// en: 'Macro play (#{id})'
	String macroPlay({required Object id}) => 'Macro play (#${id})';

	/// en: 'Volume Up'
	String get volumeUp => 'Volume Up';

	/// en: 'Volume Down'
	String get volumeDown => 'Volume Down';

	/// en: 'Volume Mute'
	String get volumeMute => 'Volume Mute';

	/// en: 'Next Track'
	String get nextTrack => 'Next Track';

	/// en: 'Previous Track'
	String get prevTrack => 'Previous Track';

	/// en: 'Stop'
	String get stop => 'Stop';

	/// en: 'Play / Pause'
	String get playPause => 'Play / Pause';

	/// en: 'Web Search'
	String get webSearch => 'Web Search';

	/// en: 'Web Home'
	String get webHome => 'Web Home';

	/// en: 'Web Back'
	String get webBack => 'Web Back';

	/// en: 'Web Forward'
	String get webForward => 'Web Forward';

	/// en: 'Web Stop'
	String get webStop => 'Web Stop';

	/// en: 'Web Refresh'
	String get webRefresh => 'Web Refresh';

	/// en: 'Web Favourite'
	String get webFavourite => 'Web Favourite';

	/// en: 'Media Player'
	String get mediaPlayer => 'Media Player';

	/// en: 'Email'
	String get email => 'Email';

	/// en: 'Calculator'
	String get calculator => 'Calculator';

	/// en: 'My Computer'
	String get myComputer => 'My Computer';

	/// en: 'Left Alt'
	String get leftAlt => 'Left Alt';

	/// en: 'Left Ctrl'
	String get leftCtrl => 'Left Ctrl';

	/// en: 'Left Win'
	String get leftWin => 'Left Win';

	/// en: 'Left Shift'
	String get leftShift => 'Left Shift';

	/// en: 'Right Alt'
	String get rightAlt => 'Right Alt';

	/// en: 'Right Ctrl'
	String get rightCtrl => 'Right Ctrl';

	/// en: 'Right Win'
	String get rightWin => 'Right Win';

	/// en: 'Right Shift'
	String get rightShift => 'Right Shift';

	/// en: 'Any key'
	String get anyKey => 'Any key';
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

	/// en: 'Current Version'
	String get currentVersion => 'Current Version';

	/// en: 'Latest version'
	String get latestVersion => 'Latest version';

	/// en: 'Check for Updates'
	String get checkForUpdates => 'Check for Updates';

	/// en: 'Check updates'
	String get checkUpdates => 'Check updates';

	/// en: 'Update Firmware'
	String get updateFirmware => 'Update Firmware';

	/// en: 'New version & update'
	String get newVersionUpdate => 'New version & update';

	/// en: 'Reset to Default'
	String get resetToDefault => 'Reset to Default';
}

// Path: macro
class Translations$macro$en {
	Translations$macro$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Macro List'
	String get macroList => 'Macro List';

	/// en: 'Macro Name'
	String get macroName => 'Macro Name';

	/// en: 'New Macro'
	String get newMacro => 'New Macro';

	/// en: 'Delete Macro'
	String get deleteMacro => 'Delete Macro';

	/// en: 'Macro type'
	String get macroType => 'Macro type';

	/// en: 'Loop count'
	String get loopCount => 'Loop count';

	/// en: 'Key Delay Mode'
	String get keyDelayMode => 'Key Delay Mode';

	/// en: 'Recorded Delay'
	String get recordedDelay => 'Recorded Delay';

	/// en: 'Fixed Delay'
	String get fixedDelay => 'Fixed Delay';

	/// en: 'Fixed Delay (ms)'
	String get fixedDelayMs => 'Fixed Delay (ms)';

	/// en: 'Start Recording'
	String get startRecording => 'Start Recording';

	/// en: 'Stop Recording'
	String get stopRecording => 'Stop Recording';

	/// en: 'Record'
	String get record => 'Record';

	/// en: 'Recording — press keys…'
	String get recordingInProgress => 'Recording — press keys…';

	/// en: 'No events recorded'
	String get noEventsRecorded => 'No events recorded';

	/// en: 'Reset'
	String get reset => 'Reset';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'No macros configured'
	String get noMacrosConfigured => 'No macros configured';

	/// en: 'Create a macro to record key sequences and mouse actions.'
	String get noMacrosConfiguredDesc => 'Create a macro to record key sequences and mouse actions.';

	/// en: 'Create Macro'
	String get createMacro => 'Create Macro';

	/// en: 'Please select a shortcut to edit'
	String get selectShortcutEdit => 'Please select a shortcut to edit';

	/// en: 'Choose a macro from the sidebar list or create a new one.'
	String get selectShortcutEditDesc => 'Choose a macro from the sidebar list or create a new one.';

	/// en: 'Wheel'
	String get wheel => 'Wheel';

	/// en: 'KeyDown'
	String get keyDown => 'KeyDown';

	/// en: 'KeyUp'
	String get keyUp => 'KeyUp';

	/// en: 'Remove Action'
	String get removeAction => 'Remove Action';

	/// en: 'Macro saved successfully'
	String get savedSuccess => 'Macro saved successfully';

	/// en: 'Macro failed to save'
	String get savedFailed => 'Macro failed to save';

	late final Translations$macro$modes$en modes = Translations$macro$modes$en.internal(_root);
}

// Path: appSettings
class Translations$appSettings$en {
	Translations$appSettings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'App Setting'
	String get appSetting => 'App Setting';

	/// en: 'System'
	String get system => 'System';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Theme'
	String get theme => 'Theme';

	/// en: 'Help'
	String get help => 'Help';

	/// en: 'FAQ'
	String get faq => 'FAQ';

	/// en: 'Customer Service'
	String get customerService => 'Customer Service';

	/// en: 'Key Test'
	String get keyTest => 'Key Test';

	/// en: 'Product Manual'
	String get productManual => 'Product Manual';

	/// en: 'Driver Bug Feedback'
	String get driverBugFeedback => 'Driver Bug Feedback';

	/// en: 'NEWMEN HUB Communities'
	String get communities => 'NEWMEN HUB Communities';

	/// en: 'Performance Settings'
	String get performanceSettings => 'Performance Settings';

	/// en: 'Low Battery Alert Threshold'
	String get lowBatteryThreshold => 'Low Battery Alert Threshold';

	/// en: 'About NEWMEN HUB'
	String get about => 'About NEWMEN HUB';

	/// en: 'Current Version: {version}'
	String currentVersion({required Object version}) => 'Current Version: ${version}';

	/// en: 'Official Website: {url}'
	String officialWebsite({required Object url}) => 'Official Website: ${url}';
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

// Path: backlight.modes
class Translations$backlight$modes$en {
	Translations$backlight$modes$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Constant'
	String get constant => 'Constant';

	/// en: 'Single breathing'
	String get singleBreathing => 'Single breathing';

	/// en: 'Multi breathing'
	String get multiBreathing => 'Multi breathing';

	/// en: 'Cycle'
	String get cycle => 'Cycle';

	/// en: 'Running'
	String get running => 'Running';

	/// en: 'Off'
	String get off => 'Off';
}

// Path: macro.modes
class Translations$macro$modes$en {
	Translations$macro$modes$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Loop'
	String get loop => 'Loop';

	/// en: 'Stop on any key or mouse click'
	String get stopOnAnyKey => 'Stop on any key or mouse click';

	/// en: 'Play on hold'
	String get playOnHold => 'Play on hold';
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
			'devices.deviceStatus' => 'Device status',
			'devices.batteryLow' => ({required Object deviceName}) => '${deviceName}: battery low',
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
			'sidebar.back' => 'Back',
			'windowControls.minimize' => 'Minimize',
			'windowControls.maximize' => 'Maximize',
			'windowControls.restore' => 'Restore',
			'windowControls.close' => 'Close',
			'mapping.mouse' => 'Mouse',
			'mapping.keyboard' => 'Keyboard',
			'mapping.special' => 'Special',
			'mapping.macro' => 'Macro',
			'mapping.modifierKey' => 'Modifier key',
			'mapping.anyKey' => 'Any key',
			'mapping.mouseAction' => 'Mouse Action',
			'mapping.mouseWheelAction' => 'Mouse Wheel Action',
			'mapping.multimedia' => 'Multimedia',
			'mapping.consumer' => 'Consumer',
			'mapping.combinationKeys' => 'Combination Keys',
			'mapping.letterSymbolNumberKeys' => 'Letter & Symbol & Number keys',
			'mapping.numericKeypadKeys' => 'Numeric Keypad Keys',
			'mapping.noMacrosConfigured' => 'No Macros Configured',
			'common.save' => 'Save',
			'common.cancel' => 'Cancel',
			'common.confirm' => 'Confirm',
			'common.done' => 'Done',
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
			'common.back' => 'Back',
			'mouseCanvas.imageMissing' => 'Mouse image missing',
			'mouseCanvas.restoreDefaultKeysTip' => 'Are you sure you want to restore default keys?',
			'performance.dpiSettings' => 'DPI Settings',
			'performance.dpiSettingsSubtitle' => 'Configure sensitivity stages, color identifiers, and active levels',
			'performance.reportRate' => 'Polling Rate',
			'performance.reportRateSubtitle' => 'Choose how frequently the mouse reports data to your computer',
			'performance.levels' => 'Levels',
			'performance.dpiLevel' => ({required Object level}) => 'DPI ${level}',
			'performance.dpiStageColor' => 'DPI stage color',
			'performance.addStage' => 'Add Stage',
			'performance.removeStage' => 'Remove Stage',
			'performance.deleteStage' => ({required Object level}) => 'Delete DPI stage ${level}',
			'parameter.sensorFeature' => 'Sensor features',
			'parameter.sensorFeatureSubtitle' => 'Advanced optical sensor tuning and calibration',
			'parameter.otherFeature' => 'Device features',
			'parameter.otherFeatureSubtitle' => 'Response times, power management and mechanics',
			'parameter.rippleControl' => 'Ripple Control',
			'parameter.rippleControlDesc' => 'Smooths micro-movements to reduce cursor jitter at high DPI.',
			'parameter.angleSnap' => 'Angle Snap',
			'parameter.angleSnapDesc' => 'Locks horizontal or vertical lines to clean straight axes.',
			'parameter.lod' => 'Lift-Off Distance',
			'parameter.lodDesc' => 'Sensor cut-off tracking height when the mouse is lifted.',
			'parameter.angleTune' => 'Angle Snapping & Tune',
			'parameter.angleTuneDesc' => 'Rotates tracking coordinate axis to match hand grip tilt.',
			'parameter.decreaseAngle' => 'Decrease angle',
			'parameter.increaseAngle' => 'Increase angle',
			'parameter.performance' => 'Performance Mode',
			'parameter.performanceDesc' => 'Balances sensor frame-rate between maximum responsiveness and battery endurance.',
			'parameter.performanceEco' => 'Low Performance (Eco)',
			'parameter.performanceOffice' => 'Office Mouse',
			'parameter.performanceGaming' => 'High Performance (Gaming)',
			'parameter.performanceMode' => ({required Object wire}) => 'Mode ${wire}',
			'parameter.debounce' => 'Button debounce delay',
			'parameter.debounceDesc' => 'Filters out unintended double-clicks caused by mechanical contact bounce.',
			'parameter.wheelDirection' => 'Wheel direction',
			'parameter.wheelDirectionDesc' => 'Inverts scroll direction to match your personal preference.',
			'parameter.wheelForward' => 'Forward (Standard)',
			'parameter.wheelReverse' => 'Reverse (Inverted)',
			'parameter.sleepTimer' => 'Sleep timer',
			'parameter.sleepTimerDesc' => 'Inactivity timeout before entering ultra-low power standby mode.',
			'backlight.title' => 'Backlight',
			'backlight.mode' => 'Mode',
			'backlight.modeDesc' => 'Select dynamic lighting pattern or static illumination effect',
			'backlight.selectModeHint' => 'Select Mode',
			'backlight.color' => 'Color',
			'backlight.colorDescEnabled' => 'Fine-tune static color saturation, hue, and brightness',
			'backlight.colorDescDisabled' => 'Selected mode manages colors automatically',
			'backlight.brightness' => 'Brightness',
			'backlight.brightnessDesc' => 'Adjust the luminous intensity of the backlight LEDs.',
			'backlight.speed' => 'Speed',
			'backlight.speedDesc' => 'Adjust the animation cycle velocity for active dynamic effects.',
			'backlight.powerSaving' => 'Power saving',
			'backlight.powerSavingDesc' => 'Inactivity timeout before turning off lighting to preserve battery.',
			'backlight.modes.constant' => 'Constant',
			'backlight.modes.singleBreathing' => 'Single breathing',
			'backlight.modes.multiBreathing' => 'Multi breathing',
			'backlight.modes.cycle' => 'Cycle',
			'backlight.modes.running' => 'Running',
			'backlight.modes.off' => 'Off',
			'actions.left' => 'Left Button',
			'actions.right' => 'Right Button',
			'actions.middle' => 'Middle Button',
			'actions.forward' => 'Forward Button',
			'actions.backward' => 'Backward Button',
			'actions.dpiCycle' => 'DPI Cycle',
			'actions.button' => ({required Object id}) => 'Button ${id}',
			'actions.disable' => 'Disable',
			'actions.buttonOff' => 'Button off',
			'actions.leftClick' => 'Left Button',
			'actions.rightClick' => 'Right Button',
			'actions.middleClick' => 'Middle Button',
			'actions.scrollUp' => 'Wheel Up',
			'actions.scrollDown' => 'Wheel Down',
			'actions.wheelUp' => 'Wheel Up',
			'actions.wheelDown' => 'Wheel Down',
			'actions.tiltLeft' => 'Tilt Left',
			'actions.tiltRight' => 'Tilt Right',
			'actions.swingLeft' => 'Tilt Left',
			'actions.swingRight' => 'Tilt Right',
			'actions.dpiIncrease' => 'DPI +',
			'actions.dpiDecrease' => 'DPI -',
			'actions.dpiUp' => 'DPI +',
			'actions.dpiDown' => 'DPI -',
			'actions.reportRate' => 'Report Rate Cycle',
			'actions.reportRateCycle' => 'Report Rate Cycle',
			'actions.profileCycle' => 'Profile Cycle',
			'actions.sniper' => 'Sniper',
			'actions.macroPlay' => ({required Object id}) => 'Macro play (#${id})',
			'actions.volumeUp' => 'Volume Up',
			'actions.volumeDown' => 'Volume Down',
			'actions.volumeMute' => 'Volume Mute',
			'actions.nextTrack' => 'Next Track',
			'actions.prevTrack' => 'Previous Track',
			'actions.stop' => 'Stop',
			'actions.playPause' => 'Play / Pause',
			'actions.webSearch' => 'Web Search',
			'actions.webHome' => 'Web Home',
			'actions.webBack' => 'Web Back',
			'actions.webForward' => 'Web Forward',
			'actions.webStop' => 'Web Stop',
			'actions.webRefresh' => 'Web Refresh',
			'actions.webFavourite' => 'Web Favourite',
			'actions.mediaPlayer' => 'Media Player',
			'actions.email' => 'Email',
			'actions.calculator' => 'Calculator',
			'actions.myComputer' => 'My Computer',
			'actions.leftAlt' => 'Left Alt',
			'actions.leftCtrl' => 'Left Ctrl',
			'actions.leftWin' => 'Left Win',
			'actions.leftShift' => 'Left Shift',
			'actions.rightAlt' => 'Right Alt',
			'actions.rightCtrl' => 'Right Ctrl',
			'actions.rightWin' => 'Right Win',
			'actions.rightShift' => 'Right Shift',
			'actions.anyKey' => 'Any key',
			'deviceSetting.mouseFirmwareVersion' => 'Mouse Firmware Version',
			'deviceSetting.dongleFirmwareVersion' => 'Dongle Firmware Version',
			'deviceSetting.currentVersion' => 'Current Version',
			'deviceSetting.latestVersion' => 'Latest version',
			'deviceSetting.checkForUpdates' => 'Check for Updates',
			'deviceSetting.checkUpdates' => 'Check updates',
			'deviceSetting.updateFirmware' => 'Update Firmware',
			'deviceSetting.newVersionUpdate' => 'New version & update',
			'deviceSetting.resetToDefault' => 'Reset to Default',
			'macro.macroList' => 'Macro List',
			'macro.macroName' => 'Macro Name',
			'macro.newMacro' => 'New Macro',
			'macro.deleteMacro' => 'Delete Macro',
			'macro.macroType' => 'Macro type',
			'macro.loopCount' => 'Loop count',
			'macro.keyDelayMode' => 'Key Delay Mode',
			'macro.recordedDelay' => 'Recorded Delay',
			'macro.fixedDelay' => 'Fixed Delay',
			'macro.fixedDelayMs' => 'Fixed Delay (ms)',
			'macro.startRecording' => 'Start Recording',
			'macro.stopRecording' => 'Stop Recording',
			'macro.record' => 'Record',
			'macro.recordingInProgress' => 'Recording — press keys…',
			'macro.noEventsRecorded' => 'No events recorded',
			'macro.reset' => 'Reset',
			'macro.save' => 'Save',
			'macro.cancel' => 'Cancel',
			'macro.noMacrosConfigured' => 'No macros configured',
			'macro.noMacrosConfiguredDesc' => 'Create a macro to record key sequences and mouse actions.',
			'macro.createMacro' => 'Create Macro',
			'macro.selectShortcutEdit' => 'Please select a shortcut to edit',
			'macro.selectShortcutEditDesc' => 'Choose a macro from the sidebar list or create a new one.',
			'macro.wheel' => 'Wheel',
			'macro.keyDown' => 'KeyDown',
			'macro.keyUp' => 'KeyUp',
			'macro.removeAction' => 'Remove Action',
			'macro.savedSuccess' => 'Macro saved successfully',
			'macro.savedFailed' => 'Macro failed to save',
			'macro.modes.loop' => 'Loop',
			'macro.modes.stopOnAnyKey' => 'Stop on any key or mouse click',
			'macro.modes.playOnHold' => 'Play on hold',
			'appSettings.appSetting' => 'App Setting',
			'appSettings.system' => 'System',
			'appSettings.language' => 'Language',
			'appSettings.theme' => 'Theme',
			'appSettings.help' => 'Help',
			'appSettings.faq' => 'FAQ',
			'appSettings.customerService' => 'Customer Service',
			'appSettings.keyTest' => 'Key Test',
			'appSettings.productManual' => 'Product Manual',
			'appSettings.driverBugFeedback' => 'Driver Bug Feedback',
			'appSettings.communities' => 'NEWMEN HUB Communities',
			'appSettings.performanceSettings' => 'Performance Settings',
			'appSettings.lowBatteryThreshold' => 'Low Battery Alert Threshold',
			'appSettings.about' => 'About NEWMEN HUB',
			'appSettings.currentVersion' => ({required Object version}) => 'Current Version: ${version}',
			'appSettings.officialWebsite' => ({required Object url}) => 'Official Website: ${url}',
			_ => null,
		};
	}
}
