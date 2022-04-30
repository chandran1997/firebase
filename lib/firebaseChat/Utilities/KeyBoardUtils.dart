import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class KeyboardUtils {
  static bool isKeyboardShowing() {
    if (WidgetsBinding.instance != null) {
      return WidgetsBinding.instance!.window.viewInsets.bottom > 0;
    } else {
      return false;
    }
  }

  static closeKeyboard(BuildContext context) {
    FocusNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }
}
