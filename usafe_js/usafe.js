//defines
const MQTT_SERVER = 'mqtt://m24.cloudmqtt.com';
const MQTT_PORT = 11714;
const MQTT_USER = 'qeozciql';
const MQTT_PASSWORD = 'rL4GWKmt99KZ';
const MQTT_CLIENT_ID = 'USafeServer';
//requires
var express = require('express');
var mqtt = require('mqtt');

//mqtt client
var mqttClient = mqtt.connect(MQTT_SERVER, {
	port: MQTT_PORT, 
	clientId: MQTT_CLIENT_ID,
	username: MQTT_USER,
	password: MQTT_PASSWORD
});

mqttClient.on('connect', () => {
	const supportedTopics = [
		'/+/vibration/raw',
		'/+/gas/raw',
		'/+/acceleration/raw',
		'/+/location/raw/json'];

	mqttClient.subscribe(supportedTopics, {qos: 2}, (err, granted) => {
		if (err) {
			console.log(err);
		}
		console.log(`Subscribed to topics:\n${
			granted.map(JSON.stringify).join('\n')}`);
	});
});

function processRawVibration(message) {
	try {
		var vibrationObj = JSON.parse(message.toString());
		console.log(vibrationObj);
	}
	catch (err) {
		conole.log('An error occured during decoding mqtt message', err);
	}
}

mqttClient.on('message', (topic, message) => {
	
});

// //express server
// var app = express();

// app.get('/', (req, res) => {
// 	res.send('Helloworld');
// });

// app.listen(8888, () => {
// 	console.log('Port 8888');
// });