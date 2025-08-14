
The air we breathe is becoming increasingly polluted, especially in urban areas or places impacted by wildfire.

The World Health Organization believes that 29% of lung cancer, 24% of stroke, 25% of heart disease and 43% of lung disease deaths are due to air pollution. 92% of the world's population cannot breathe safe air, and 7 million people die directly or indirectly from air pollution each year. 

(https://www.curiejet.com/en/product/air-quality-monitor/wearable-pm25-air-quality-monitor)

The most at risk populations include the elderly, people with asthma, pregnant women, and those with other chronic conditions.  
These people should have some way of recognizing when the air quality around them is bad using PM sensors (Particulate Matter - tiny particles that penetrate the lungs), gas sensors that sense CO, O3 and VOCs (Volatile Organic Components). 

I'd like to come up with a sleek, wearable device that can provide real-time information to users about the air quality around them so that they can become informed about their immediate environments and take appropriate precautions. 

Wednesday, August 13 - 9 hours
I created the schematic with all of the components. I had to make the kicad compatiable PMS7003 footprint and symbol. 

Components List:
BT1: Battery

C1,C2,C3,C4,C5,C6,C9: Capacitor_NP

C7,C8: 100nF_Ceramic

D1: WS2812B

J1: Conn_01x02_Socket

J2: USB_C_Receptacle_PowerOnly_6P

R1,R2,R3,R4,R5: Resistor

SW1: SW_Push

SW2: SW_SPDT

U1: ESP32-WROOM-32

U2: TP4056-42-ESOP8

U3: AP2112K-3.3

U4: BME680

U5: PMS7003

U6: DM-OLED096-636

I wrote the firmware in /Firmware/firmware.cpp for Arduino. The code runs on the ESP32 and reads the data from the two sensors (BME680 and PMS7003). It processes the raw data and uses bluetooth to transfer data to my server on my computer.
Then I created the Node.js backend server. It listens to the physical device's firmware. There is an organized API endpoint /api/data that the mobile app can access. 
The IOS app made with Swift can make network requests to the Node.js server, fetch the sensor data, and display it in a UITableView. I also configured the app's security settings so it could successfully connect to your server. 

I need to make the PCB, test the app and run the Node.js backend to make sure everything is working. I'm not going to make the database because my local device has issues with MySQL that need to be mitigated before I can create the database. But I need to make sure my dummy data is functional. 