import 'package:flutter/foundation.dart';

import 'app_install.dart';

/// Build native: app-nya sudah terpasang dari store.
final ValueListenable<AppInstallMode> appInstallMode = ValueNotifier(AppInstallMode.none);

Future<void> promptAppInstall() async {}
