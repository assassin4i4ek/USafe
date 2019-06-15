//defines
const MQTT_SERVER = 'mqtt://m24.cloudmqtt.com';
const MQTT_PORT = 11714;
const MQTT_USER = 'qeozciql';
const MQTT_PASSWORD = 'rL4GWKmt99KZ';
const MQTT_CLIENT_ID = 'USafeTest';
//requires
const mqtt = require('mqtt');

//mqtt client
const mqttClient = mqtt.connect(MQTT_SERVER, {
	port: MQTT_PORT, 
	clientId: MQTT_CLIENT_ID,
	username: MQTT_USER,
	password: MQTT_PASSWORD
});

//app service
const supportedTopics = [
		'/+/vibration/alert',
		'/+/gas/alert',
		'/+/acceleration/alert',
		'/+/location/alert'];

mqttClient.on('connect', () => {
	console.log('connected...');
	mqttClient.subscribe(supportedTopics, {qos: 2}, (err, granted) => {
		if (err) {
			console.log(err);
		}
		else {
			var prev = [];
			var now = [];
			const N = 100;

			function sleep(ms){
			    return new Promise(resolve=>{
			        setTimeout(resolve,ms)
			    })
			}

			async function repeat() {
				async function callback (i) {
					mqttClient.publish(`/helmet${i}/gas/raw`, '{"type": "gas", "raw_value": 10000}', {qos: 2});
					mqttClient.publish(`/helmet${i}/acceleration/raw`, '{"type": "acceleration", "raw_value": {	"x": 0.5,	"y": 0.6,	"z": 0.7}}', {qos: 2});
					mqttClient.publish(`/helmet${i}/vibration/raw`, '{"type": "vibration", "raw_value": 10001}', {qos: 2});
					console.log(`message${i}`);
					prev[i] = Date.now();
				};
				for (var i = 0; i < N; i++) {
					await callback(i);					
				}
			};

			var j = 0;

			mqttClient.on('message', async (topic, message) => {
				now[j] = [topic, Date.now()];
				console.log(`recieved ${j}`);
				j = j + 1;

				if (j == 3 * N) {
					// console.log(now);
					now = now.sort((a, b) => {
						const rex = /^\/helmet(\d+)\/.*/;
						aId = a[0].match(rex)[1];
						bId = b[0].match(rex)[1];
						return aId - bId;
					})
					.map((a) => a[1])
					.reduce((result, next, index) => {
						if (index % 3 == 0) {
							result.push(next);
						}
						else {
							result[result.length - 1] = Math.max(result[result.length - 1], next);
						}
						return result;
					}, []);

					// console.log(now);

					for (var i = 0; i < now.length; i++) {
						console.log(now[i] - prev[i]); 
					}

					now = [];

					j = 0;
					// repeat();
				}
			});

			repeat();
		}
	});
});

