///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsZh extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZh({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zh,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsZh _root = this; // ignore: unused_field

	@override 
	TranslationsZh $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZh(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$views$zh views = _Translations$views$zh._(_root);
	@override late final _Translations$devices$zh devices = _Translations$devices$zh._(_root);
	@override late final _Translations$sidebar$zh sidebar = _Translations$sidebar$zh._(_root);
	@override late final _Translations$mapping$zh mapping = _Translations$mapping$zh._(_root);
	@override late final _Translations$common$zh common = _Translations$common$zh._(_root);
	@override late final _Translations$mouseCanvas$zh mouseCanvas = _Translations$mouseCanvas$zh._(_root);
	@override late final _Translations$performance$zh performance = _Translations$performance$zh._(_root);
	@override late final _Translations$parameter$zh parameter = _Translations$parameter$zh._(_root);
	@override late final _Translations$backlight$zh backlight = _Translations$backlight$zh._(_root);
	@override late final _Translations$actions$zh actions = _Translations$actions$zh._(_root);
	@override late final _Translations$deviceSetting$zh deviceSetting = _Translations$deviceSetting$zh._(_root);
	@override late final _Translations$macro$zh macro = _Translations$macro$zh._(_root);
}

// Path: views
class _Translations$views$zh extends Translations$views$en {
	_Translations$views$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override late final _Translations$views$login$zh login = _Translations$views$login$zh._(_root);
	@override late final _Translations$views$home$zh home = _Translations$views$home$zh._(_root);
}

// Path: devices
class _Translations$devices$zh extends Translations$devices$en {
	_Translations$devices$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get addDevice => '添加设备';
	@override String get working => '工作中...';
	@override String get bluetoothWarning => '该驱动程序无法识别蓝牙连接。请使用 2.4G 接收器或电缆连接';
	@override String get noDevices => '未发现设备';
}

// Path: sidebar
class _Translations$sidebar$zh extends Translations$sidebar$en {
	_Translations$sidebar$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get buttonMapping => '按键映射';
	@override String get macroSetting => '宏设置';
	@override String get performanceSetting => '性能设置';
	@override String get parameterSetting => '参数设置';
	@override String get backlightSetting => '背光设置';
	@override String get profileManagement => '配置文件管理';
	@override String get deviceSetting => '设备设置';
	@override String get mouse => '鼠标';
	@override String batteryLabel({required Object pct}) => '电量 ${pct}%';
	@override String batteryCharging({required Object pct}) => '电量 ${pct}% 充电中';
	@override String get batteryEmpty => '电量 —';
}

// Path: mapping
class _Translations$mapping$zh extends Translations$mapping$en {
	_Translations$mapping$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get mouse => '鼠标';
	@override String get keyboard => '键盘';
	@override String get special => '特殊键';
	@override String get macro => '宏';
	@override String get modifierKey => '修饰键';
}

// Path: common
class _Translations$common$zh extends Translations$common$en {
	_Translations$common$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get save => '保存';
	@override String get cancel => '取消';
	@override String get confirm => '确认';
	@override String get resetToDefault => '恢复默认';
	@override String get tip => '提示';
	@override String get settings => '设置';
	@override String get language => '语言';
	@override String get lightMode => '浅色模式';
	@override String get darkMode => '深色模式';
	@override String get switchToLightMode => '切换到浅色模式';
	@override String get switchToDarkMode => '切换到深色模式';
	@override String get forward => '向前';
	@override String get reverse => '反向';
	@override String secondsUnit({required Object seconds}) => '${seconds} 秒';
	@override String get done => '完成';
}

// Path: mouseCanvas
class _Translations$mouseCanvas$zh extends Translations$mouseCanvas$en {
	_Translations$mouseCanvas$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get imageMissing => '鼠标图片缺失';
	@override String get restoreDefaultKeysTip => '您确定要恢复默认按键吗？';
}

// Path: performance
class _Translations$performance$zh extends Translations$performance$en {
	_Translations$performance$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get dpiSettings => 'DPI 设置';
	@override String get reportRate => '回报率';
	@override String get levels => '档位';
	@override String dpiLevel({required Object level}) => 'DPI ${level}';
	@override String get dpiStageColor => 'DPI 档位颜色';
}

// Path: parameter
class _Translations$parameter$zh extends Translations$parameter$en {
	_Translations$parameter$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get sensorFeature => '传感器功能';
	@override String get otherFeature => '其他功能';
	@override String get rippleControl => '平滑控制';
	@override String get angleSnap => '角度微调';
	@override String get lod => '静默高度 (LOD)';
	@override String get angleTune => '角度调整';
	@override String get performance => '性能';
	@override String get wheelDirection => '滚轮方向';
}

// Path: backlight
class _Translations$backlight$zh extends Translations$backlight$en {
	_Translations$backlight$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '背光';
	@override String get mode => '模式';
	@override String get color => '颜色';
	@override String get powerSaving => '省电';
}

// Path: actions
class _Translations$actions$zh extends Translations$actions$en {
	_Translations$actions$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get left => '左键';
	@override String get right => '右键';
	@override String get middle => '中键';
	@override String get forward => '前进';
	@override String get backward => '后退';
	@override String get dpiCycle => 'DPI 循环';
	@override String button({required Object id}) => '按键 ${id}';
	@override String get disable => '禁用 / 无操作';
	@override String get buttonOff => '关闭按键';
	@override String get leftClick => '左键单击';
	@override String get rightClick => '右键单击';
	@override String get middleClick => '中键单击';
	@override String get scrollUp => '向上滚动';
	@override String get scrollDown => '向下滚动';
	@override String get swingLeft => '向左摇摆';
	@override String get swingRight => '向右摇摆';
	@override String get dpiIncrease => '增加 DPI';
	@override String get dpiDecrease => '减少 DPI';
	@override String get reportRate => '回报率';
	@override String get profileCycle => '配置文件循环';
	@override String get sniper => '狙击键';
	@override String macroPlay({required Object id}) => '宏播放 (#${id})';
}

// Path: deviceSetting
class _Translations$deviceSetting$zh extends Translations$deviceSetting$en {
	_Translations$deviceSetting$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get mouseFirmwareVersion => '鼠标固件版本';
	@override String get dongleFirmwareVersion => '接收器固件版本';
	@override String get latestVersion => '最新版本';
	@override String get checkUpdates => '检查更新';
	@override String get newVersionUpdate => '新版本与更新';
}

// Path: macro
class _Translations$macro$zh extends Translations$macro$en {
	_Translations$macro$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get startRecording => '开始录制';
	@override String get stopRecording => '停止录制';
	@override String get record => '录制';
	@override String get reset => '重置';
	@override String get noMacrosConfigured => '未配置宏';
	@override String get createMacro => '创建宏';
	@override String get selectShortcutEdit => '请选择要编辑的快捷键';
	@override String get newMacro => '新建宏';
}

// Path: views.login
class _Translations$views$login$zh extends Translations$views$login$en {
	_Translations$views$login$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get welcome => '欢迎';
	@override String get userName => '用户名';
	@override String get loginButton => '登录';
}

// Path: views.home
class _Translations$views$home$zh extends Translations$views$home$en {
	_Translations$views$home$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String greeting({required Object userName}) => '你好，${userName}！';
}

/// The flat map containing all translations for locale <zh>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZh {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'views.login.welcome' => '欢迎',
			'views.login.userName' => '用户名',
			'views.login.loginButton' => '登录',
			'views.home.greeting' => ({required Object userName}) => '你好，${userName}！',
			'devices.addDevice' => '添加设备',
			'devices.working' => '工作中...',
			'devices.bluetoothWarning' => '该驱动程序无法识别蓝牙连接。请使用 2.4G 接收器或电缆连接',
			'devices.noDevices' => '未发现设备',
			'sidebar.buttonMapping' => '按键映射',
			'sidebar.macroSetting' => '宏设置',
			'sidebar.performanceSetting' => '性能设置',
			'sidebar.parameterSetting' => '参数设置',
			'sidebar.backlightSetting' => '背光设置',
			'sidebar.profileManagement' => '配置文件管理',
			'sidebar.deviceSetting' => '设备设置',
			'sidebar.mouse' => '鼠标',
			'sidebar.batteryLabel' => ({required Object pct}) => '电量 ${pct}%',
			'sidebar.batteryCharging' => ({required Object pct}) => '电量 ${pct}% 充电中',
			'sidebar.batteryEmpty' => '电量 —',
			'mapping.mouse' => '鼠标',
			'mapping.keyboard' => '键盘',
			'mapping.special' => '特殊键',
			'mapping.macro' => '宏',
			'mapping.modifierKey' => '修饰键',
			'common.save' => '保存',
			'common.cancel' => '取消',
			'common.confirm' => '确认',
			'common.resetToDefault' => '恢复默认',
			'common.tip' => '提示',
			'common.settings' => '设置',
			'common.language' => '语言',
			'common.lightMode' => '浅色模式',
			'common.darkMode' => '深色模式',
			'common.switchToLightMode' => '切换到浅色模式',
			'common.switchToDarkMode' => '切换到深色模式',
			'common.forward' => '向前',
			'common.reverse' => '反向',
			'common.secondsUnit' => ({required Object seconds}) => '${seconds} 秒',
			'common.done' => '完成',
			'mouseCanvas.imageMissing' => '鼠标图片缺失',
			'mouseCanvas.restoreDefaultKeysTip' => '您确定要恢复默认按键吗？',
			'performance.dpiSettings' => 'DPI 设置',
			'performance.reportRate' => '回报率',
			'performance.levels' => '档位',
			'performance.dpiLevel' => ({required Object level}) => 'DPI ${level}',
			'performance.dpiStageColor' => 'DPI 档位颜色',
			'parameter.sensorFeature' => '传感器功能',
			'parameter.otherFeature' => '其他功能',
			'parameter.rippleControl' => '平滑控制',
			'parameter.angleSnap' => '角度微调',
			'parameter.lod' => '静默高度 (LOD)',
			'parameter.angleTune' => '角度调整',
			'parameter.performance' => '性能',
			'parameter.wheelDirection' => '滚轮方向',
			'backlight.title' => '背光',
			'backlight.mode' => '模式',
			'backlight.color' => '颜色',
			'backlight.powerSaving' => '省电',
			'actions.left' => '左键',
			'actions.right' => '右键',
			'actions.middle' => '中键',
			'actions.forward' => '前进',
			'actions.backward' => '后退',
			'actions.dpiCycle' => 'DPI 循环',
			'actions.button' => ({required Object id}) => '按键 ${id}',
			'actions.disable' => '禁用 / 无操作',
			'actions.buttonOff' => '关闭按键',
			'actions.leftClick' => '左键单击',
			'actions.rightClick' => '右键单击',
			'actions.middleClick' => '中键单击',
			'actions.scrollUp' => '向上滚动',
			'actions.scrollDown' => '向下滚动',
			'actions.swingLeft' => '向左摇摆',
			'actions.swingRight' => '向右摇摆',
			'actions.dpiIncrease' => '增加 DPI',
			'actions.dpiDecrease' => '减少 DPI',
			'actions.reportRate' => '回报率',
			'actions.profileCycle' => '配置文件循环',
			'actions.sniper' => '狙击键',
			'actions.macroPlay' => ({required Object id}) => '宏播放 (#${id})',
			'deviceSetting.mouseFirmwareVersion' => '鼠标固件版本',
			'deviceSetting.dongleFirmwareVersion' => '接收器固件版本',
			'deviceSetting.latestVersion' => '最新版本',
			'deviceSetting.checkUpdates' => '检查更新',
			'deviceSetting.newVersionUpdate' => '新版本与更新',
			'macro.startRecording' => '开始录制',
			'macro.stopRecording' => '停止录制',
			'macro.record' => '录制',
			'macro.reset' => '重置',
			'macro.noMacrosConfigured' => '未配置宏',
			'macro.createMacro' => '创建宏',
			'macro.selectShortcutEdit' => '请选择要编辑的快捷键',
			'macro.newMacro' => '新建宏',
			_ => null,
		};
	}
}
