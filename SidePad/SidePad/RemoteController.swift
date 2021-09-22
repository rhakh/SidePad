//
//  RemoteController.swift
//  SidePad
//
//  Created by Роман Гах on 24.04.2020.
//  Copyright © 2020 Роман Гах. All rights reserved.
//

import UIKit
import CoreBluetooth
import os

class RemoteController: UIViewController {
    
//    var peripheral: CBPeripheralManager?
//    var manager: ConnectCandidate?
//    var service: CBMutableService?
//    var characteristic: CBMutableCharacteristic?

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        navigationItem.title = "Manage '\(manager!.name)'"
//
//        // TODO: Make peripheral, manager, service, characteristic
//        // shared for this application. For Server app too.
//        os_log("Try to send Hello")
//        let didSend = peripheral!.updateValue("Hello".data(using: .utf8)!,
//                               for: self.characteristic!,
//                               onSubscribedCentrals: [manager!.central])
//        
//        if !didSend {
//            // TODO: Do something with it
//            os_log("Failed to send Hello message")
//        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction func buttonPressed(_ sender: Any) {
        BluetoothManager.shared.sendData("Portion of letters...")
    }
    
}
