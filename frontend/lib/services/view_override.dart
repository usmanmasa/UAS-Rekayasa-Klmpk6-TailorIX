import 'package:flutter/foundation.dart' show kIsWeb;

/// Global helper to persist "force web view" state when app is opened with
/// `?view=web` in the browser URL. Call `initFromUri()` early from wrapper
/// widgets so the flag stays in memory across navigations.
class ViewOverride {
  static bool forceWeb = false;

  static void initFromUri() {
    if (!kIsWeb) return;
    final view = Uri.base.queryParameters['view'];
    forceWeb = view == 'web';
  }
}
