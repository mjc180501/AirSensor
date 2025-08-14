import UIKit
import CoreBluetooth

struct SensorReading: Decodable {
    var humidity: Float?
    var temperature: Float?
    var pressure: Float?
    var pm2_5: Float?
    var timestamp: String?
}

class SensorReadingCell: UITableViewCell {
    
    let humidityLabel = UILabel()
    let temperatureLabel = UILabel()
    let pm2_5Label = UILabel()
    let pressureLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let stackView = UIStackView(arrangedSubviews: [temperatureLabel, humidityLabel, pressureLabel, pm2_5Label])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with reading: SensorReading) {
        temperatureLabel.text = "Temperature: \(reading.temperature ?? 0, specifier: "%.2f")°C"
        humidityLabel.text = "Humidity: \(reading.humidity ?? 0, specifier: "%.2f")%"
        pressureLabel.text = "Pressure: \(reading.pressure ?? 0, specifier: "%.2f")"
        pm2_5Label.text = "PM2.5: \(reading.pm2_5 ?? 0, specifier: "%.2f")"
        
        if let pm2_5 = reading.pm2_5 {
            if pm2_5 < 12 {
                pm2_5Label.textColor = .systemGreen
            } else if pm2_5 < 35 {
                pm2_5Label.textColor = .systemYellow
            } else {
                pm2_5Label.textColor = .systemRed
            }
        }
    }
}


class ViewController: UIViewController, UITableViewDataSource, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private let tableView = UITableView()
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral?
    
    let serviceUUID = CBUUID(string: "4d89d46f-20c2-4014-9b2f-4c57713f0a1e")
    let humidityCharacteristicUUID = CBUUID(string: "4d89d46f-20c2-4014-9b2f-4c57713f0a1f")
    let temperatureCharacteristicUUID = CBUUID(string: "4d89d46f-20c2-4014-9b2f-4c57713f0a20")
    let pressureCharacteristicUUID = CBUUID(string: "4d89d46f-20c2-4014-9b2f-4c57713f0a21")
    let pm2_5CharacteristicUUID = CBUUID(string: "4d89d46f-20c2-4014-9b2f-4c57713f0a22")
    
    var currentSensorReading: SensorReading = SensorReading()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - UI Setup
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(SensorReadingCell.self, forCellReuseIdentifier: "SensorReadingCell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Central manager is powered on. Scanning for device...")
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        } else {
            print("Bluetooth is not available.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered peripheral: \(peripheral.name ?? "Unknown")")
        
        centralManager.stopScan()
        
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(peripheral.name ?? "Unknown")")
        peripheral.discoverServices([serviceUUID])
    }

    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            print("Discovered service: \(service.uuid)")
            
            peripheral.discoverCharacteristics([humidityCharacteristicUUID, temperatureCharacteristicUUID, pressureCharacteristicUUID, pm2_5CharacteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid)")
            
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        let value = data.withUnsafeBytes { $0.load(as: Float.self) }
        
        if characteristic.uuid == humidityCharacteristicUUID {
            currentSensorReading.humidity = value
        } else if characteristic.uuid == temperatureCharacteristicUUID {
            currentSensorReading.temperature = value
        } else if characteristic.uuid == pressureCharacteristicUUID {
            currentSensorReading.pressure = value
        } else if characteristic.uuid == pm2_5CharacteristicUUID {
            currentSensorReading.pm2_5 = value
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SensorReadingCell", for: indexPath) as? SensorReadingCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: currentSensorReading)
        return cell
    }
}

