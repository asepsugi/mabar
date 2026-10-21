import 'dart:js_interop';

import 'package:flutter/foundation.dart';

import 'app_install.dart';

@JS('mabarInstall')
external _MabarInstall? get _api;

extension type _MabarInstall._(JSObject _) implements JSObject {
  external String state();
  external JSPromise<JSAny?> prompt();
  external set onchange(JSFunction callback);
}

AppInstallMode _read() => switch (_api?.state()) {
  'prompt' => AppInstallMode.prompt,
  'manual' => AppInstallMode.manual,
  _ => AppInstallMode.none,
};

/// Ikut berubah saat browser menawarkan pemasangan (sering setelah Beranda tampil) dan
/// setelah dialognya ditutup — diterima atau tidak, event yang sama tidak bisa dipakai lagi.
final ValueListenable<AppInstallMode> appInstallMode = () {
  final mode = ValueNotifier(_read());
  _api?.onchange = () {
    mode.value = _read();
  }.toJS;
  return mode;
}();

Future<void> promptAppInstall() async {
  await _api?.prompt().toDart;
}
