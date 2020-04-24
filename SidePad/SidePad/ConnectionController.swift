//
//  ConnectionController.swift
//  SidePad
//
//  Created by Роман Гах on 24.04.2020.
//  Copyright © 2020 Роман Гах. All rights reserved.
//

import UIKit
import CoreBluetooth
import os

class ConnectionController: UITableViewController {
    
    var peripheralManager: CBPeripheralManager!
    var connectCharacteristic: CBMutableCharacteristic?
    var connectService: CBMutableService?
    var connectCandidates: [ConnectCandidate] = [] // TODO: use list here

    override func viewDidLoad() {
        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [CBPeripheralManagerOptionShowPowerAlertKey: true])

        super.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Don't keep advertising going while we're not showing.
        peripheralManager.stopAdvertising()

        super.viewWillDisappear(animated)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return connectCandidates.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CandidateCell", for: indexPath)
                    as! ConnectionControllerCell

        cell.update(with: connectCandidates[indexPath.row])

        return cell
    }
    
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RemoteControllSegue" {
            let indexPath = tableView.indexPathForSelectedRow!
            let selectedCandidate = connectCandidates[indexPath.row]
            let navController = segue.destination as! UINavigationController
            let remoteController = navController.topViewController as! RemoteController

            // TODO: Delete connectCharacteristic.
            remoteController.central = selectedCandidate
            remoteController.service = connectService
        }
    }

    
    // MARK: - Bluetooth
    private func setupPeripheral() {
        // Build our service.
        
        // Start with the CBMutableCharacteristic.
        let connectCharacteristic = CBMutableCharacteristic(type: TransferService.characteristicUUID,
                                                         properties: [.notify, .writeWithoutResponse],
                                                         value: nil,
                                                         permissions: [.readable, .writeable])
        
        // Create a service from the characteristic.
        let connectService = CBMutableService(type: TransferService.serviceUUID, primary: true)
        
        // Add the characteristic to the service.
        connectService.characteristics = [connectCharacteristic]
        
        // And add it to the peripheral manager.
        peripheralManager.add(connectService)
        
        // Save the characteristic for later.
        self.connectCharacteristic = connectCharacteristic
        self.connectService = connectService
    }
}

extension ConnectionController: CBPeripheralManagerDelegate {
    // implementations of the CBPeripheralManagerDelegate methods

    /*
     *  Required protocol method.  A full app should take care of all the possible states,
     *  but we're just waiting for to know when the CBPeripheralManager is ready
     *
     *  Starting from iOS 13.0, if the state is CBManagerStateUnauthorized, you
     *  are also required to check for the authorization state of the peripheral to ensure that
     *  your app is allowed to use bluetooth
     */
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            // ... so start working with the peripheral
            os_log("CBManager is powered on")
            setupPeripheral()
        case .poweredOff:
            os_log("CBManager is not powered on")
            // In a real app, you'd deal with all the states accordingly
            return
        case .resetting:
            os_log("CBManager is resetting")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unauthorized:
            // In a real app, you'd deal with all the states accordingly
            if #available(iOS 13.0, *) {
                switch peripheral.authorization {
                case .denied:
                    os_log("You are not authorized to use Bluetooth")
                case .restricted:
                    os_log("Bluetooth is restricted")
                default:
                    os_log("Unexpected authorization")
                }
            } else {
                // Fallback on earlier versions
            }
            return
        case .unknown:
            os_log("CBManager state is unknown")
            // In a real app, you'd deal with all the states accordingly
            return
        case .unsupported:
            os_log("Bluetooth is not supported on this device")
            // In a real app, you'd deal with all the states accordingly
            return
        @unknown default:
            os_log("A previously unknown peripheral manager state occurred")
            // In a real app, you'd deal with yet unknown cases that might occur in the future
            return
        }
    }
    
    /*
     *  Catch when someone subscribes to our characteristic, then start sending them data
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {

        guard let connectCharacteristic = connectCharacteristic else {
            os_log("connectCharacteristic is nil")
            return
        }
        
        os_log("Central subscribed to connectCharacteristic")
        
        // Start sending
        let didSend = peripheralManager.updateValue(
                        "📱 iPhone".data(using: .utf8)!,
                        for: connectCharacteristic,
                        onSubscribedCentrals: nil)

        // Start advertising
        peripheralManager.startAdvertising(
            [CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUID]])
        
        if !didSend {
            // TODO: Asser, connection stoped here
            os_log("Failed to send connect message")
            return
        }
    }
    
    /*
     *  Recognize when the central unsubscribes
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        os_log("Central unsubscribed from characteristic")
        
        // TODO: Remove particular central, not first one
        connectCandidates.remove(at: 0)
    }
    
    /*
     * This callback comes in when the PeripheralManager received write to characteristics
     */
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           didReceiveWrite requests: [CBATTRequest])
    {
        for request in requests {
            guard let requestValue = request.value,
                let stringFromData = String(data: requestValue, encoding: .utf8) else {
                    continue
            }
            
            os_log("Received write request of %d bytes: %s", requestValue.count, stringFromData)
            
            // Add candidate to the table
            let newIndexPath = IndexPath(row: connectCandidates.count, section: 0)

            connectCandidates.append(ConnectCandidate(name: stringFromData,
                                                      central: request.central))
            // Update tableView
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        }
    }
}
