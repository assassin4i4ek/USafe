import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:rxdart/subjects.dart';

enum StatusLevel { LOW, MEDIUM, HIGH }

class StatusLevelHelper {
  static StatusLevel fromString(String statusLevel) {
    switch (statusLevel.toLowerCase()) {
      case "low":
        return StatusLevel.LOW;
      case "medium":
        return StatusLevel.MEDIUM;
      case "high":
        return StatusLevel.HIGH;
      default:
        throw FormatException();
    }
  }

  static String convertToString(StatusLevel statusLevel) {
    switch (statusLevel) {
      case StatusLevel.LOW:
        return "low";
      case StatusLevel.MEDIUM:
        return "medium";
      case StatusLevel.HIGH:
        return "high";
    }
  }
}

class StatusInfo {
  String type;
  StatusLevel level;
  bool needsConfirmation;

  StatusInfo(this.type, this.level, this.needsConfirmation);

  StatusInfo.fromJson(Map<String, dynamic> json)
      : this(json["type"], StatusLevelHelper.fromString(json["level"]),
            _toBool(json["needs_confirmation"] as String));

  static bool _toBool(String value) {
    switch (value.toLowerCase()) {
      case "true":
        return true;
      case "false":
        return false;
      default:
        throw FormatException();
    }
  }
}

abstract class ServiceSubscriber {
  Stream<StatusInfo> get onNewStatusInfo;
  String get serviceDescription;

  void confirmStatusInfo(StatusInfo status);
}

class MqttServiceSubscriber extends ServiceSubscriber {
  @override
  Stream<StatusInfo> get onNewStatusInfo => _statusInfoController.stream;
  @override
  String get serviceDescription => _serviceDescription;

  String _serviceDescription;
  String _statusTopic;
  String _confirmationTopic;
  MqttClient _mqttClient;
  StreamSubscription _streamSubscription;
  String _typeFilter;
  StreamController<StatusInfo> _statusInfoController = BehaviorSubject();
//      StreamController.broadcast();

  static String wrongDataFormat = "WRONG_DATA_FORMAT";
  static String unsupportedService = "UNSUPPORTED_SERVICE";
  static String unknownError = "UNKNOWN_ERROR";

  MqttServiceSubscriber._(this._serviceDescription, this._statusTopic,
      this._confirmationTopic, this._mqttClient,
      [this._typeFilter]);

  factory MqttServiceSubscriber.forService(
      String serviceName, String helmetId, MqttClient mqttClient) {
    MqttServiceSubscriber subscriber;
    switch (serviceName) {
      case "gas":
        subscriber = MqttServiceSubscriber._("Gas level", "/$helmetId/gas/alert",
            "/$helmetId/gas/confirmations", mqttClient, "gas");
        break;
      case "vibration":
        subscriber = MqttServiceSubscriber._(
            "Knock",
            "/$helmetId/vibration/alert",
            "/$helmetId/vibration/confirmations",
            mqttClient,
            "vibration");
        break;
      case "acceleration":
        subscriber = MqttServiceSubscriber._(
            "Movement",
            "/$helmetId/acceleration/alert",
            "/$helmetId/acceleration/confirmations",
            mqttClient,
            "acceleration");
        break;
      default:
//        throw ServiceException(MqttServiceSubscriber.unsupportedService);
    }

    return subscriber;
  }

  void start() {
    _streamSubscription = _mqttClient.updates.listen((messages) {
      String newMessage = lastTopicMessageToString(messages);
      if (newMessage != null) {
        try {
          dynamic object = json.decode(newMessage);
          if (!(object is Map<String, dynamic>)) {
            throw SubscriberException(MqttServiceSubscriber.wrongDataFormat,
                "Wrong data format appeared in topic");
          }
          StatusInfo statusInfo = StatusInfo.fromJson(object);

          if (_typeFilter == null || _typeFilter == statusInfo.type) {
            _statusInfoController.add(statusInfo);
          } else {
            throw SubscriberException(MqttServiceSubscriber.wrongDataFormat,
                "Wrong status info appeared in topic");
          }
        } on SubscriberException catch (e) {
          _statusInfoController.addError(e);
        } on Exception {
          _statusInfoController.addError(
              SubscriberException(MqttServiceSubscriber.unknownError));
        }
      }
    });

    _mqttClient.subscribe(_statusTopic, MqttQos.exactlyOnce);
  }

  String lastTopicMessageToString(
      List<MqttReceivedMessage<MqttMessage>> messages) {
    var message = (messages
            .firstWhere((m) => m.topic == _statusTopic, orElse: () => null)
            ?.payload as MqttPublishMessage)
        ?.payload
        ?.message;

    return message != null
        ? MqttPublishPayload.bytesToStringAsString(message)
        : null;
  }

  void stop() {
    if (_mqttClient.connectionStatus.state == MqttConnectionState.connected) {
      _mqttClient.unsubscribe(_statusTopic);
    }
    _streamSubscription.cancel();
    _statusInfoController.close();
  }

  @override
  void confirmStatusInfo(StatusInfo status) {
    MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addUTF8String('{'
        '"type": "${status.type}",'
        '"level": "${StatusLevelHelper.convertToString(status.level)}",'
        '"confirmation": "true"'
        '}');
    _mqttClient.publishMessage(
        _confirmationTopic, MqttQos.exactlyOnce, builder.payload);
  }
}

class SubscriberException {
  String code;

  var description;
  SubscriberException([this.code = "", this.description = ""]);
}
