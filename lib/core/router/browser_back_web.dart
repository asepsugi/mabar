import 'dart:async';
import 'dart:js_interop';

import 'package:go_router/go_router.dart';

@JS('mabarBack')
external set _onBack(JSFunction callback);

/// Back browser menutup sheet, dialog, atau layar teratas, sama dengan back native. False = tidak ada yang bisa
/// ditutup (Beranda), jadi `index.html` membiarkan back berikutnya keluar dari app.
void handleBrowserBack(GoRouter router) {
  _onBack = () {
    if (!router.canPop()) return false.toJS;
    unawaited(router.routerDelegate.popRoute());
    return true.toJS;
  }.toJS;
}
