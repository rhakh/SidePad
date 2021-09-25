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
    // MARK: Properties
    var touchStart: CGPoint?
    var touchEnd: CGPoint?
    var lastTouch: CGPoint?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // navigationItem.title = "Manage '\(manager!.name)'"
        
        // disable swipe back gesture
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // reenable swipe back gesture
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        // TODO: send disconnect message
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: view)
            print("B Position: ", position)
            
            touchStart = position
            lastTouch = position
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: view)
            
            guard let lastTouch = lastTouch else {
                return
            }
            var x = Float(position.x - lastTouch.x)
            var y = Float(position.y - lastTouch.y)
            x = preciseRound(x, precision: .hundredths)
            y = preciseRound(y, precision: .hundredths)

            print("M Diff: x=\(x) y=\(y)")
            
            // Don't send very small diff
            if (abs(x) < 1.0 && abs(y) < 1.0) {
                self.lastTouch = position
                return
            }

            // send connected to device
            BluetoothManager.shared.sendData("x:\(x) y:\(y)")
            
            // save this touch
            self.lastTouch = position
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: view)
            
            touchEnd = position
            if (touchEnd == touchStart) {
                BluetoothManager.shared.sendData("Click")
            } else {
                guard let lastTouch = lastTouch else {
                    return
                }
                var x = Float(position.x - lastTouch.x)
                var y = Float(position.y - lastTouch.y)
                x = preciseRound(x, precision: .hundredths)
                y = preciseRound(y, precision: .hundredths)
                
                print("E Diff: x=\(x) y=\(y)")
                BluetoothManager.shared.sendData("x:\(x) y:\(y)")
            }
        }
    }

    @IBAction func buttonPressed(_ sender: Any) {
        BluetoothManager.shared.sendData("Portion of letters...")
    }
    
    
    @IBAction func moveButtonPressed(_ sender: Any) {
        var x = 0, y = 0
        let button = sender as! UIButton
        let text = button.currentTitle!
        
        if (text == "⬆️" || text == "↗️" || text == "↖️") { y -= 10 }
        if (text == "⬇️" || text == "↙️" || text == "↘️") { y += 10 }
        if (text == "⬅️" || text == "↙️" || text == "↖️") { x -= 10 }
        if (text == "➡️" || text == "↗️" || text == "↘️") { x += 10 }
        
        BluetoothManager.shared.sendData("x:\(x) y:\(y)")
    }
    
}
