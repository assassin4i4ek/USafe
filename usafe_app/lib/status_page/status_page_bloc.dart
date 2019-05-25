import 'dart:async';
import 'package:usafe_app/message_display/message_display.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:usafe_app/mqtt_service/publishers.dart';
import 'dart:io';
import 'dart:convert';

import 'package:usafe_app/mqtt_service/subscribers.dart';

class StatusPageBloc {
  //MESSAGE CONTROLLER
  StreamController<Message> _messageController = StreamController.broadcast();

  Stream<Message> get messageStream => _messageController.stream;

  Sink<Message> get messageSink => _messageController.sink;
  //CONNECTION CONTROLLER
  StreamController<bool> _connectionController = StreamController.broadcast();

  Stream<bool> get connectionStream => _connectionController.stream.transform(
          StreamTransformer<bool, bool>.fromHandlers(
              handleData: (connect, sink) async {
        if (connect) {
          sink.add(await _connect());
        } else {
          sink.add(!_disconnect());
        }
      }, handleError: (error, stackTrace, sink) {
        if (error is bool) {
          sink.add(error);
        } else {
          messageSink.add(Message.error("Connection error occured "));
        }
      }));

  Sink<bool> get connectionSink => _connectionController.sink;

  //SUBSCRIBERS CONTOLLER
  StreamController<List<ServiceSubscriber>> _serviceSubscriberController =
      StreamController.broadcast();

  Stream<List<ServiceSubscriber>> get serviceSubscriberStream =>
      _serviceSubscriberController.stream;

  Sink<List<ServiceSubscriber>> get _serviceSubscriberSink =>
      _serviceSubscriberController.sink;

  void dispose() {
    _disconnectMqtt();
    _messageController.close();
    _connectionController.close();
    _serviceSubscriberController.close();
  }

  //MQTT SECTION
  MqttClient _mqttClient;
  List<MqttServicePublisher> _mqttPublishers = List();
  List<MqttServiceSubscriber> _mqttSubscribers = List();

  Future<bool> _connect() async {
    String server = "m24.cloudmqtt.com";
    String clientId = "+380999999999";
    String username = "qeozciql";
    String password = "rL4GWKmt99KZ";
    int port = 11714;
    _mqttClient = MqttClient.withPort(server, clientId, port);
    _mqttClient.onDisconnected = () {
      _disconnectMqtt();
      messageSink.add(Message.error("Disconnected!"));
      _connectionController.addError(false);
    };

    try {
      await _mqttClient.connect(username, password);
      String scanResult = await BarcodeScanner.scan();
      Map<String, dynamic> result = json.decode(scanResult);
      String helmetId = result["helmet_id"];
      List helmetServices = result["services"];
      if (helmetId == null || helmetId.isEmpty) {
        throw FormatException("Invalid code scanned");
      }
      //Location publisher
      MqttServicePublisher locationPublisher =
          MqttLocationPublisher(helmetId, _mqttClient);
      Future<void> startPublisher = locationPublisher.start();
      _mqttPublishers.add(locationPublisher);
      await startPublisher;

      //Subscribers
      helmetServices.forEach((serviceName) async {
        MqttServiceSubscriber subscriber = MqttServiceSubscriber.forService(
            serviceName, helmetId, _mqttClient);
        subscriber.start();
        _mqttSubscribers.add(subscriber);
      });

      _serviceSubscriberSink.add(_mqttSubscribers);

      messageSink.add(
          Message.success('Successfully connected to helmet:\n"$helmetId"'));

      return true;
    } on SocketException catch (e) {
      //No network connection
      messageSink.add(Message.error("Couldn't connect to MQTT\n$e"));
    } on NoConnectionException catch (e) {
      //Broker refused
      messageSink.add(Message.error("Couldn't connect to MQTT broker\n$e"));
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        messageSink.add(Message.error("No camera permission"));
      } else {
        messageSink.add(Message.error("Unknown error\n$e"));
      }
    } on FormatException catch (e) {
      messageSink.add(Message.error("Unknown error\n$e"));
    } on SubscriberException catch (e) {
      if (e.code == MqttLocationPublisher.permissionDenied) {
        messageSink.add(Message.error("You rejected location permission\n"
            "Please, reconnect and confirm permission."));
      } else if (e.code == MqttLocationPublisher.serviceDisabled) {
        messageSink.add(Message.error("You have disabled location service\n"
            "Please, reconnect and confirm permission"));
      }
    } on PublisherException catch (e) {
      if (e.code == MqttLocationPublisher.serviceDisabled) {
        messageSink
            .add(Message.error("Please, enable GPS service and try again."));
      } else if (e.code == MqttLocationPublisher.permissionDenied) {
        messageSink
            .add(Message.error("Permission for GPS service is not granted"));
      }
    }

    _disconnectMqtt();
    return false;
  }

  void _disconnectMqtt() {
    _mqttPublishers.forEach((publisher) => publisher.stop());
    _mqttPublishers.clear();
    _mqttSubscribers.forEach((subscriber) => subscriber.stop());
    _mqttSubscribers.clear();
    _serviceSubscriberSink.add(_mqttSubscribers);
    _mqttClient?.onDisconnected = null;
    _mqttClient?.disconnect();
  }

  bool _disconnect() {
    _disconnectMqtt();
    messageSink.add(Message.success("Disconnected!"));
    return true;
  }
}
