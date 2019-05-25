import 'dart:math';

import 'package:flutter/material.dart';

enum Severity { SUCCESS, INFO, ERROR }

class SeverityHelper {
  static Icon iconOf(Severity severity) {
    Icon icon;

    switch (severity) {
      case Severity.INFO:
        icon = Icon(Icons.info_outline, color: Colors.lightBlueAccent);
        break;
      case Severity.SUCCESS:
        icon = Icon(Icons.check_circle_outline, color: Colors.green);
        break;
      case Severity.ERROR:
        icon = Icon(Icons.warning, color: Colors.red);
        break;
    }

    return icon;
  }
}

class Message {
  Message._(this.severity, this.message);

  Severity severity;
  String message;

  Message.info(String message) : this._(Severity.INFO, message);

  Message.success(String message) : this._(Severity.SUCCESS, message);
  Message.error(String message) : this._(Severity.ERROR, message);
}

class MessageDisplay extends StatelessWidget {
  final Stream<Message> messageStream;
  EdgeInsetsGeometry padding;

  MessageDisplay(this.messageStream, {Key key, this.padding}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Message>(
        initialData: null,
        stream: messageStream,
        builder: (BuildContext context, AsyncSnapshot<Message> snapshot) {
          if (snapshot.data != null) {
            Widget display = Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Expanded(
                    child: FittedBox(
                        child: SeverityHelper.iconOf(snapshot.data.severity))),
                Text(
                  snapshot.data.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                )
              ],
            );

            if (padding != null) {
              return Padding(padding: padding, child: display,);
            }
            else {
              return display;
            }
          } else {
            return SizedBox(
              width: 0,
              height: 0,
            );
          }
        });
  }
}
