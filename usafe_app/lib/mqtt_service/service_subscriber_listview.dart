import 'dart:async';
import 'package:flutter/material.dart';
import 'package:usafe_app/mqtt_service/subscribers.dart';

class ServiceListView extends StatefulWidget {
  final Stream<List<ServiceSubscriber>> _serviceSubscriberStream;

  ServiceListView(this._serviceSubscriberStream);

  @override
  State<StatefulWidget> createState() {
    return _ServiceListViewState(_serviceSubscriberStream);
  }
}

class _ServiceListViewState extends State<ServiceListView> {
  Stream<List<ServiceSubscriber>> _serviceSubscriberStream;
  StreamSubscription<List<ServiceSubscriber>> _subscription;

  _ServiceListViewState(this._serviceSubscriberStream);

  List<ServiceSubscriber> _serviceSubscribers = List();

  @override
  void initState() {
    super.initState();
    _subscription = _serviceSubscriberStream.listen((services) {
      setState(() {
        _serviceSubscribers = services;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_serviceSubscribers.isEmpty) {
      return Container();
    }

    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: <Widget>[
        SliverAppBar(
          title: const Text(
            "Supported services:",
            style: TextStyle(color: Colors.black87),
          ),
          pinned: true,
          elevation: 0,
          primary: false,
          backgroundColor: Theme.of(context).canvasColor,
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            {
              if (_serviceSubscribers.isEmpty ||
                  index >= _serviceSubscribers.length) {
                return null;
              }

              ServiceSubscriber subscriber = _serviceSubscribers[index];
              ConfirmationButton confirmButton = ConfirmationButton(subscriber);

              return StatusInfoInheritedWidget(
                subscriber.onNewStatusInfo,
                child: StreamBuilder<StatusInfo>(
                  stream: subscriber.onNewStatusInfo
                      .handleError((e) {}, test: (e) => e is SubscriberException),
                  builder: (context, snapshot) {
                    if (snapshot.data != null) {
                      Icon statusIcon;
                      String title;
                      Widget confirmationWidget;
                      switch (snapshot.data.level) {
                        case StatusLevel.LOW:
                          title = "Low";
                          statusIcon = Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 36,
                          );
                          break;
                        case StatusLevel.MEDIUM:
                          title = "Medium";
                          statusIcon = Icon(
                            Icons.warning,
                            color: Colors.orangeAccent,
                            size: 36,
                          );
                          break;
                        case StatusLevel.HIGH:
                          title = "High";
                          statusIcon = Icon(
                            Icons.warning,
                            color: Colors.red,
                            size: 36,
                          );
                          break;
                      }

                      if (snapshot.data.needsConfirmation) {
                        title += " (needs confirming)";
                        confirmationWidget = confirmButton;
                      }
                      return Card(
                        child: ListTile(
                          leading: statusIcon,
                          title: Text(title),
                          subtitle: Text(subscriber.serviceDescription),
                          trailing: confirmationWidget,
                        ),
                      );
                    } else {
                      return Card(
                        child: ListTile(
                          leading: CircularProgressIndicator(),
                          title: const Text("Connecting..."),
                          subtitle: Text(subscriber.serviceDescription),
                        ),
                      );
                    }
                  },
                ),
              );
            }
          }),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }
}

class StatusInfoInheritedWidget extends InheritedWidget {
  final Stream<StatusInfo> statusInfoStream;

  StatusInfoInheritedWidget(this.statusInfoStream, {Widget child})
      : super(child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }

  static StatusInfoInheritedWidget of(BuildContext context) =>
      context.ancestorWidgetOfExactType(StatusInfoInheritedWidget);
}

class ConfirmationButton extends StatefulWidget {
  final ServiceSubscriber subscriber;

  ConfirmationButton(this.subscriber);

  @override
  State<StatefulWidget> createState() {
    return _ConfirmationButtonState();
  }
}

class _ConfirmationButtonState extends State<ConfirmationButton> {
  bool isConfirmed = false;
  StatusInfo currentStatusInfo;
  StreamSubscription<StatusInfo> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = StatusInfoInheritedWidget.of(context).statusInfoStream.listen((statusInfo) {
      currentStatusInfo = currentStatusInfo ?? statusInfo;
      if (statusInfo.level != currentStatusInfo.level && statusInfo.needsConfirmation) {
        setState(() => isConfirmed = false);
      }
      currentStatusInfo = statusInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isConfirmed) {
      return CircularProgressIndicator();
    }
    else {
      return GestureDetector(
        onLongPress: () {
          if (currentStatusInfo != null) {
            setState(() {
              widget.subscriber
                  .confirmStatusInfo(currentStatusInfo);
              isConfirmed = true;
            });
          }
        },
        child: CircleAvatar(
          child: Icon(
            Icons.touch_app,
            size: 36,
          ),
          maxRadius: 24,
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    _subscription.cancel();
  }
}
