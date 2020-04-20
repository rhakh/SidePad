//
//  File.swift
//  SidePad Server
//
//  Created by Роман Гах on 19.04.2020.
//  Copyright © 2020 Роман Гах. All rights reserved.
//

import Foundation
import CoreBluetooth

let PERIPHERAL_NAME = "SPPeriferal"

struct TransferService {
    static let serviceUUID = CBUUID(string: "C43F7DE2-644D-46C5-B0CF-2DBCA3E6390E")
    static let characteristicUUID = CBUUID(string: "096839B6-2D43-403E-8CF2-4ADA498EB4D2")
}
