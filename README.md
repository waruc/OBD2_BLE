# OBD2_BLE

[![CI Status](http://img.shields.io/travis/nordale1-1541045/OBD2_BLE.svg?style=flat)](https://travis-ci.org/nordale1-1541045/OBD2_BLE)
[![Version](https://img.shields.io/cocoapods/v/OBD2_BLE.svg?style=flat)](http://cocoapods.org/pods/OBD2_BLE)
[![License](https://img.shields.io/cocoapods/l/OBD2_BLE.svg?style=flat)](http://cocoapods.org/pods/OBD2_BLE)
[![Platform](https://img.shields.io/cocoapods/p/OBD2_BLE.svg?style=flat)](http://cocoapods.org/pods/OBD2_BLE)

#### OBD2_BLE is a Swift framework for interfacing with OBD-II devices using iOS Bluetooth Low Energy capabilities.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

OBD2_BLE is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "OBD2_BLE"
```

## Usage

### Initialization
```
import OBD2_BLE

...

let obd2 = OBD2_BLE.sharedInstance
```
OBD2_BLE is implemented as a Singleton class.

### iOS BLE Background Processing
```
override func viewDidLoad() {
    super.viewDidLoad()
	
    OBD2_BLE.setup(restoreId: "myAppID.Bluetooth.RestoreID")
    let obd2 = OBD2_BLE.sharedInstance
}
```

### Properties
##### iOS CoreBluetooth Objects

```
var centralManager: CBCentralManager!
var obd2: CBPeripheral?
var dataCharacteristic:CBCharacteristic?
```

##### `obdCommands` Dictionary

```
var obdCommands:[String: String]! = [
    "speed": "010D",
    "rpm": "010C",
    "engineLoad": "0104",
    "coolantTemp": "0105",
    "vin": "0902"
]
```
[OBD-II PIDs](https://en.wikipedia.org/wiki/OBD-II_PIDs)


##### `configurationCommands` Dictionary

```
var configurationCommands = [
    "ATE0", // Echo Off
    "ATH0", // Headers Off
    "ATS0", // printing of Spaces Off
    "ATL0", // Linefeeds Off
    "ATSP0" // Set Protocol to 0 (Auto)
]
```
[ELM327 AT Commands](https://www.sparkfun.com/datasheets/Widgets/ELM327_AT_Commands.pdf)

### Configuration

* `createCommand(name: String, command: String)`<br><br>

* `clearConfigurationCommands()`

* `setConfigurationCommands(commands: [String])`

* `addConfigurationCommands(commands: [String])`<br><br>

* `configureOBD()`


### Requesting Data

* `getVin()`

* `getSpeed()`

* `sendCommandNamed(name: String)`<br><br>

* `getVehicleInfo(vinNumber: String, completion: @escaping (_ vehicleInfo: [String: Any]) -> ())`


## Author

Nick Nordale, nicknordale@gmail.com

## License

OBD2_BLE is available under the MIT license. See the LICENSE file for more info.
