//defines
const MQTT_SERVER = 'mqtt://m24.cloudmqtt.com';
const MQTT_PORT = 11714;
const MQTT_USER = 'qeozciql';
const MQTT_PASSWORD = 'rL4GWKmt99KZ';
const MQTT_CLIENT_ID = 'USafeServer';
//requires
var express = require('express');
var mqtt = require('mqtt');
var UsafeServiceProvider = require('./usafe-service');

//mqtt client
var mqttClient = mqtt.connect(MQTT_SERVER, {
	port: MQTT_PORT, 
	clientId: MQTT_CLIENT_ID,
	username: MQTT_USER,
	password: MQTT_PASSWORD
});

//app service
const supportedTopics = [
		'/+/vibration/raw',
		'/+/gas/raw',
		'/+/acceleration/raw',
		'/+/location/raw',
		'/+/vibration/confirmations',
		'/+/gas/confirmations',
		'/+/acceleration/confirmations'];
const topicRegexp = /^\/(.+)\/(vibration|gas|acceleration|location)\/(raw|confirmations)$/i;

var serviceProvider = new UsafeServiceProvider();
serviceProvider.on('gas', (helmetId, data) => {
	mqttClient.publish(`/${helmetId}/gas/alert`, JSON.stringify(data), {qos: 2});
});
serviceProvider.on('acceleration', (helmetId, data) => {
	mqttClient.publish(`/${helmetId}/acceleration/alert`, JSON.stringify(data), {qos: 0});
});
serviceProvider.on('vibration', (helmetId, data) => {
	mqttClient.publish(`/${helmetId}/vibration/alert`, JSON.stringify(data), {qos: 0});
});

mqttClient.on('connect', () => {
	mqttClient.subscribe(supportedTopics, {qos: 2}, (err, granted) => {
		if (err) {
			console.log(err);
		}
		console.log(`Subscribed to topics:\n${
			granted.map(JSON.stringify).join('\n')}`);
	});
});

mqttClient.on('message', (topic, message) => {
	try {
		var [, helmetId, dataType, dataSource] = topic.match(topicRegexp);
		var data = JSON.parse(message.toString());
		
		if (data['type'] != dataType) {
			throw 'Invalid data type in topic ' + topic;
		}	

		if (dataSource == 'raw') {
			serviceProvider.processRaw(helmetId, dataType, data);
		}
		else if (dataSource == 'confirmations') {
			serviceProvider.confirmAlert(helmetId, dataType, data);
		}
	}
	catch (err) {
		console.log('An error occured during decoding mqtt message: ', err);
	}
});

// //express server
// var app = express();

// app.get('/', (req, res) => {
// 	res.send('Helloworld');
// });

// app.listen(8888, () => {
// 	console.log('Port 8888');
// });