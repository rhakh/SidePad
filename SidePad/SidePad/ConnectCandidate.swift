//
//  File.swift
//  SidePad
//
//  Created by Роман Гах on 24.04.2020.
//  Copyright © 2020 Роман Гах. All rights reserved.
//

import Foundation
import CoreBluetooth

class ConnectCandidate {
    let name: String
    let central: CBCentral
    
    init(name: String, central: CBCentral) {
        self.name = name
        self.central = central
    }
}
