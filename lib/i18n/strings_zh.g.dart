///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsZh extends Translations {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  TranslationsZh({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
  }) : assert(
         overrides == null,
         'Set "translation_overrides: true" in order to enable this feature.',
       ),
       $meta = TranslationMetadata(
         locale: AppLocale.zh,
         overrides: overrides ?? {},
         cardinalResolver: cardinalResolver,
         ordinalResolver: ordinalResolver,
       ),
       super(
         cardinalResolver: cardinalResolver,
         ordinalResolver: ordinalResolver,
       ) {
    super.$meta.setFlatMapFunction(
      $meta.getTranslation,
    ); // copy base translations to super.$meta
    $meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <zh>.
  @override
  final TranslationMetadata<AppLocale, Translations> $meta;

  /// Access flat map
  @override
  dynamic operator [](String key) =>
      $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

  late final TranslationsZh _root = this; // ignore: unused_field

  // Translations
  @override
  late final _TranslationsViewsZh views = _TranslationsViewsZh._(_root);
  @override
  late final _TranslationsDevicesZh devices = _TranslationsDevicesZh._(_root);
  @override
  late final _TranslationsSidebarZh sidebar = _TranslationsSidebarZh._(_root);
  @override
  late final _TranslationsMappingZh mapping = _TranslationsMappingZh._(_root);
  @override
  late final _TranslationsCommonZh common = _TranslationsCommonZh._(_root);
  @override
  late final _TranslationsMouseCanvasZh mouseCanvas =
      _TranslationsMouseCanvasZh._(_root);
  @override
  late final _TranslationsPerformanceZh performance =
      _TranslationsPerformanceZh._(_root);
  @override
  late final _TranslationsParameterZh parameter = _TranslationsParameterZh._(
    _root,
  );
  @override
  late final _TranslationsBacklightZh backlight = _TranslationsBacklightZh._(
    _root,
  );
  @override
  late final _TranslationsActionsZh actions = _TranslationsActionsZh._(_root);
  @override
  late final _TranslationsDeviceSettingZh deviceSetting =
      _TranslationsDeviceSettingZh._(_root);
  @override
  late final _TranslationsMacroZh macro = _TranslationsMacroZh._(_root);
}

// Path: views
class _TranslationsViewsZh extends TranslationsViewsEn {
  _TranslationsViewsZh._(TranslationsZh root)
    : this._root = root,
      super.internal(root);

  final TranslationsZh _root; // ignore: unused_field

  // Translations
  @override
  late final _TranslationsViewsLoginZh login = _TranslationsViewsLoginZh._(
    _root,
  );
  @override
  late final _TranslationsViewsHomeZh home = _TranslationsViewsHomeZh._(_root);
}

// Path: devices
class _TranslationsDevicesZh extends TranslationsDevicesEn {
  _TranslationsDevicesZh._(TranslationsZh root)
    : this._root = root,
      super.internal(root);

  final TranslationsZh _root; // ignore: unused_field

  // Translations
  @override
  String get addDevice => '添加设备';
  @override
  String get working => '工作中...';
  @override
  String get bluetoothWarning => '该驱动程序无法识别蓝牙连接。请使用 2.4G 接收器或电缆连接';
  @override
  String get noDevices => '未发现设备';
}

// Path: sidebar
class _TranslationsSidebarZh extends TranslationsSidebarEn {
  _TranslationsSidebarZh._(TranslationsZh root)
    : this._root = root,
      super.internal(root);

  final TranslationsZh _root; // ignore: unused_field

  // Translations
  @override
  String get buttonMapping => '按键映射';
  @override
  String get macroSetting => '宏设置';
  @override
  String get performanceSetting => '性能设置';
  @override
  String get parameterSetting => '参数设置';
  @override
  String get backlightSetting => '背光设置';
  @override
  String get profileManagement => '配置文件管理';
  @override
  String get deviceSetting => '设备设置';
  @override
  String get mouse => '鼠标';
  @override
  String batteryLabel({required Object pct}) => '电量 ${pct}%';
  @override
  String batteryCharging({required Object pct}) => '电量 ${pct}% 充电中';
  @override
  String get batteryEmpty => '电量 —';
}

// Path: mapping
class _TranslationsMappingZh extends TranslationsMappingEn {
  _TranslationsMappingZh._(TranslationsZh root)
    : this._root = root,
      super.internal(root);

  final TranslationsZh _root; // ignore: unused_field

  // Translations
  @override
  String get mouse => '鼠标';
  @override
  String get keyboard => '键盘';
  @override
  String get special => '特殊键';
  @override
  String get macro => '宏';
  @override
  String get modifierKey => '修饰键';
}

// Path: common
class _TranslationsCommonZh extends TranslationsCommonEn {
  _TranslationsCommonZh._(TranslationsZh root)
    : this._root = root,
      super.internal(root);

  final TranslationsZh _root; // ignore: unused_field

  // Translations
  @override
  String get save => '保存';
  @override
  String get cancel => '取消';
  @override
  String get confirm => '确认';
  @override
  String get resetToDefault => '恢复默认';
  @override
  String get tip => '提示';
  @override
  String get settings => '设置';
  @override
  String get language => '语言';
  @override
  String get lightMode => '浅色模式';
  @override
  String get darkMode => '深色模式';
  @override
  String get switchToLightMode => '切换到浅色模式';
  @override
  String get switchToDarkMode => '切换到深色模式';
  @override
  String get forward => '向前';
  @override
  String get reverse => '反向';
  @override
  String secondsUnit({required Object seconds}) => '${seconds} 秒';
  @override
  String get done => '完成';
}

// Path: mouseCanvas
class _TranslationsMouseCanvasZh extends TranslationsMouseCanvasEn {
  _TranslationsMouseCanvasZh._(TranslationsZh root)
    : this._root = root,
      super.internal(root);

  final TranslationsZh _root; // ignore: unused_field

  // Translations
  @override
  String get imageMissing => '鼠标图片缺失';
  @override
  String get restoreDefaultKeysTip => '您确定要恢复默认按键吗？';
}

// Path: performance
class _TranslationsPerformanceZh extends TranslationsPerformanceEn {
  _TranslationsPerformanceZh._(TranslationsZh root)
    : this._root = root,
      super.internal(root);

  final TranslationsZh _root; // ignore: unused_field

  // Translations
  @override
  String get dpiSettings => 'DPI 设置';
  @override
  String get reportRate => '回报率';
  @override
  String get levels => '档位';
  @override
  String dpiLevel({required Object level}) => 'DPI ${level}';
  @override
  String get dpiStageColor => 'DPI 档位颜色';
}

// Path: parameter
class _TranslationsParameterZh extends TranslationsParameterEn {
  _TranslationsParameterZh._(TranslationsZh root)
    : this._root = root,
      super.internal(root);

  final TranslationsZh _root; // ignore: unused_field

  // Translations
  @override
  String get sensorFeature => '传感器功能';
  @override
  String get otherFeature => '其他功能';
  @override
  String get rippleControl => '平滑控制';
  @override
  String get angleSnap => '角度微调';
  @override
  String get lod => '静默高度 (LOD)';
  @override
  String get angleTune => '角度调整';
  @override
  String get performance => '性能';
  @override
  String get wheelDirection => '滚轮方向';
}

// Path: backlight
class _TranslationsBacklightZh extends TranslationsBacklightEn {
  _TranslationsBacklightZh._(TranslationsZh root)
    : this._root = root,
      super.internal(root);

  final TranslationsZh _root; // ignore: unused_field

  // Translations
  @override
  String get title => '背光';
  @override
  String get mode => '模式';
  @override
  String get color => '颜色';
  @override
  String get powerSaving => '省电';
}

// Path: actions
class _TranslationsActionsZh extends TranslationsActionsEn {
  _TranslationsActionsZh._(TranslationsZh root)
    : this._root = root,
      super.internal(root);

  final TranslationsZh _root; // ignore: unused_field

  // Translations
  @override
  String get left => '左键';
  @override
  String get right => '右键';
  @override
  String get middle => '中键';
  @override
  String get forward => '前进';
  @override
  String get backward => '后退';
  @override
  String get dpiCycle => 'DPI 循环';
  @override
  String button({required Object id}) => '按键 ${id}';
  @override
  String get disable => '禁用 / 无操作';
  @override
  String get buttonOff => '关闭按键';
  @override
  String get leftClick => '左键单击';
  @override
  String get rightClick => '右键单击';
  @override
  String get middleClick => '中键单击';
  @override
  String get scrollUp => '向上滚动';
  @override
  String get scrollDown => '向下滚动';
  @override
  String get swingLeft => '向左摇摆';
  @override
  String get swingRight => '向右摇摆';
  @override
  String get dpiIncrease => '增加 DPI';
  @override
  String get dpiDecrease => '减少 DPI';
  @override
  String get reportRate => '回报率';
  @override
  String get profileCycle => '配置文件循环';
  @override
  String get sniper => '狙击键';
  @override
  String macroPlay({required Object id}) => '宏播放 (#${id})';
}

// Path: deviceSetting
class _TranslationsDeviceSettingZh extends TranslationsDeviceSettingEn {
  _TranslationsDeviceSettingZh._(TranslationsZh root)
    : this._root = root,
      super.internal(root);

  final TranslationsZh _root; // ignore: unused_field

  // Translations
  @override
  String get mouseFirmwareVersion => '鼠标固件版本';
  @override
  String get dongleFirmwareVersion => '接收器固件版本';
  @override
  String get latestVersion => '最新版本';
  @override
  String get checkUpdates => '检查更新';
  @override
  String get newVersionUpdate => '新版本与更新';
}

// Path: macro
class _TranslationsMacroZh extends TranslationsMacroEn {
  _TranslationsMacroZh._(TranslationsZh root)
    : this._root = root,
      super.internal(root);

  final TranslationsZh _root; // ignore: unused_field

  // Translations
  @override
  String get startRecording => '开始录制';
  @override
  String get stopRecording => '停止录制';
  @override
  String get record => '录制';
  @override
  String get reset => '重置';
  @override
  String get noMacrosConfigured => '未配置宏';
  @override
  String get createMacro => '创建宏';
  @override
  String get selectShortcutEdit => '请选择要编辑的快捷键';
  @override
  String get newMacro => '新建宏';
}

// Path: views.login
class _TranslationsViewsLoginZh extends TranslationsViewsLoginEn {
  _TranslationsViewsLoginZh._(TranslationsZh root)
    : this._root = root,
      super.internal(root);

  final TranslationsZh _root; // ignore: unused_field

  // Translations
  @override
  String get welcome => '欢迎';
  @override
  String get userName => '用户名';
  @override
  String get loginButton => '登录';
}

// Path: views.home
class _TranslationsViewsHomeZh extends TranslationsViewsHomeEn {
  _TranslationsViewsHomeZh._(TranslationsZh root)
    : this._root = root,
      super.internal(root);

  final TranslationsZh _root; // ignore: unused_field

  // Translations
  @override
  String greeting({required Object userName}) => '你好，${userName}！';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on TranslationsZh {
  dynamic _flatMapFunction(String path) {
    switch (path) {
      case 'views.login.welcome':
        return '欢迎';
      case 'views.login.userName':
        return '用户名';
      case 'views.login.loginButton':
        return '登录';
      case 'views.home.greeting':
        return ({required Object userName}) => '你好，${userName}！';
      case 'devices.addDevice':
        return '添加设备';
      case 'devices.working':
        return '工作中...';
      case 'devices.bluetoothWarning':
        return '该驱动程序无法识别蓝牙连接。请使用 2.4G 接收器或电缆连接';
      case 'devices.noDevices':
        return '未发现设备';
      case 'sidebar.buttonMapping':
        return '按键映射';
      case 'sidebar.macroSetting':
        return '宏设置';
      case 'sidebar.performanceSetting':
        return '性能设置';
      case 'sidebar.parameterSetting':
        return '参数设置';
      case 'sidebar.backlightSetting':
        return '背光设置';
      case 'sidebar.profileManagement':
        return '配置文件管理';
      case 'sidebar.deviceSetting':
        return '设备设置';
      case 'sidebar.mouse':
        return '鼠标';
      case 'sidebar.batteryLabel':
        return ({required Object pct}) => '电量 ${pct}%';
      case 'sidebar.batteryCharging':
        return ({required Object pct}) => '电量 ${pct}% 充电中';
      case 'sidebar.batteryEmpty':
        return '电量 —';
      case 'mapping.mouse':
        return '鼠标';
      case 'mapping.keyboard':
        return '键盘';
      case 'mapping.special':
        return '特殊键';
      case 'mapping.macro':
        return '宏';
      case 'mapping.modifierKey':
        return '修饰键';
      case 'common.save':
        return '保存';
      case 'common.cancel':
        return '取消';
      case 'common.confirm':
        return '确认';
      case 'common.resetToDefault':
        return '恢复默认';
      case 'common.tip':
        return '提示';
      case 'common.settings':
        return '设置';
      case 'common.language':
        return '语言';
      case 'common.lightMode':
        return '浅色模式';
      case 'common.darkMode':
        return '深色模式';
      case 'common.switchToLightMode':
        return '切换到浅色模式';
      case 'common.switchToDarkMode':
        return '切换到深色模式';
      case 'common.forward':
        return '向前';
      case 'common.reverse':
        return '反向';
      case 'common.secondsUnit':
        return ({required Object seconds}) => '${seconds} 秒';
      case 'common.done':
        return '完成';
      case 'mouseCanvas.imageMissing':
        return '鼠标图片缺失';
      case 'mouseCanvas.restoreDefaultKeysTip':
        return '您确定要恢复默认按键吗？';
      case 'performance.dpiSettings':
        return 'DPI 设置';
      case 'performance.reportRate':
        return '回报率';
      case 'performance.levels':
        return '档位';
      case 'performance.dpiLevel':
        return ({required Object level}) => 'DPI ${level}';
      case 'performance.dpiStageColor':
        return 'DPI 档位颜色';
      case 'parameter.sensorFeature':
        return '传感器功能';
      case 'parameter.otherFeature':
        return '其他功能';
      case 'parameter.rippleControl':
        return '平滑控制';
      case 'parameter.angleSnap':
        return '角度微调';
      case 'parameter.lod':
        return '静默高度 (LOD)';
      case 'parameter.angleTune':
        return '角度调整';
      case 'parameter.performance':
        return '性能';
      case 'parameter.wheelDirection':
        return '滚轮方向';
      case 'backlight.title':
        return '背光';
      case 'backlight.mode':
        return '模式';
      case 'backlight.color':
        return '颜色';
      case 'backlight.powerSaving':
        return '省电';
      case 'actions.left':
        return '左键';
      case 'actions.right':
        return '右键';
      case 'actions.middle':
        return '中键';
      case 'actions.forward':
        return '前进';
      case 'actions.backward':
        return '后退';
      case 'actions.dpiCycle':
        return 'DPI 循环';
      case 'actions.button':
        return ({required Object id}) => '按键 ${id}';
      case 'actions.disable':
        return '禁用 / 无操作';
      case 'actions.buttonOff':
        return '关闭按键';
      case 'actions.leftClick':
        return '左键单击';
      case 'actions.rightClick':
        return '右键单击';
      case 'actions.middleClick':
        return '中键单击';
      case 'actions.scrollUp':
        return '向上滚动';
      case 'actions.scrollDown':
        return '向下滚动';
      case 'actions.swingLeft':
        return '向左摇摆';
      case 'actions.swingRight':
        return '向右摇摆';
      case 'actions.dpiIncrease':
        return '增加 DPI';
      case 'actions.dpiDecrease':
        return '减少 DPI';
      case 'actions.reportRate':
        return '回报率';
      case 'actions.profileCycle':
        return '配置文件循环';
      case 'actions.sniper':
        return '狙击键';
      case 'actions.macroPlay':
        return ({required Object id}) => '宏播放 (#${id})';
      case 'deviceSetting.mouseFirmwareVersion':
        return '鼠标固件版本';
      case 'deviceSetting.dongleFirmwareVersion':
        return '接收器固件版本';
      case 'deviceSetting.latestVersion':
        return '最新版本';
      case 'deviceSetting.checkUpdates':
        return '检查更新';
      case 'deviceSetting.newVersionUpdate':
        return '新版本与更新';
      case 'macro.startRecording':
        return '开始录制';
      case 'macro.stopRecording':
        return '停止录制';
      case 'macro.record':
        return '录制';
      case 'macro.reset':
        return '重置';
      case 'macro.noMacrosConfigured':
        return '未配置宏';
      case 'macro.createMacro':
        return '创建宏';
      case 'macro.selectShortcutEdit':
        return '请选择要编辑的快捷键';
      case 'macro.newMacro':
        return '新建宏';
      default:
        return null;
    }
  }
}
