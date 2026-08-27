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
	@override late final _Translations$windowControls$zh windowControls = _Translations$windowControls$zh._(_root);
	@override late final _Translations$mapping$zh mapping = _Translations$mapping$zh._(_root);
	@override late final _Translations$common$zh common = _Translations$common$zh._(_root);
	@override late final _Translations$mouseCanvas$zh mouseCanvas = _Translations$mouseCanvas$zh._(_root);
	@override late final _Translations$performance$zh performance = _Translations$performance$zh._(_root);
	@override late final _Translations$parameter$zh parameter = _Translations$parameter$zh._(_root);
	@override late final _Translations$backlight$zh backlight = _Translations$backlight$zh._(_root);
	@override late final _Translations$actions$zh actions = _Translations$actions$zh._(_root);
	@override late final _Translations$deviceSetting$zh deviceSetting = _Translations$deviceSetting$zh._(_root);
	@override late final _Translations$macro$zh macro = _Translations$macro$zh._(_root);
	@override late final _Translations$appSettings$zh appSettings = _Translations$appSettings$zh._(_root);
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
	@override String get deviceStatus => '设备状态';
	@override String batteryLow({required Object deviceName}) => '${deviceName}: 电量过低';
	@override String get sleeping => '休眠中';
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
	@override String get back => '返回';
}

// Path: windowControls
class _Translations$windowControls$zh extends Translations$windowControls$en {
	_Translations$windowControls$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get minimize => '最小化';
	@override String get maximize => '最大化';
	@override String get restore => '还原';
	@override String get close => '关闭';
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
	@override String get anyKey => '任意按键';
	@override String get mouseAction => '鼠标功能';
	@override String get mouseWheelAction => '滚轮功能';
	@override String get multimedia => '多媒体';
	@override String get consumer => '快捷功能';
	@override String get combinationKeys => '组合键';
	@override String get letterSymbolNumberKeys => '字母、符号和数字键';
	@override String get numericKeypadKeys => '小键盘按键';
	@override String get noMacrosConfigured => '未配置宏';
}

// Path: common
class _Translations$common$zh extends Translations$common$en {
	_Translations$common$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get save => '保存';
	@override String get cancel => '取消';
	@override String get confirm => '确认';
	@override String get done => '完成';
	@override String get resetToDefault => '恢复默认值';
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
	@override String get back => '返回';
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
	@override String get dpiSettingsSubtitle => '配置灵敏度档位、指示灯颜色及启用档位';
	@override String get reportRate => '回报率';
	@override String get reportRateSubtitle => '选择鼠标向计算机报告数据的频率';
	@override String get levels => '档位';
	@override String dpiLevel({required Object level}) => 'DPI ${level}';
	@override String get dpiStageColor => 'DPI 档位颜色';
	@override String get addStage => '添加档位';
	@override String get removeStage => '删除档位';
	@override String deleteStage({required Object level}) => '删除 DPI 档位 ${level}';
}

// Path: parameter
class _Translations$parameter$zh extends Translations$parameter$en {
	_Translations$parameter$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get sensorFeature => '传感器功能';
	@override String get sensorFeatureSubtitle => '高级光学传感器微调与校准';
	@override String get otherFeature => '设备功能';
	@override String get otherFeatureSubtitle => '响应时间、电源管理及机械设置';
	@override String get rippleControl => '平滑控制';
	@override String get rippleControlDesc => '平滑微小移动，减少高 DPI 下的光标抖动。';
	@override String get angleSnap => '直线修正';
	@override String get angleSnapDesc => '将水平或垂直移动锁定为直线。';
	@override String get lod => '静默高度 (LOD)';
	@override String get lodDesc => '抬起鼠标时传感器停止追踪的高度。';
	@override String get angleTune => '角度微调';
	@override String get angleTuneDesc => '旋转追踪坐标轴以匹配手握倾斜角度。';
	@override String get decreaseAngle => '减小角度';
	@override String get increaseAngle => '增大角度';
	@override String get performance => '性能模式';
	@override String get performanceDesc => '在最高响应速度和电池续航之间平衡传感器帧率。';
	@override String get performanceEco => '低功耗模式 (节能)';
	@override String get performanceOffice => '办公模式';
	@override String get performanceGaming => '高性能模式 (游戏)';
	@override String performanceMode({required Object wire}) => '模式 ${wire}';
	@override String get debounce => '按键防抖延迟';
	@override String get debounceDesc => '过滤机械触点抖动导致的意外双击。';
	@override String get wheelDirection => '滚轮方向';
	@override String get wheelDirectionDesc => '反转滚轮滚动方向以符合个人偏好。';
	@override String get wheelForward => '正向 (标准)';
	@override String get wheelReverse => '反向 (反转)';
	@override String get sleepTimer => '休眠时间';
	@override String get sleepTimerDesc => '进入超低功耗待机模式前的无操作超时时间。';
}

// Path: backlight
class _Translations$backlight$zh extends Translations$backlight$en {
	_Translations$backlight$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '背光';
	@override String get mode => '模式';
	@override String get modeDesc => '选择动态灯效模式或静态照明效果';
	@override String get selectModeHint => '选择模式';
	@override String get color => '颜色';
	@override String get colorDescEnabled => '微调静态颜色的饱和度、色调和亮度';
	@override String get colorDescDisabled => '所选模式自动管理灯光颜色';
	@override String get brightness => '亮度';
	@override String get brightnessDesc => '调节背光 LED 的发光强度。';
	@override String get speed => '速度';
	@override String get speedDesc => '调节动态灯效的动画变换速度。';
	@override String get powerSaving => '省电';
	@override String get powerSavingDesc => '关闭灯光以节省电量前的无操作超时时间。';
	@override String get colorCode => '颜色代码';
	@override late final _Translations$backlight$modes$zh modes = _Translations$backlight$modes$zh._(_root);
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
	@override String get disable => '禁用';
	@override String get buttonOff => '关闭按键';
	@override String get leftClick => '左键';
	@override String get rightClick => '右键';
	@override String get middleClick => '中键';
	@override String get scrollUp => '向上滚动';
	@override String get scrollDown => '向下滚动';
	@override String get wheelUp => '向上滚动';
	@override String get wheelDown => '向下滚动';
	@override String get tiltLeft => '向左摇摆';
	@override String get tiltRight => '向右摇摆';
	@override String get swingLeft => '向左摇摆';
	@override String get swingRight => '向右摇摆';
	@override String get dpiIncrease => 'DPI +';
	@override String get dpiDecrease => 'DPI -';
	@override String get dpiUp => 'DPI +';
	@override String get dpiDown => 'DPI -';
	@override String get reportRate => '回报率循环';
	@override String get reportRateCycle => '回报率循环';
	@override String get profileCycle => '配置文件循环';
	@override String get sniper => '狙击键';
	@override String macroPlay({required Object id}) => '宏播放 (#${id})';
	@override String get volumeUp => '音量增加';
	@override String get volumeDown => '音量减少';
	@override String get volumeMute => '静音';
	@override String get nextTrack => '下一首';
	@override String get prevTrack => '上一首';
	@override String get stop => '停止';
	@override String get playPause => '播放 / 暂停';
	@override String get webSearch => '网络搜索';
	@override String get webHome => '主页';
	@override String get webBack => '网页后退';
	@override String get webForward => '网页前进';
	@override String get webStop => '停止加载';
	@override String get webRefresh => '网页刷新';
	@override String get webFavourite => '收藏夹';
	@override String get mediaPlayer => '媒体播放器';
	@override String get email => '电子邮件';
	@override String get calculator => '计算器';
	@override String get myComputer => '我的电脑';
	@override String get leftAlt => '左 Alt';
	@override String get leftCtrl => '左 Ctrl';
	@override String get leftWin => '左 Win';
	@override String get leftShift => '左 Shift';
	@override String get rightAlt => '右 Alt';
	@override String get rightCtrl => '右 Ctrl';
	@override String get rightWin => '右 Win';
	@override String get rightShift => '右 Shift';
	@override String get anyKey => '任意按键';
	@override String get capsLock => '大写锁定';
	@override String get space => '空格';
	@override String get enter => '回车';
	@override String get esc => 'Esc';
	@override String get backspace => '退格';
	@override String get tab => 'Tab';
	@override String get insert => '插入 (Insert)';
	@override String get home => 'Home';
	@override String get pageUp => '向上翻页';
	@override String get pageDown => '向下翻页';
	@override String get delete => '删除 (Delete)';
	@override String get end => 'End';
	@override String get upArrow => '向上箭头';
	@override String get downArrow => '向下箭头';
	@override String get leftArrow => '向左箭头';
	@override String get rightArrow => '向右箭头';
	@override String get printScreen => '截屏 (Print Screen)';
	@override String get scrollLock => '滚动锁定';
	@override String get pause => '暂停 (Pause)';
	@override String get numLock => '数字锁定';
	@override String get numpadEnter => '小键盘回车';
	@override String get numpadDel => '小键盘删除';
	@override String get numpadAdd => '小键盘 +';
	@override String get numpadSub => '小键盘 -';
	@override String get numpadMul => '小键盘 *';
	@override String get numpadDiv => '小键盘 /';
	@override String get numpadEq => '小键盘 =';
	@override String get numpad0 => '小键盘 0';
	@override String get numpad1 => '小键盘 1';
	@override String get numpad2 => '小键盘 2';
	@override String get numpad3 => '小键盘 3';
	@override String get numpad4 => '小键盘 4';
	@override String get numpad5 => '小键盘 5';
	@override String get numpad6 => '小键盘 6';
	@override String get numpad7 => '小键盘 7';
	@override String get numpad8 => '小键盘 8';
	@override String get numpad9 => '小键盘 9';
}

// Path: deviceSetting
class _Translations$deviceSetting$zh extends Translations$deviceSetting$en {
	_Translations$deviceSetting$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get mouseFirmwareVersion => '鼠标固件版本';
	@override String get dongleFirmwareVersion => '接收器固件版本';
	@override String get currentVersion => '当前版本';
	@override String get latestVersion => '最新版本';
	@override String get checkForUpdates => '检查更新';
	@override String get checkUpdates => '检查更新';
	@override String get updateFirmware => '更新固件';
	@override String get newVersionUpdate => '新版本与更新';
	@override String get resetToDefault => '恢复默认';
}

// Path: macro
class _Translations$macro$zh extends Translations$macro$en {
	_Translations$macro$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get macroList => '宏列表';
	@override String get macroName => '宏名称';
	@override String get newMacro => '新建宏';
	@override String get deleteMacro => '删除宏';
	@override String get macroType => '宏类型';
	@override String get loopCount => '循环次数';
	@override String get keyDelayMode => '按键延迟模式';
	@override String get recordedDelay => '录制延迟';
	@override String get fixedDelay => '固定延迟';
	@override String get fixedDelayMs => '固定延迟 (毫秒)';
	@override String get startRecording => '开始录制';
	@override String get stopRecording => '停止录制';
	@override String get record => '录制';
	@override String get recordingInProgress => '录制中 — 请按下按键…';
	@override String get noEventsRecorded => '未录制任何事件';
	@override String get reset => '重置';
	@override String get save => '保存';
	@override String get cancel => '取消';
	@override String get noMacrosConfigured => '未配置宏';
	@override String get noMacrosConfiguredDesc => '创建宏以录制按键序列和鼠标操作。';
	@override String get createMacro => '创建宏';
	@override String get selectShortcutEdit => '请选择要编辑的快捷键';
	@override String get selectShortcutEditDesc => '从侧边栏列表中选择一个宏或创建一个新宏。';
	@override String get wheel => '滚轮';
	@override String get keyDown => '按键按下';
	@override String get keyUp => '按键抬起';
	@override String get removeAction => '移除操作';
	@override String get savedSuccess => '宏保存成功';
	@override String get savedFailed => '宏保存失败';
	@override String get allSlotsUsed => '所有 16 个宏槽位均已被使用';
	@override String get fixedDelayRange => '固定延迟必须在 0 到 100 毫秒之间';
	@override String saveFailed({required Object error}) => '宏保存失败: ${error}';
	@override String get loopCountRange => '循环次数必须在 1 到 255 之间';
	@override String nameTooLong({required Object max}) => '宏名称长度不能超过 ${max} 个字符';
	@override String get actionCountRange => '宏必须包含 1 到 30 个操作';
	@override String delayRange({required Object index}) => '操作 ${index} 的延迟必须在 0 到 127 之间';
	@override String unsupportedKey({required Object index}) => '操作 ${index} 包含不受支持的按键代码';
	@override late final _Translations$macro$modes$zh modes = _Translations$macro$modes$zh._(_root);
}

// Path: appSettings
class _Translations$appSettings$zh extends Translations$appSettings$en {
	_Translations$appSettings$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get appSetting => '应用设置';
	@override String get system => '系统';
	@override String get language => '语言';
	@override String get theme => '主题';
	@override String get help => '帮助';
	@override String get faq => '常见问题';
	@override String get customerService => '客户服务';
	@override String get keyTest => '按键测试';
	@override String get productManual => '产品说明书';
	@override String get driverBugFeedback => '驱动问题反馈';
	@override String get communities => 'NEWMEN HUB 社区';
	@override String get performanceSettings => '性能设置';
	@override String get lowBatteryThreshold => '低电量提醒阈值';
	@override String get about => '关于 NEWMEN HUB';
	@override String currentVersion({required Object version}) => '当前版本: ${version}';
	@override String officialWebsite({required Object url}) => '官方网站: ${url}';
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

// Path: backlight.modes
class _Translations$backlight$modes$zh extends Translations$backlight$modes$en {
	_Translations$backlight$modes$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get constant => '常亮';
	@override String get singleBreathing => '单色呼吸';
	@override String get multiBreathing => '多色呼吸';
	@override String get multiColor => '多色霓虹';
	@override String get runningColor => '流光跑马';
	@override String get cycleWave => '七彩波浪';
	@override String get cycle => '光谱循环';
	@override String get running => '跑马灯';
	@override String get off => '关闭';
}

// Path: macro.modes
class _Translations$macro$modes$zh extends Translations$macro$modes$en {
	_Translations$macro$modes$zh._(TranslationsZh root) : this._root = root, super.internal(root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get loop => '循环';
	@override String get stopOnAnyKey => '按任意键或鼠标点击停止';
	@override String get playOnHold => '按住播放';
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
			'devices.deviceStatus' => '设备状态',
			'devices.batteryLow' => ({required Object deviceName}) => '${deviceName}: 电量过低',
			'devices.sleeping' => '休眠中',
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
			'sidebar.back' => '返回',
			'windowControls.minimize' => '最小化',
			'windowControls.maximize' => '最大化',
			'windowControls.restore' => '还原',
			'windowControls.close' => '关闭',
			'mapping.mouse' => '鼠标',
			'mapping.keyboard' => '键盘',
			'mapping.special' => '特殊键',
			'mapping.macro' => '宏',
			'mapping.modifierKey' => '修饰键',
			'mapping.anyKey' => '任意按键',
			'mapping.mouseAction' => '鼠标功能',
			'mapping.mouseWheelAction' => '滚轮功能',
			'mapping.multimedia' => '多媒体',
			'mapping.consumer' => '快捷功能',
			'mapping.combinationKeys' => '组合键',
			'mapping.letterSymbolNumberKeys' => '字母、符号和数字键',
			'mapping.numericKeypadKeys' => '小键盘按键',
			'mapping.noMacrosConfigured' => '未配置宏',
			'common.save' => '保存',
			'common.cancel' => '取消',
			'common.confirm' => '确认',
			'common.done' => '完成',
			'common.resetToDefault' => '恢复默认值',
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
			'common.back' => '返回',
			'mouseCanvas.imageMissing' => '鼠标图片缺失',
			'mouseCanvas.restoreDefaultKeysTip' => '您确定要恢复默认按键吗？',
			'performance.dpiSettings' => 'DPI 设置',
			'performance.dpiSettingsSubtitle' => '配置灵敏度档位、指示灯颜色及启用档位',
			'performance.reportRate' => '回报率',
			'performance.reportRateSubtitle' => '选择鼠标向计算机报告数据的频率',
			'performance.levels' => '档位',
			'performance.dpiLevel' => ({required Object level}) => 'DPI ${level}',
			'performance.dpiStageColor' => 'DPI 档位颜色',
			'performance.addStage' => '添加档位',
			'performance.removeStage' => '删除档位',
			'performance.deleteStage' => ({required Object level}) => '删除 DPI 档位 ${level}',
			'parameter.sensorFeature' => '传感器功能',
			'parameter.sensorFeatureSubtitle' => '高级光学传感器微调与校准',
			'parameter.otherFeature' => '设备功能',
			'parameter.otherFeatureSubtitle' => '响应时间、电源管理及机械设置',
			'parameter.rippleControl' => '平滑控制',
			'parameter.rippleControlDesc' => '平滑微小移动，减少高 DPI 下的光标抖动。',
			'parameter.angleSnap' => '直线修正',
			'parameter.angleSnapDesc' => '将水平或垂直移动锁定为直线。',
			'parameter.lod' => '静默高度 (LOD)',
			'parameter.lodDesc' => '抬起鼠标时传感器停止追踪的高度。',
			'parameter.angleTune' => '角度微调',
			'parameter.angleTuneDesc' => '旋转追踪坐标轴以匹配手握倾斜角度。',
			'parameter.decreaseAngle' => '减小角度',
			'parameter.increaseAngle' => '增大角度',
			'parameter.performance' => '性能模式',
			'parameter.performanceDesc' => '在最高响应速度和电池续航之间平衡传感器帧率。',
			'parameter.performanceEco' => '低功耗模式 (节能)',
			'parameter.performanceOffice' => '办公模式',
			'parameter.performanceGaming' => '高性能模式 (游戏)',
			'parameter.performanceMode' => ({required Object wire}) => '模式 ${wire}',
			'parameter.debounce' => '按键防抖延迟',
			'parameter.debounceDesc' => '过滤机械触点抖动导致的意外双击。',
			'parameter.wheelDirection' => '滚轮方向',
			'parameter.wheelDirectionDesc' => '反转滚轮滚动方向以符合个人偏好。',
			'parameter.wheelForward' => '正向 (标准)',
			'parameter.wheelReverse' => '反向 (反转)',
			'parameter.sleepTimer' => '休眠时间',
			'parameter.sleepTimerDesc' => '进入超低功耗待机模式前的无操作超时时间。',
			'backlight.title' => '背光',
			'backlight.mode' => '模式',
			'backlight.modeDesc' => '选择动态灯效模式或静态照明效果',
			'backlight.selectModeHint' => '选择模式',
			'backlight.color' => '颜色',
			'backlight.colorDescEnabled' => '微调静态颜色的饱和度、色调和亮度',
			'backlight.colorDescDisabled' => '所选模式自动管理灯光颜色',
			'backlight.brightness' => '亮度',
			'backlight.brightnessDesc' => '调节背光 LED 的发光强度。',
			'backlight.speed' => '速度',
			'backlight.speedDesc' => '调节动态灯效的动画变换速度。',
			'backlight.powerSaving' => '省电',
			'backlight.powerSavingDesc' => '关闭灯光以节省电量前的无操作超时时间。',
			'backlight.colorCode' => '颜色代码',
			'backlight.modes.constant' => '常亮',
			'backlight.modes.singleBreathing' => '单色呼吸',
			'backlight.modes.multiBreathing' => '多色呼吸',
			'backlight.modes.multiColor' => '多色霓虹',
			'backlight.modes.runningColor' => '流光跑马',
			'backlight.modes.cycleWave' => '七彩波浪',
			'backlight.modes.cycle' => '光谱循环',
			'backlight.modes.running' => '跑马灯',
			'backlight.modes.off' => '关闭',
			'actions.left' => '左键',
			'actions.right' => '右键',
			'actions.middle' => '中键',
			'actions.forward' => '前进',
			'actions.backward' => '后退',
			'actions.dpiCycle' => 'DPI 循环',
			'actions.button' => ({required Object id}) => '按键 ${id}',
			'actions.disable' => '禁用',
			'actions.buttonOff' => '关闭按键',
			'actions.leftClick' => '左键',
			'actions.rightClick' => '右键',
			'actions.middleClick' => '中键',
			'actions.scrollUp' => '向上滚动',
			'actions.scrollDown' => '向下滚动',
			'actions.wheelUp' => '向上滚动',
			'actions.wheelDown' => '向下滚动',
			'actions.tiltLeft' => '向左摇摆',
			'actions.tiltRight' => '向右摇摆',
			'actions.swingLeft' => '向左摇摆',
			'actions.swingRight' => '向右摇摆',
			'actions.dpiIncrease' => 'DPI +',
			'actions.dpiDecrease' => 'DPI -',
			'actions.dpiUp' => 'DPI +',
			'actions.dpiDown' => 'DPI -',
			'actions.reportRate' => '回报率循环',
			'actions.reportRateCycle' => '回报率循环',
			'actions.profileCycle' => '配置文件循环',
			'actions.sniper' => '狙击键',
			'actions.macroPlay' => ({required Object id}) => '宏播放 (#${id})',
			'actions.volumeUp' => '音量增加',
			'actions.volumeDown' => '音量减少',
			'actions.volumeMute' => '静音',
			'actions.nextTrack' => '下一首',
			'actions.prevTrack' => '上一首',
			'actions.stop' => '停止',
			'actions.playPause' => '播放 / 暂停',
			'actions.webSearch' => '网络搜索',
			'actions.webHome' => '主页',
			'actions.webBack' => '网页后退',
			'actions.webForward' => '网页前进',
			'actions.webStop' => '停止加载',
			'actions.webRefresh' => '网页刷新',
			'actions.webFavourite' => '收藏夹',
			'actions.mediaPlayer' => '媒体播放器',
			'actions.email' => '电子邮件',
			'actions.calculator' => '计算器',
			'actions.myComputer' => '我的电脑',
			'actions.leftAlt' => '左 Alt',
			'actions.leftCtrl' => '左 Ctrl',
			'actions.leftWin' => '左 Win',
			'actions.leftShift' => '左 Shift',
			'actions.rightAlt' => '右 Alt',
			'actions.rightCtrl' => '右 Ctrl',
			'actions.rightWin' => '右 Win',
			'actions.rightShift' => '右 Shift',
			'actions.anyKey' => '任意按键',
			'actions.capsLock' => '大写锁定',
			'actions.space' => '空格',
			'actions.enter' => '回车',
			'actions.esc' => 'Esc',
			'actions.backspace' => '退格',
			'actions.tab' => 'Tab',
			'actions.insert' => '插入 (Insert)',
			'actions.home' => 'Home',
			'actions.pageUp' => '向上翻页',
			'actions.pageDown' => '向下翻页',
			'actions.delete' => '删除 (Delete)',
			'actions.end' => 'End',
			'actions.upArrow' => '向上箭头',
			'actions.downArrow' => '向下箭头',
			'actions.leftArrow' => '向左箭头',
			'actions.rightArrow' => '向右箭头',
			'actions.printScreen' => '截屏 (Print Screen)',
			'actions.scrollLock' => '滚动锁定',
			'actions.pause' => '暂停 (Pause)',
			'actions.numLock' => '数字锁定',
			'actions.numpadEnter' => '小键盘回车',
			'actions.numpadDel' => '小键盘删除',
			'actions.numpadAdd' => '小键盘 +',
			'actions.numpadSub' => '小键盘 -',
			'actions.numpadMul' => '小键盘 *',
			'actions.numpadDiv' => '小键盘 /',
			'actions.numpadEq' => '小键盘 =',
			'actions.numpad0' => '小键盘 0',
			'actions.numpad1' => '小键盘 1',
			'actions.numpad2' => '小键盘 2',
			'actions.numpad3' => '小键盘 3',
			'actions.numpad4' => '小键盘 4',
			'actions.numpad5' => '小键盘 5',
			'actions.numpad6' => '小键盘 6',
			'actions.numpad7' => '小键盘 7',
			'actions.numpad8' => '小键盘 8',
			'actions.numpad9' => '小键盘 9',
			'deviceSetting.mouseFirmwareVersion' => '鼠标固件版本',
			'deviceSetting.dongleFirmwareVersion' => '接收器固件版本',
			'deviceSetting.currentVersion' => '当前版本',
			'deviceSetting.latestVersion' => '最新版本',
			'deviceSetting.checkForUpdates' => '检查更新',
			'deviceSetting.checkUpdates' => '检查更新',
			'deviceSetting.updateFirmware' => '更新固件',
			'deviceSetting.newVersionUpdate' => '新版本与更新',
			'deviceSetting.resetToDefault' => '恢复默认',
			'macro.macroList' => '宏列表',
			'macro.macroName' => '宏名称',
			'macro.newMacro' => '新建宏',
			'macro.deleteMacro' => '删除宏',
			'macro.macroType' => '宏类型',
			'macro.loopCount' => '循环次数',
			'macro.keyDelayMode' => '按键延迟模式',
			'macro.recordedDelay' => '录制延迟',
			'macro.fixedDelay' => '固定延迟',
			'macro.fixedDelayMs' => '固定延迟 (毫秒)',
			'macro.startRecording' => '开始录制',
			'macro.stopRecording' => '停止录制',
			'macro.record' => '录制',
			'macro.recordingInProgress' => '录制中 — 请按下按键…',
			'macro.noEventsRecorded' => '未录制任何事件',
			'macro.reset' => '重置',
			'macro.save' => '保存',
			'macro.cancel' => '取消',
			'macro.noMacrosConfigured' => '未配置宏',
			'macro.noMacrosConfiguredDesc' => '创建宏以录制按键序列和鼠标操作。',
			'macro.createMacro' => '创建宏',
			'macro.selectShortcutEdit' => '请选择要编辑的快捷键',
			'macro.selectShortcutEditDesc' => '从侧边栏列表中选择一个宏或创建一个新宏。',
			'macro.wheel' => '滚轮',
			'macro.keyDown' => '按键按下',
			'macro.keyUp' => '按键抬起',
			'macro.removeAction' => '移除操作',
			'macro.savedSuccess' => '宏保存成功',
			'macro.savedFailed' => '宏保存失败',
			'macro.allSlotsUsed' => '所有 16 个宏槽位均已被使用',
			'macro.fixedDelayRange' => '固定延迟必须在 0 到 100 毫秒之间',
			'macro.saveFailed' => ({required Object error}) => '宏保存失败: ${error}',
			'macro.loopCountRange' => '循环次数必须在 1 到 255 之间',
			'macro.nameTooLong' => ({required Object max}) => '宏名称长度不能超过 ${max} 个字符',
			'macro.actionCountRange' => '宏必须包含 1 到 30 个操作',
			'macro.delayRange' => ({required Object index}) => '操作 ${index} 的延迟必须在 0 到 127 之间',
			'macro.unsupportedKey' => ({required Object index}) => '操作 ${index} 包含不受支持的按键代码',
			'macro.modes.loop' => '循环',
			'macro.modes.stopOnAnyKey' => '按任意键或鼠标点击停止',
			'macro.modes.playOnHold' => '按住播放',
			'appSettings.appSetting' => '应用设置',
			'appSettings.system' => '系统',
			'appSettings.language' => '语言',
			'appSettings.theme' => '主题',
			'appSettings.help' => '帮助',
			'appSettings.faq' => '常见问题',
			'appSettings.customerService' => '客户服务',
			'appSettings.keyTest' => '按键测试',
			'appSettings.productManual' => '产品说明书',
			'appSettings.driverBugFeedback' => '驱动问题反馈',
			'appSettings.communities' => 'NEWMEN HUB 社区',
			'appSettings.performanceSettings' => '性能设置',
			'appSettings.lowBatteryThreshold' => '低电量提醒阈值',
			'appSettings.about' => '关于 NEWMEN HUB',
			'appSettings.currentVersion' => ({required Object version}) => '当前版本: ${version}',
			'appSettings.officialWebsite' => ({required Object url}) => '官方网站: ${url}',
			_ => null,
		};
	}
}
