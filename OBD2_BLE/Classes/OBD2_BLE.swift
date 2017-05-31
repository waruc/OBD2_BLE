//
//  OBD2_BLE.swift
//  Pods
//
//  Created by Nicholas Nordale on 5/31/17.
//
//

import Foundation
import CoreBluetooth
import Alamofire
import SwiftyJSON

public class OBD2_BLE: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    var centralManager: CBCentralManager!
    var obd2: CBPeripheral?
    var dataCharacteristic:CBCharacteristic?
    
    var obdCommands:[String: String]! = [
        "speed": "010D",
        "vin": "0902"
    ]
    
    var configurationCommands = [
        "ATE0",
        "ATH0",
        "ATS0",
        "ATL0",
        "ATSP0"
    ]

    var obdResponse:[UInt8] = []
    let endOfResponseNotificationIdentifier = Notification.Name("endOfResponseNotificationIdentifier")

    // setupOutput is expected output from device after reset (no prior configuration)
    // partialsetupOutput is expected output from device without reset (device remained configured from previous run)
    let restartSetupOutput = "\r\rELM327 v1.5\r\r>ATE0\rOK\r\r>OK\r\r>OK\r\r>OK\r\r>OK\r\r>"
    let setupOutput = "ATE0\rOK\r\r>OK\r\r>OK\r\r>OK\r\r>OK\r\r>"
    let partialsetupOutput = "OK\r\r>OK\r\r>OK\r\r>OK\r\r>OK\r\r>"
    var setupComplete = false

    var vinNumber:String?
    
    static let sharedInstance = OBD2_BLE()
    private static let setup = OBD2_BLESetup()
    
    class func setup(restoreId: String) {
        OBD2_BLE.setup.restoreId = restoreId
    }
    
    public override init() {
        super.init()
        
        let restoreId = OBD2_BLE.setup.restoreId
        
        if restoreId == nil {
            self.initWithoutBackground()
        } else {
            self.initWithBackground(restoreId: restoreId!)
        }
    }
    
    internal func initWithoutBackground() {
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    
    internal func initWithBackground(restoreId: String) {
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey : restoreId])
    }
    
    @available(iOS 5.0, *)
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            print("Bluetooth on this device is currently powered off.")
        case .unsupported:
            print("This device does not support Bluetooth Low Energy.")
        case .unauthorized:
            print("This app is not authorized to use Bluetooth Low Energy.")
        case .resetting:
            print("The BLE Manager is resetting; a state update is pending.")
        case .unknown:
            print("The state of the BLE Manager is unknown.")
        case .poweredOn:
            print("Bluetooth LE is turned on and ready for communication.")
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral")
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect")
    }
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("willRestoreState")
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("didDiscoverServices")
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("didDiscoverCharacteristicsFor")
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValueFor")
        if error != nil {
            print("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(String(describing: error?.localizedDescription))")
            return
        }
        
        let returnedBytes = [UInt8](characteristic.value!)
        obdResponse += returnedBytes
        
        // End of response
        if (Array(obdResponse.suffix(3)).map { String(UnicodeScalar($0)) }.joined()) == "\r\r>" {
            // Do something with response
            // Clear responses
        }
    }
    
    public func createCommand(name: String, command: String) {
        obdCommands[name] = command
    }
    
    public func clearConfigurationCommands() {
        configurationCommands = []
    }
    
    public func setConfigurationCommands(commands: [String]) {
        configurationCommands = commands
    }
    
    public func addConfigurationCommands(commands: [String]) {
        configurationCommands += commands
    }
    
    public func configureOBD() -> Bool {
        if obd2 == nil || dataCharacteristic == nil {
            print("Device is not connected to an OBD-II scanner.")
            setupComplete = false
        } else {
            for cmd in configurationCommands {
                obd2!.writeValue(Data(bytes: Array("\(cmd)\r".utf8)), for: dataCharacteristic!, type: .withResponse)
            }
        }
        
        return setupComplete
    }
    
    public func getVin() {
        if obd2 == nil || dataCharacteristic == nil {
            print("Device is not connected to an OBD-II scanner.")
        } else {
            obd2!.writeValue(Data(bytes: Array("\(obdCommands["vin"]!)\r".utf8)), for: dataCharacteristic!, type: .withResponse)
        }
    }
    
    public func getSpeed() {
        if obd2 == nil || dataCharacteristic == nil {
            print("Device is not connected to an OBD-II scanner.")
        } else {
            obd2!.writeValue(Data(bytes: Array("\(obdCommands["speed"]!)\r".utf8)), for: dataCharacteristic!, type: .withResponse)
        }
    }
    
    public func sendCommandNamed(name: String, receivedData: ([UInt8]) -> ()) {
        if obd2 == nil || dataCharacteristic == nil {
            print("Device is not connected to an OBD-II scanner.")
        } else {
            obd2!.writeValue(Data(bytes: Array("\(obdCommands[name]!)\r".utf8)), for: dataCharacteristic!, type: .withResponse)
        }
    }
    
    public func getVehicleInfo(vinNumber: String, completion: @escaping (_ vehicleInfo: [String: Any]) -> ()) {
        Alamofire.request(self.vinLookupUrl(vin: vinNumber), method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                let vinData = json["Results"].arrayValue.filter { [26, 28, 29].contains($0["VariableId"].intValue) }
                
                var vehicleResponse:[String: String] = [:]
                
                vehicleResponse["make"] = self.getVehicleAttrWithId(vinData: vinData, variableId: 26).capitalized
                vehicleResponse["model"] = self.getVehicleAttrWithId(vinData: vinData, variableId: 28)
                vehicleResponse["year"] = self.getVehicleAttrWithId(vinData: vinData, variableId: 29)
                
                print("\nMake: \(vehicleResponse["make"]!)")
                print("Model: \(vehicleResponse["model"]!)")
                print("Model Year: \(vehicleResponse["year"]!)")
                
                completion(vehicleResponse)
                
            case .failure(let error):
                print("VIN Lookup Failure:")
                print(error)
            }
        }
    }
    
    private func vinLookupUrl(vin: String) -> String {
        return "https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVin/\(vin)*BA?format=json"
    }
    
    private func getVehicleAttrWithId(vinData: [JSON], variableId: Int) -> String {
        return vinData.filter { $0["VariableId"].intValue == variableId }[0]["Value"].stringValue
    }
    
    private func parseVinResponse(data: [UInt8]) {
        var vinString = ""
        var resultStrings = data.map { String(UnicodeScalar($0)) }.joined().components(separatedBy: "\r")
        
        // Ref: Pg 42 - https://www.elmelectronics.com/wp-content/uploads/2016/07/ELM327DS.pdf
        let line1 = resultStrings[2]
        let index1 = line1.index(line1.startIndex, offsetBy: 8)
        vinString += line1.substring(from: index1)
        
        let line2 = resultStrings[3]
        let index2 = line2.index(line2.startIndex, offsetBy: 2)
        vinString += line2.substring(from: index2)
        
        let line3 = resultStrings[4]
        let index3 = line3.index(line3.startIndex, offsetBy: 2)
        vinString += line3.substring(from: index3)
        
        let vinHexArray = Array(vinString.characters).splitBy(subSize: 2).map { String($0) }
        let vinCharArray = vinHexArray.map { char -> Character in
            let code = Int(strtoul(char, nil, 16))
            return Character(UnicodeScalar(code)!)
        }
        
        vinNumber = String(vinCharArray)
        print("\nVIN Number: \(vinNumber!)")
    }
    
}

private class OBD2_BLESetup {
    var restoreId:String?
}

extension Array {
    func splitBy(subSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: subSize).map { startIndex in
            if let endIndex = self.index(startIndex, offsetBy: subSize, limitedBy: self.count) {
                return Array(self[startIndex ..< endIndex])
            }
            return Array()
        }
    }
}

