//
//  ViewController.swift
//  SidePad Server
//
//  Created by Роман Гах on 14.04.2020.
//  Copyright © 2020 Роман Гах. All rights reserved.
//

import Cocoa
import CoreBluetooth

enum SwipeDirection: String {
    case None
    case Left
    case Up
    case Right
    case Down
}

class ViewController: NSViewController
{
    var centralManager: CBCentralManager!

    var discoveredPeripheral: CBPeripheral?
    var transferCharacteristic: CBCharacteristic?
    
    lazy var window: NSWindow = self.view.window!
    var mouseLocation: NSPoint { NSEvent.mouseLocation }

    @IBOutlet weak var countLabel: NSTextField!
    @IBOutlet var logText: NSTextView!
    let queue = DispatchQueue.main
    

    override func viewDidLoad() {
        super.viewDidLoad()

        centralManager = CBCentralManager(
                    delegate: self,
                    queue: nil,
                    options: [CBCentralManagerOptionShowPowerAlertKey: true])
        
//        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { _ in
////            print(String(format: "%.0f, %.0f", self.mouseLocation.x, self.mouseLocation.y))
//        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()

        window.acceptsMouseMovedEvents = true
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    // MARK: Bluetooth

    /*
     * We will first check if we are already connected to our counterpart
     * Otherwise, scan for peripherals - specifically for our service's 128bit CBUUID
     */
    private func retrievePeripheral() {
        
        let connectedPeripherals: [CBPeripheral] =
            (centralManager.retrieveConnectedPeripherals(
                    withServices: [TransferService.serviceUUID]))
        
        print("Found connected Peripherals with transfer service: %@", connectedPeripherals)
        
        if let connectedPeripheral = connectedPeripherals.last {
            print("Connecting to peripheral 1", connectedPeripheral)
            self.discoveredPeripheral = connectedPeripheral
            centralManager.connect(connectedPeripheral, options: nil)
        } else {
            // We were not connected to our counterpart, so start scanning
            centralManager.scanForPeripherals(
                withServices: [TransferService.serviceUUID],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    /*
     *  Call this when things either go wrong, or you're done with the connection.
     *  This cancels any subscriptions if there are any, or straight disconnects if not.
     *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
     */
    private func cleanup() {
        // Don't do anything if we're not connected
        guard let discoveredPeripheral = discoveredPeripheral,
            case .connected = discoveredPeripheral.state else { return }
        
        for service in (discoveredPeripheral.services ?? [] as [CBService]) {
            for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                if characteristic.uuid == TransferService.characteristicUUID && characteristic.isNotifying {
                    // It is notifying, so unsubscribe
                    self.discoveredPeripheral?.setNotifyValue(false, for: characteristic)
                }
            }
        }
    }
}

extension ViewController: CBCentralManagerDelegate {

    /*
     *  centralManagerDidUpdateState is a required protocol method.
     *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
     *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
     *  the Central is ready to be used.
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // ... so start working with the peripheral
            print("CBManager is powered on")
            retrievePeripheral()
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
                switch central.authorization {
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
            print("A previously unknown central manager state occurred")
            // In a real app, you'd deal with yet unknown cases that might occur in the future
            return
        }
    }
    
    /*
     *  This callback comes whenever a peripheral that is advertising the transfer serviceUUID is discovered.
     *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
     *  we start the connection process
     */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        // Reject if the signal strength is too low to attempt data transfer.
        // Change the minimum RSSI value depending on your app’s use case.
        guard RSSI.intValue >= -50
            else {
                print("Discovered perhiperal not in expected range, at %d", RSSI.intValue)
                return
        }
        
        print("Discovered %s at %d", peripheral.name, RSSI.intValue)
        
        // Device is in range - have we already seen it?
        if discoveredPeripheral != peripheral {
            
            // Save a local copy of the peripheral, so CoreBluetooth doesn't get rid of it.
            discoveredPeripheral = peripheral
            
            // And finally, connect to the peripheral.
            print("Connecting to perhiperal 2", peripheral)
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    /*
     *  If the connection fails for whatever reason, we need to deal with it.
     */
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to %@. %s", peripheral, String(describing: error))
        cleanup()
    }
    
    /*
     *  We've connected to the peripheral, now we need to discover the services
     *  and characteristics to find the 'transfer' characteristic.
     */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral Connected")
        
        // Stop scanning
        centralManager.stopScan()
        print("Scanning stopped")
        
        // Make sure we get the discovery callbacks
        peripheral.delegate = self
        
        // Search only for services that match our UUID
        peripheral.discoverServices([TransferService.serviceUUID])
    }
    
    /*
     *  Once the disconnection happens, we need to clean up our local copy of the peripheral
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Perhiperal Disconnected")
        discoveredPeripheral = nil
        
        retrievePeripheral()

        // We're disconnected, so start scanning again
//        if connectionIterationsComplete < defaultIterations {
//            retrievePeripheral()
//        } else {
//            print("Connection iterations completed")
//        }
    }
}

extension ViewController: CBPeripheralDelegate {
    /*
     *  The peripheral letting us know when services have been invalidated.
     */
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        
        for service in invalidatedServices where service.uuid == TransferService.serviceUUID {
            print("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices([TransferService.serviceUUID])
        }
    }
    
    /*
     *  The Transfer Service was discovered
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: %s", error.localizedDescription)
            cleanup()
            return
        }
        
        // Discover the characteristic we want...
        
        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        guard let peripheralServices = peripheral.services else { return }
        for service in peripheralServices {
            peripheral.discoverCharacteristics([TransferService.characteristicUUID], for: service)
        }
    }
    
    /*
     *  The Transfer characteristic was discovered.
     *  Once this has been found, we want to subscribe to it,
     *  which lets the peripheral know we want the data it contains
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Deal with errors (if any).
        if let error = error {
            print("Error discovering characteristics: %s", error.localizedDescription)
            cleanup()
            return
        }
        
        // Again, we loop through the array, just in case and check if it's the right one
        guard let serviceCharacteristics = service.characteristics else { return }
        for characteristic in serviceCharacteristics where characteristic.uuid == TransferService.characteristicUUID {
            // If it is, subscribe to it
            transferCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        }
        
        // Once this is complete, we just need to wait for the data to come in.
    }
    
    /*
     *   This callback lets us know more data has arrived via notification on the characteristic
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            print("Error discovering characteristics: %s", error.localizedDescription)
            cleanup()
            return
        }
        
        guard let characteristicData = characteristic.value,
            let stringFromData = String(data: characteristicData, encoding: .utf8) else { return }
        
        print("Received \(characteristicData.count) bytes: '\(stringFromData)'")
        
        DispatchQueue.main.async() {
            print("Received data: ", stringFromData)
            self.moveCursor(stringFromData)
        }
    }
    
    /*
     *  The peripheral letting us know whether our subscribe/unsubscribe happened or not
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        // Deal with errors (if any)
        if let error = error {
            print("Error changing notification state: %s", error.localizedDescription)
            return
        }
        
        // Exit if it's not the transfer characteristic
        guard characteristic.uuid == TransferService.characteristicUUID else { return }
        
        if characteristic.isNotifying {
            // Notification has started
            print("Notification began on %@", characteristic)
        } else {
            // Notification has stopped, so disconnect from the peripheral
            print("Notification stopped on %@. Disconnecting", characteristic)
            cleanup()
        }
        
    }
    
    /*
     *  This is called when peripheral is ready to accept more data when using write without response
     */
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        print("Peripheral is ready, send data")
//        writeData()
    }
    
    // MARK: Move cursor
    
    func moveCursor(_ direction: String) {
        var xDelta = CGFloat(0)
        var yDelta = CGFloat(0)
        var mouseLocation = self.mouseLocation

        switch direction {
        case SwipeDirection.Left.rawValue:
            xDelta = -10;
        case SwipeDirection.Up.rawValue:
            yDelta = -10;
        case SwipeDirection.Right.rawValue:
            xDelta = +10;
        case SwipeDirection.Down.rawValue:
            yDelta = +10;
        default:
            // TODO: do something
            print("Assert here")
        }
        
        print("x = \(xDelta), y = \(yDelta)")
        
        mouseLocation.y = NSHeight(NSScreen.screens[0].frame) - mouseLocation.y
//        mouseLocation.x = NSHeight(NSScreen.screens[0].frame) - mouseLocation.x
        mouseLocation.x += xDelta
        mouseLocation.y += yDelta
        CGDisplayMoveCursorToPoint(CGMainDisplayID(), mouseLocation)

        print(String(format: "%.0f, %.0f", self.mouseLocation.x, self.mouseLocation.y))
    }

}

