#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Adafruit_BME680.h>
#include <FastLED.h>
// download from the library on github
// https://github.com/jmstriegel/Plantower_PMS7003
#include "Plantower_PMS7003.h"


// I2C pins for OLED
#define OLED_SDA 21
#define OLED_SCL 22

// SPI pins for BME
#define BME_CS 5
#define BME_SCK 18
#define BME_MISO 19
#define BME_MOSI 23

// UART pins for PMS7003
#define PMS_RXD 16
#define PMS_TXD 17

// buttons + led
#define LED_PIN 4
#define BUTTON_PIN 12

// BLE service
#define SERVICE_UUID "4d89d46f-20c2-4014-9b2f-4c57713f0a1e"
#define HUMIDITY_CHARACTERISTIC_UUID "4d89d46f-20c2-4014-9b2f-4c57713f0a1f"
#define TEMPERATURE_CHARACTERISTIC_UUID "4d89d46f-20c2-4014-9b2f-4c57713f0a20"
#define PRESSURE_CHARACTERISTIC_UUID "4d89d46f-20c2-4014-9b2f-4c57713f0a21"
#define PM2_5_CHARACTERISTIC_UUID "4d89d46f-20c2-4014-9b2f-4c57713f0a22"

// Constructors
Adafruit_SSD1306 display(128, 64, &Wire, -1);
Adafruit_BME680 bme(BME_CS, BME_MOSI, BME_MISO, BME_SCK);
CRGB leds[1];
Plantower_PMS7003 sensor = Plantower_PMS7003();

// display state management
enum DisplayMode {
    PME25_ONLY,
    TEMP_HUMIDITY,
    FULL_DATA
};

DisplayMode currentMode= PM25_ONLY;
BLECharacteristic *pHumidityCharacteristic;
BLECharacteristic *pTemperatureCharacteristic;
BLECharacteristic *pPressureCharacteristic;
BLECharacteristic *pPM2_5Characteristic;

// Setup function
void setup() {
    Serial.begin(115200);
    Wire.begin(OLED_SDA, OLED_SCL);
    if (!display.begin(SSD1306_SWITCHCAPVCC,0x3C)){
        Serial.println(F("SSD1306 allocation failed"));
        for (;;);
    }
    display.display();
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0,0);

    Serial2.begin(9600, SERIAL_8N1, PMS_RXD, PMS_TXT);
    sensor.init(&Serial2);

    FastLED.addLeds<WS2812B, LED_PIN, GRB>(leds, 1);
    pinMode(BUTTON_PIN, INPUT_PULLUP);

    // create BLE to connect to the mobile app
    BLEDevice::init("CanAirIO Monitor");
    BLEServer *pServer = BLEDevice::createServer();
    BLEService *pService = pServer->createService(SERVICE_UUID);

    // create a characteristic for EACH sensor reading and add it to the service
    pHumidityCharacteristic = pService->createCharacteristic(
                                         HUMIDITY_CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_NOTIFY
                                       );
    pTemperatureCharacteristic = pService->createCharacteristic(
                                         TEMPERATURE_CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_NOTIFY
                                       );
    pPressureCharacteristic = pService->createCharacteristic(
                                         PRESSURE_CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_NOTIFY
                                       );
    pPM2_5Characteristic = pService->createCharacteristic(
                                         PM2_5_CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ |
                                         BLECharacteristic::PROPERTY_NOTIFY
                                       );

    pService->start();

    BLEAdvertising *pAdvertising = pServer->getAdvertising();
    pAdvertising->start();
}

// loop

void loop() {
    sensor.updateFrame();
    if (sensor.hasNewData()) {
        int pm2_5_value = sensor.getPM_2_5();
        int pm1_0_value = sensor.getPM_1_0();
        int pm10_0_value = sensor.getPM_10_0();

        // this is basically wiring the led based on the the pm reading
        // to indicate quickly the safety
        // <12 green, < 35 moderate, >35 bad
        if (pm2_5_value < 12) {
            leds[0] = CRGB::Green;
        } else if (pm2_5_value < 35) {
            leds[0] = CRGB::Yellow;
        } else {
            leds[0] = CRGB::Red;
        }
        FastLED.show();
    }


    float temp = bme.temperature;
    float humidity = bme.humidity;
    float pressure = bme.pressure;
    float gas_resistance = bme.gas_resistance;

//    display.clearDisplay();
//    display.setCursor(0,0);
//    display.println("air quality monitor");
//    display.print("PM2.5: "); display.println(sensor.getPM_2_5());
//    display.print("Temp: "); display.println(temp);
//    display.print("Humid: "); display.println(humidity);
//    display.display();

    pHumidityCharacteristic->setValue((uint8_t*)&humidity, sizeof(humidity));
    pTemperatureCharacteristic->setValue((uint8_t*)&temp, sizeof(temp));
    pPressureCharacteristic->setValue((uint8_t*)&pressure, sizeof(pressure));
    pPM2_5Characteristic->setValue((uint8_t*)&pm2_5_value, sizeof(pm2_5_value));

    pHumidityCharacteristic->notify();
    pTemperatureCharacteristic->notify();
    pPressureCharacteristic->notify();
    pPM2_5Characteristic->notify();



    if (digitalRead(BUTTON_PIN) == LOW) {
        delay(50);
        if (digitalRead(BUTTON_PIN) == LOW) {
            switch (currentMode) {
                case PM25_ONLY:
                    currentMode = TEMP_HUMIDITY;
                    break;
                case TEMP_HUMIDITY:
                    currentMode = FULL_DATA;
                    break;
                case FULL_DATA:
                    currentMode = PM25_ONLY;
                    break;
            }
            while (digitalRead(BUTTON_PIN) == LOW) {}
        }
    }

    display.clearDisplay();
    display.setCursor(0,0);

    switch (currentMode) {
        case PM25_ONLY:
            display.println("PM2.5:");
            display.println(sensor.getPM_2_5());
            break;
        case TEMP_HUMIDITY:
            display.println("Temperature:");
            display.println(bme.temperature);
            display.println("Humidity:");
            display.println(bme.humidity);
            break;
        case FULL_DATA:
            display.println("PM2.5: " + String(sensor.getPM_2_5()));
            display.println("Temp: " + String(bme.temperature));
            display.println("Humidity: " + String(bme.humidity));
            break;
    }

  display.display();
  delay(100);


}