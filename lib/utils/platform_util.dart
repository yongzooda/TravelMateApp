import 'dart:io';

bool isMobilePlatform() {
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (e) {
    return false; // 웹 플랫폼
  }
}
