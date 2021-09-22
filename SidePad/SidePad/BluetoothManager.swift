//
//  BluetoothManager.swift
//  SidePad
//
//  Created by Роман Гах on 21.09.2021.
//  Copyright © 2021 Роман Гах. All rights reserved.
//

import Foundation
import CoreBluetooth
import os

class BluetoothManager: NSObject {
    
    // MARK: Fields
    var peripheralManager: CBPeripheralManager!
    var transferCharacteristic: CBMutableCharacteristic?
    var candidates: [ConnectCandidate] = []
    
    static var shared: BluetoothManager = {
        let instance = BluetoothManager()
        return instance
    }()
    
    private override init() {}
    
    // MARK: Functions
    func initPeripheral() -> Void {
        peripheralManager = CBPeripheralManager(
                    delegate: self,
                    queue: nil,
                    options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
    }

    func setupPeripheral() -> Void {
        // Build our service.
        // Start with the CBMutableCharacteristic.
        let transferCharacteristic = CBMutableCharacteristic(
                                    type: TransferService.characteristicUUID,
                                    properties: [.notify, .read, .write],
                                    value: nil,
                                    permissions: [.readable, .writeable])

        let rxCharacteristic = CBMutableCharacteristic(
                                    type: TransferService.centralTxUUID,
                                    properties: [.read],
                                    value: nil,
                                    permissions: [.readable])
        
        // Create a service from the characteristic.
        let transferService = CBMutableService(type: TransferService.serviceUUID, primary: true)
        
        // Add the characteristic to the service.
        transferService.characteristics = [transferCharacteristic, rxCharacteristic]
        
        // And add it to the peripheral manager.
        peripheralManager.add(transferService)
        
        // Save the characteristic for later.
        self.transferCharacteristic = transferCharacteristic
        
        // Start advertising
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUID]])

    }

    func stopAdvertising() -> Void {
        peripheralManager.stopAdvertising()
    }

    /*
     *  Sends the next amount of data to the connected central
     */
    func sendData(_ data: String) {

        guard let transferCharacteristic = transferCharacteristic else {
            return
        }
        
        // Work out how big it should be
        // var amountToSend = dataToSend.count - sendDataIndex
        // if let mtu = connectedCentral?.maximumUpdateValueLength {
        //     print("amountToSend = %d, mtu = %d", amountToSend, mtu)
        //     amountToSend = min(amountToSend, mtu)
        // }
        
        // TODO: Check if it fits into amountToSend
        // Send it
        print("Send '\(data)'")
        let didSend = peripheralManager.updateValue(
                    data.data(using: .utf8)!,
                    for: transferCharacteristic,
                    onSubscribedCentrals: nil)
        
        // If it didn't work, drop out and wait for the callback
        if !didSend {
            // TODO: do something
            print("Failed to send '\(data)'")
            return
        }
    }
    
    func getCandidatesCount() -> Int {
        // TODO
        return candidates.count
    }
    
    func getCandidateAt(_ index: Int) -> ConnectCandidate {
        return candidates[index]
    }
}

extension BluetoothManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            // ... so start working with the peripheral
            print("CBManager is powered on")
            setupPeripheral()
        case .poweredOff:
            print("CBManager is not powered on")
            // In a real app, you'd deal with all the states accordingly
            return
        case .resetting:
            print("CBManager is resetting")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unauthorized:
            // In a real app, you'd deal with all the states accordingly
            if #available(iOS 13.0, *) {
                switch peripheral.authorization {
                case .denied:
                    print("You are not authorized to use Bluetooth")
                case .restricted:
                    print("Bluetooth is restricted")
                default:
                    print("Unexpected authorization")
                }
            } else {
                // Fallback on earlier versions
            }
            return
        case .unknown:
            print("CBManager state is unknown")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unsupported:
            print("Bluetooth is not supported on this device")
            // In a real app, you'd deal with all the states accordingly
            return
        @unknown default:
            print("A previously unknown peripheral manager state occurred")
            // In a real app, you'd deal with yet unknown cases that might occur in the future
            return
        }
    }
    
    /*
     *  Catch when someone subscribes to our characteristic, then start sending them data
     */
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didSubscribeTo characteristic: CBCharacteristic) {
        print("Central subscribed to characteristic")

        // save central
        // candidates.append(central)

        // Start sending
        sendData("📱 iPhone")
    }
    
    /*
     *  Recognize when the central unsubscribes
     */
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("Central unsubscribed from characteristic")
        // connectedCentral = nil
        
        var index = 0
        for candidate in candidates {
            if candidate.central == central {
                candidates.remove(at: index)
                break
            }
            index += 1
        }
    }
    
    /*
     *  This callback comes in when the PeripheralManager is ready to send the next chunk of data.
     *  This is to ensure that packets will arrive in the order they are sent
     */
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // Start sending again
        // sendData()
    }
    
    /*
     * This callback comes in when the PeripheralManager received write to characteristics
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for aRequest in requests {
            guard let requestValue = aRequest.value,
                let stringFromData = String(data: requestValue, encoding: .utf8) else {
                    continue
            }
            
            print("Received write request of \(requestValue.count) bytes: \(stringFromData)")
            
            // Save name in list
            candidates.append(ConnectCandidate(name: stringFromData, central: aRequest.central))
            GConnectionController.addCandidate(IndexPath(row: candidates.count - 1, section: 0))
        }
    }
}

extension BluetoothManager: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}
