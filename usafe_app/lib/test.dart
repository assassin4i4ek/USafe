import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:mqtt_client/mqtt_client.dart';

void main() => runApp(TestApp());

class TestApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.bluetooth),
            onPressed: mqtt,
        )
      ),
    );
  }

  bluetooth() {
    FlutterBlue flutterBlue = FlutterBlue.instance;
    StreamSubscription scan;
    scan = flutterBlue.scan().listen((scanResult) {
      if (scanResult.device.name == 'helmet1' &&
          scanResult.advertisementData.serviceUuids
              .contains("39b8f144-d224-49d4-9226-23d857ce200c")) {
        scan.cancel();

        StreamSubscription connect;
        BluetoothDevice device = scanResult.device;
        connect = flutterBlue.connect(device).listen((state) {
          if (state == BluetoothDeviceState.connected) {
            device.discoverServices().then((services) {
              BluetoothService service = services.firstWhere(
                      (service) =>
                  service.uuid ==
                      Guid("39b8f144-d224-49d4-9226-23d857ce200c"));

              BluetoothCharacteristic gasCharacteristic =
              service.characteristics.firstWhere((ch) =>
              ch.uuid ==
                  Guid("57d63d58-4e7d-4327-9832-dfc284d2fc89"));
              BluetoothCharacteristic accelerationCharacteristic =
              service.characteristics.firstWhere((ch) =>
              ch.uuid ==
                  Guid("e2a996df-1601-4a70-a61c-56791f2ec236"));
              BluetoothCharacteristic vibrationCharacteristic =
              service.characteristics.firstWhere((ch) =>
              ch.uuid ==
                  Guid("3e887a0d-f703-489d-a701-8dbec9298649"));

              var readAll;
              var prev;
              readAll = () async {
                prev = DateTime.now();

                String gas = String.fromCharCodes(await device
                    .readCharacteristic(gasCharacteristic));
                String acceleration = String.fromCharCodes(
                    await device.readCharacteristic(
                        accelerationCharacteristic));
                String vibration = String.fromCharCodes(await device
                    .readCharacteristic(vibrationCharacteristic));

                var now = DateTime.now();

                print(now.millisecondsSinceEpoch - prev.millisecondsSinceEpoch);
                readAll();
              };

              readAll();
            });
          }
        });
      }
    });
  }

  mqtt() async {
    String server = "m24.cloudmqtt.com";
    String clientId = "+380999999999";
    String username = "qeozciql";
    String password = "rL4GWKmt99KZ";
    int port = 11714;
    MqttClient _mqttClient = MqttClient.withPort(server, clientId, port);

    await _mqttClient.connect(username, password);

    DateTime now, prev = DateTime.now();
    int count = 3;
    var runAll;
    runAll = () {
      count += 1;
      if (count >= 3) {
        now = DateTime.now();
        print(now.millisecondsSinceEpoch - prev.millisecondsSinceEpoch);
        count = 0;
        MqttClientPayloadBuilder mqttPayloadBuilder;
        mqttPayloadBuilder = MqttClientPayloadBuilder();
        mqttPayloadBuilder.addUTF8String(
"""{
	"type": "gas",
	"raw_value": 2000
}""");
        _mqttClient.publishMessage("/helmet1/gas/raw", MqttQos.exactlyOnce, mqttPayloadBuilder.payload);
        mqttPayloadBuilder = MqttClientPayloadBuilder();
        mqttPayloadBuilder.addUTF8String(
            """{
	"type": "vibration",
	"raw_value": 10001
}""");
        _mqttClient.publishMessage("/helmet1/vibration/raw", MqttQos.exactlyOnce, mqttPayloadBuilder.payload);
        mqttPayloadBuilder = MqttClientPayloadBuilder();
        mqttPayloadBuilder.addUTF8String(
            """{
	"type": "acceleration",
	"raw_value": {
		"x": 0.5,
		"y": 0.6,
		"z": 0.7
	}
}""");
        _mqttClient.publishMessage("/helmet1/acceleration/raw", MqttQos.exactlyOnce, mqttPayloadBuilder.payload);
        prev = DateTime.now();
      }
    };
    _mqttClient.subscribe("/helmet1/gas/alert", MqttQos.exactlyOnce);
    _mqttClient.subscribe("/helmet1/acceleration/alert", MqttQos.exactlyOnce);
    _mqttClient.subscribe("/helmet1/vibration/alert", MqttQos.exactlyOnce);
    _mqttClient.updates.listen((messages) {
      var message = getMessageForTopic("/helmet1/gas/alert", messages);
      if (message != null) {
        runAll();
      }
    });
    _mqttClient.updates.listen((messages) {
      var message = getMessageForTopic("/helmet1/acceleration/alert", messages);
      if (message != null) {
        runAll();
      }
    });
    _mqttClient.updates.listen((messages) {
      var message = getMessageForTopic("/helmet1/vibration/alert", messages);
      if (message != null) {
        runAll();
      }
    });
    prev = DateTime.now();
    runAll();
  }
}

getMessageForTopic(String topic, List<MqttReceivedMessage<MqttMessage>> messages) {
    var message = (messages
        .firstWhere((m) => m.topic == topic, orElse: () => null)
        ?.payload as MqttPublishMessage)
        ?.payload
        ?.message;

    return message != null
        ? MqttPublishPayload.bytesToStringAsString(message)
        : null;
}
