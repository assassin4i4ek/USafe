var EventEmitter = require('events').EventEmitter;
var util = require('util');

class UsafeServiceProvider {
	constructor() {
		EventEmitter.call(this);
		this.services = new Map();
	}

	processRaw(helmetId, dataType, data) {
		if (!this.services.has(helmetId)) {
			var helmetService = new HelmetService();
			helmetService.on('alert', (alertObject) => {
				this.emit(alertObject['type'], helmetId, alertObject);
			})
			this.services.set(helmetId, helmetService);
		}

		helmetService = this.services.get(helmetId);
		helmetService.processRaw(data);
	}

	confirmAlert(helmetId, dataType, data) {
		if (this.services.has(helmetId)) {
			this.services.get(helmetId).confirmAlert(data);
		}
	}
}

class HelmetService {
	constructor() {
		EventEmitter.call(this);
		this.VIBRATION_THRESHOLD = 20000;
		this.GAS_MEDIUM_THRESHOLD = 1500;
		this.GAS_HIGH_THRESHOLD = 1700;
		this.ACCELERATION_THRESHOLD = 0.05;
		this.ACCELERATION_TIMEOUT = 10000;
		this.vibrationBlockingAlert = new BlockingStatus({
			type: 'vibration',
			level: 'low',
			needs_confirmation: 'false'
		});
		this.gasBlockingAlert = new BlockingStatus({
			type: 'gas',
			level: 'low',
			needs_confirmation: 'false'
		});
		this.accelerationAlert = {
			type: 'acceleration',
			level: 'low',
			needs_confirmation: 'false'
		};
	}

	processRaw(data) {
		switch (data['type']) {
			case 'gas':
				this.processRawGas(data);
				break;
			case 'acceleration':
				this.processRawAcceleration(data);
				break;
			case 'vibration':
				this.processRawVibration(data);
				break;
			case 'location':
				this.processRawLocation(data);
				break;
			default: 
				throw 'Unsupported service for type: ' + data['type'];
		}
	}

	confirmAlert(data) {
		switch (data['type']) {
			case 'gas':
				this.confirmGasAlert(data);
				break;
			case 'acceleration':
				this.confirmAccelerationAlert(data);
				break;
			case 'vibration':
				this.confirmVibrationAlert(data);
				break;
			case 'location':
				this.confirmLocationAlert(data);
				break;
			default: 
				throw 'Unsupported service for type: ' + data['type'];
		}
	}

	processRawVibration(rawVibration) {
		if (rawVibration['raw_value'] > this.VIBRATION_THRESHOLD) {
			this.vibrationBlockingAlert.currentStatus.level = 'medium';
			this.vibrationBlockingAlert.currentStatus.needs_confirmation = 'true';
			this.vibrationBlockingAlert.blockingStatus.level = 'medium';
			this.vibrationBlockingAlert.blockingStatus.needs_confirmation = 'true';
			this.vibrationBlockingAlert.block();
		}
		else {
			this.vibrationBlockingAlert.currentStatus.level = 'low';
			this.vibrationBlockingAlert.currentStatus.needs_confirmation = 'false';
		}

		this.emit('alert', this.vibrationBlockingAlert.getStatus());
	}

	confirmVibrationAlert(vibrationAlert) {
		if (vibrationAlert['level'] == this.vibrationBlockingAlert.blockingStatus.level) {
			if (vibrationAlert['confirmation'] == 'true') {
				this.vibrationBlockingAlert.unblock();
			}
		}

		this.emit('alert', this.vibrationBlockingAlert.getStatus());
	}

	processRawGas(rawGas) {
		if (rawGas['raw_value'] > this.GAS_HIGH_THRESHOLD) {
			if (this.gasBlockingAlert.currentStatus.level != 'high') {
				//current status == {low | medium}
				this.gasBlockingAlert.blockingStatus.level = 'high';
				this.gasBlockingAlert.blockingStatus.needs_confirmation = 'true';
				this.gasBlockingAlert.block();
			}

			this.gasBlockingAlert.currentStatus.level = 'high';
		}
		else if (rawGas['raw_value'] > this.GAS_MEDIUM_THRESHOLD) {
			if (!['high', 'medium'].includes(this.gasBlockingAlert.currentStatus.level)) {
				//current status == low
				this.gasBlockingAlert.blockingStatus.level = 'medium';
				this.gasBlockingAlert.blockingStatus.needs_confirmation = 'true';
				this.gasBlockingAlert.block();
			}

			this.gasBlockingAlert.currentStatus.level = 'medium';
		}
		else {
			this.gasBlockingAlert.currentStatus.level = 'low';
			this.gasBlockingAlert.currentStatus.needs_confirmation = 'false';
			this.gasBlockingAlert.unblock();
		}

		this.emit('alert', this.gasBlockingAlert.getStatus());
	}

	confirmGasAlert(gasAlert) {
		if (gasAlert['level'] == this.gasBlockingAlert.blockingStatus.level) {
			if (gasAlert['confirmation'] == 'true') {
				this.gasBlockingAlert.currentStatus.needs_confirmation = 'false';
				this.gasBlockingAlert.unblock();
			}
		}

		this.emit('alert', this.gasBlockingAlert.getStatus());
	}

	processRawAcceleration(rawAcceleration) {
		if (!this.prevAcceleration) {
			this.prevAcceleration = rawAcceleration['raw_value'];
		}
		else {
			var del1 = this.delta(rawAcceleration['raw_value'], this.prevAcceleration);
			if (del1 < this.ACCELERATION_THRESHOLD) {
				if (!this.accelerationTimeout) {
					this.accelerationTimeout = setTimeout((prev) => {
						var del2 = this.delta(prev, this.prevAcceleration);
						if (del2 < this.ACCELERATION_THRESHOLD) {
							this.accelerationAlert.level = 'medium';
						}
					}, this.ACCELERATION_TIMEOUT, rawAcceleration['raw_value']);
				}
			}
			else {
				if (this.accelerationTimeout) {
					clearTimeout(this.accelerationTimeout);
					this.accelerationTimeout = null;
				}
				
				this.accelerationAlert.level = 'low';
			}

			this.prevAcceleration = rawAcceleration['raw_value'];
		}

		this.emit('alert', this.accelerationAlert);
	}

	confirmAccelerationAlert(accelerationAlert) {

	}

	delta(vec1, vec2) {
		var delta = 0;
		for (var coord in vec1) {
			delta += Math.pow(vec1[coord] - vec2[coord], 2);
		}

		return delta;
	}

	processRawLocation(rawLocation) {

	}

	confirmLocationAlert(locationAlert) {

	}
}

class BlockingStatus {
	constructor(defaultStatus) {
		this.currentStatus = defaultStatus;
		this.blockingStatus = Object.assign({}, defaultStatus);
		this.isBlocked = false;
	}

	block() {
		this.isBlocked = true;
	}

	unblock() {
		this.isBlocked = false;;
	}

	getStatus() {
		if (this.isBlocked) {
			return this.blockingStatus;
		}
		else {
			return this.currentStatus;
		}
	}
}

util.inherits(UsafeServiceProvider, EventEmitter);
util.inherits(HelmetService, EventEmitter);

module.exports = UsafeServiceProvider;