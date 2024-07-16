import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> showMyOkDialog({
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: navigatorKey.currentContext!,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: <Widget>[
          TextButton(
            child: const Text('Oke'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}

void showMySnackBar({required String message}) {
  final snackBar = SnackBar(content: Text(message));
  ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(snackBar);
}

Container myLoading(bool isLoading) {
  if (!isLoading) return Container();
  return Container(
    color: Theme.of(navigatorKey.currentContext!).primaryColor.withOpacity(0.5),
    child: Center(
      child: LoadingAnimationWidget.inkDrop(color: Colors.white, size: 34),
    ),
  );
}
