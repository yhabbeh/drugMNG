import 'package:flutter/material.dart';

abstract final class RouteGuards {
  static String? redirect(BuildContext context, String? authState) {
    final isLoggedIn = authState != null;
    final isOnSignIn = ModalRoute.of(context)?.settings.name == '/sign-in';

    if (!isLoggedIn && !isOnSignIn) return '/sign-in';
    if (isLoggedIn && isOnSignIn) return '/';
    return null;
  }
}
