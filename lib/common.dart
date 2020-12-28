import 'package:flutter/material.dart';

void _closePop(BuildContext context) {
  Navigator.of(context).pop();
}


void popup(BuildContext context, String title, String body) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () => _closePop(context),
            ),
          ],
        );
      });
}
