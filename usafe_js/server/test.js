topic = '/helmet1/gas/raw'
const topicRegexp = /^\/(.+)\/(vibration|gas|acceleration|location)\/raw$/i;

var [, helmetId, dataType] = topic.match(topicRegexp);

console.log(helmetId, dataType);