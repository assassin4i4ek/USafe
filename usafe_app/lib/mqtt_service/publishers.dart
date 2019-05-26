import 'dart:async';
import 'package:location/location.dart';
import 'package:mqtt_client/mqtt_client.dart';

abstract class ServicePublisher {

}

abstract class MqttServicePublisher implements ServicePublisher {
  Future<void> start();
  void stop();
}

class MqttLocationPublisher implements MqttServicePublisher {
  String _helmetId;
  MqttClient _mqttClient;

  static String permissionDenied = "LOCATION_PERMISSION_DENIED";
  static String serviceDisabled = "LOCATION_SERVICE_DISABLED";

  StreamSubscription<LocationData> _streamSubscription;

  MqttLocationPublisher(this._helmetId, this._mqttClient);

  @override
  Future<void> start() async {
    Location location = Location();
    location.changeSettings(interval: 1000);

    if (!await location.hasPermission()) {
      if (!await location.requestPermission())
        throw PublisherException(MqttLocationPublisher.permissionDenied);
    }

    if (!await location.serviceEnabled()) {
      if (!await location.requestService()) {
        throw PublisherException(MqttLocationPublisher.serviceDisabled);
      } else {
        print('aaa');
      }
    }

    _streamSubscription = location.onLocationChanged()
        .handleError((e) {
          print("a");
        })
        .listen((locationData) {
      var builder = MqttClientPayloadBuilder();
      builder.addUTF8String('{"type": "location", "raw_value": {\n'
          '"latitude": ${locationData.latitude},\n'
          '"longitude": ${locationData.longitude},\n'
          '"accuracy": ${locationData.accuracy},\n'
          '"altitude": ${locationData.altitude},\n'
          '"speed": ${locationData.speed},\n'
          '"speedAccuracy": ${locationData.speedAccuracy},\n'
          '"heading": ${locationData.heading},\n'
          '"time": '
          '"${DateTime.fromMillisecondsSinceEpoch(locationData.time.toInt()).toIso8601String()}"\n'
          '}}');

      _mqttClient.publishMessage(
          "$_helmetId/location/raw/json", MqttQos.exactlyOnce, builder.payload);
    });

    return true;
  }

  @override
  void stop() {
    _streamSubscription?.cancel();
  }
}

class PublisherException {
  String code;
  PublisherException(this.code);
}