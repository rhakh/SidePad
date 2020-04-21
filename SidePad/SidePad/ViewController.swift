//
//  ViewController.swift
//  SidePad
//
//  Created by Роман Гах on 06.04.2020.
//  Copyright © 2020 Роман Гах. All rights reserved.
//

import UIKit
import CoreBluetooth

enum SwipeDirection: String {
    case None
    case Left
    case Up
    case Right
    case Down
}

class ViewController: UIViewController {
    
    @IBOutlet weak var swipeLabel: UILabel!
    @IBOutlet weak var advertisingSwitch: UISwitch!
    
    var peripheralManager: CBPeripheralManager!

    var transferCharacteristic: CBMutableCharacteristic?
    var connectedCentral: CBCentral?
    var dataToSend = Data()
    var sendDataIndex: Int = 0
    var swipeDirection = SwipeDirection.None

    override func viewDidLoad() {
        peripheralManager = CBPeripheralManager(
                    delegate: self,
                    queue: nil,
                    options: [CBPeripheralManagerOptionShowPowerAlertKey: true])

        super.viewDidLoad()
        
        swipeDirection = .None
        swipeObservers()
    }

    func swipeObservers() {
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(gestureHandler))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(gestureHandler))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(gestureHandler))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(gestureHandler))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
    }

    @objc func gestureHandler(gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .right:
            swipeLabel.text = "Right"
            swipeDirection = .Right
        case .left:
            swipeLabel.text = "Left"
            swipeDirection = .Left
        case .up:
            swipeLabel.text = "Up"
            swipeDirection = .Up
        case .down:
            swipeLabel.text = "Down"
            swipeDirection = .Down
        default:
            break
        }
        
        if connectedCentral != nil {
            print("Send swipe '\(swipeDirection.rawValue)'")
            
            peripheralManager.updateValue(
                swipeDirection.rawValue.data(using: .utf8)!,
                for: transferCharacteristic!,
                onSubscribedCentrals: [connectedCentral!])
        }
    }
    
    @IBAction func switchChanged(_ sender: Any) {
        // All we advertise is our service's UUID.
        if advertisingSwitch.isOn {
//            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUID]])
        } else {
            // Stop advertising service when cerntal was conncted
            peripheralManager.stopAdvertising()
        }
    }
    
    
    // MARK: Bluetooth
    
    private func setupPeripheral() {
        
        // Build our service.
        
        // Start with the CBMutableCharacteristic.
        let transferCharacteristic = CBMutableCharacteristic(
                                    type: TransferService.characteristicUUID,
                                    properties: [.notify, .writeWithoutResponse],
                                    value: nil,
                                    permissions: [.readable, .writeable])
        
        // Create a service from the characteristic.
        let transferService = CBMutableService(type: TransferService.serviceUUID, primary: true)
        
        // Add the characteristic to the service.
        transferService.characteristics = [transferCharacteristic]
        
        // And add it to the peripheral manager.
        peripheralManager.add(transferService)
        
        // Save the characteristic for later.
        self.transferCharacteristic = transferCharacteristic
        
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUID]])

    }
    
    /*
     *  Sends the next amount of data to the connected central
     */
    static var sendingEOM = false
    
    private func sendData() {
        
        guard let transferCharacteristic = transferCharacteristic else {
            return
        }
        
        // First up, check if we're meant to be sending an EOM
        if ViewController.sendingEOM {
            // send it
            let didSend = peripheralManager.updateValue(
                                                "EOM".data(using: .utf8)!,
                                                for: transferCharacteristic,
                                                onSubscribedCentrals: nil)
            // Did it send?
            if didSend {
                // It did, so mark it as sent
                ViewController.sendingEOM = false
                print("Sent: EOM")
            }
            // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
            return
        }
        
        // We're not sending an EOM, so we're sending data
        // Is there any left to send?
        if sendDataIndex >= dataToSend.count {
            // No data left.  Do nothing
            return
        }
        
        // There's data left, so send until the callback fails, or we're done.
        var didSend = true
        while didSend {
            
            // Work out how big it should be
            var amountToSend = dataToSend.count - sendDataIndex
            if let mtu = connectedCentral?.maximumUpdateValueLength {
                print("amountToSend = %d, mtu = %d", amountToSend, mtu)
                amountToSend = min(amountToSend, mtu)
            }
            
            // Copy out the data we want
            let chunk = dataToSend.subdata(in: sendDataIndex..<(sendDataIndex + amountToSend))
            
            // Send it
            didSend = peripheralManager.updateValue(chunk, for: transferCharacteristic, onSubscribedCentrals: nil)
            
            // If it didn't work, drop out and wait for the callback
            if !didSend {
                return
            }
            
            let stringFromData = String(data: chunk, encoding: .utf8)
            print("Sent %d bytes: %s", chunk.count, String(describing: stringFromData))
            
            // It did send, so update our index
            sendDataIndex += amountToSend
            // Was it the last one?
            if sendDataIndex >= dataToSend.count {
                // It was - send an EOM
                
                // Set this so if the send fails, we'll send it next time
                ViewController.sendingEOM = true
                
                //Send it
                let eomSent = peripheralManager.updateValue(
                                "EOM".data(using: .utf8)!,
                                for: transferCharacteristic,
                                onSubscribedCentrals: nil)
                
                if eomSent {
                    // It sent; we're all done
                    ViewController.sendingEOM = false
                    print("Sent: EOM")
                }
                return
            }
        }
    }
}

extension ViewController: CBPeripheralManagerDelegate {
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
                           didSubscribeTo characteristic: CBCharacteristic)
    {
        print("Central subscribed to characteristic")
        
        // Get the data
        dataToSend = swipeDirection.rawValue.data(using: .utf8)!
        
        // Reset the index
        sendDataIndex = 0
        
        // save central
        connectedCentral = central
        
        // Start sending
        sendData()
    }
    
    /*
     *  Recognize when the central unsubscribes
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic)
    {
        print("Central unsubscribed from characteristic")
        connectedCentral = nil
    }
    
    /*
     *  This callback comes in when the PeripheralManager is ready to send the next chunk of data.
     *  This is to ensure that packets will arrive in the order they are sent
     */
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // Start sending again
        sendData()
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
            
            print("Received write request of %d bytes: %s", requestValue.count, stringFromData)
        }
    }
}
