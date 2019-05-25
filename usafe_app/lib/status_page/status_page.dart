import 'package:flutter/material.dart';
import 'package:usafe_app/message_display/message_display.dart';
import 'package:usafe_app/mqtt_service/subscribers.dart';
import 'package:usafe_app/mqtt_service/service_subscriber_listview.dart';
import 'package:usafe_app/my_flutter_app_icons.dart';
import './status_page_bloc.dart';

class StatusPage extends StatelessWidget {
  final StatusPageBloc _bloc;

  StatusPage(this._bloc);

  @override
  Widget build(BuildContext context) {
    List<ServiceSubscriber> subscribers = List();
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
//            mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
                flex: 2,
                child: Card(
                    child: MessageDisplay(_bloc.messageStream, padding: EdgeInsets.all(8),),
                )),
            Divider(),
            Expanded(
              flex: 3,
              child: ServiceListView(_bloc.serviceSubscriberStream),
            ),
            Container(height: 72,)
          ],
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
          stream: _bloc.connectionStream,
          builder: (context, snapshot) {
            bool isConnected = snapshot.data == null ? false : snapshot.data;

            if (isConnected) {
              return GestureDetector(
                onLongPress: () {
                  _bloc.connectionSink.add(false);
                  Feedback.forLongPress(context);
                },
                child: FloatingActionButton(
                  onPressed: () {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: const Text("Long press to cancel connection"),
                    ));
                  },
                  child: Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 36,
                  ),
                  backgroundColor: Colors.white,
                ),
              );
            } else {
              return FloatingActionButton(
                onPressed: () => _bloc.connectionSink.add(true),
                child: Icon(MyFlutterApp.qrcode),
              );
            }
          }),
    );
  }
}
