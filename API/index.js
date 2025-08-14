const express = require('express');
const bodyParser = require('body-parser');
const app = express();
const port = 3000;

const sensorReadings = [];

app.use(bodyParser.json());

app.post('/api/data', (req, res) => {

    const { humidity, temperature, pressure, pm2_5 } = req.body;

    if (humidity || temperature || pressure || pm2_5) {
        const newReading = {
            humidity: humidity,
            temperature: temperature,
            pressure: pressure,
            pm2_5: pm2_5,
            timestamp: new Date().toISOString()
        };
        sensorReadings.push(newReading);
        console.log('New Reading Received', newReading);
        res.status(201).send({ message: 'Data stored successfully' });
    } else {
        res.status(400).send({ message: 'Sensor data is required'});
    }
});

app.get('/api/data', (req, res) => {
    res.status(200).send(sensorReadings);
});

app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});