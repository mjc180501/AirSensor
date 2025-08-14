Air Quality Monitor Project
This project is a multi-component system designed to monitor and display real-time air quality data. It includes a physical sensor device, custom firmware, a mobile application, and a backend server for data handling.

Project Status
This project is currently in progress. The hardware, firmware, and iOS app are under active development.

Project Components
1. Hardware and Schematics
The physical device is an air quality monitor designed in KiCad. It integrates several sensors, including a BME680 for environmental data and a PMS7003 for particulate matter, along with an ESP32 microcontroller and an OLED display.

2. Firmware
The firmware is written in C++ for the ESP32-WROOM-32. It performs the following functions:

  - Reads data from the connected BME680 and PMS7003 sensors.

  - Broadcasts the sensor readings over Bluetooth Low Energy (BLE).

  - Controls a status LED and an OLED display to provide visual feedback and show sensor data locally.

  - Manages user input via a button to cycle through different display modes.

3. iOS App (Client)
The iOS application serves as a BLE client. It is designed to:

  - Scan for and connect to the air quality monitor device.

  - Receive real-time sensor data from the device's BLE service.

  - Display the temperature, humidity, pressure, and PM2.5 values in a user- friendly interface.

4. Backend API (Server)
This component is a Node.js server intended to act as a central hub for the data. In future development, the server will receive data from the physical device and store it, allowing for historical data analysis and remote access.

Getting Started
To get the project running, you will need to:

  - Flash the firmware onto the ESP32 device.

  - Run the Node.js server on your local machine.

  - Build and run the iOS app on an iPhone with Bluetooth enabled to connect to the device.

Contributing
Contributions are welcome! Please feel free to open an issue or submit a pull request.
