import 'dart:js_interop';

@JS('window.location.replace')
external void _replace(JSString url);

void openHome() => _replace(Uri.base.removeFragment().toString().toJS);
