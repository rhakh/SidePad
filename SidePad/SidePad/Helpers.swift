//
//  Helpers.swift
//  SidePad
//
//  Created by Роман Гах on 24.09.2021.
//  Copyright © 2021 Роман Гах. All rights reserved.
//

import Foundation

// Specify the decimal place to round to using an enum
public enum RoundingPrecision {
    case ones
    case tenths
    case hundredths
}

// Round to the specific decimal place
public func preciseRound(
    _ value: Float,
    precision: RoundingPrecision = .ones) -> Float
{
    switch precision {
    case .ones:
        return round(value)
    case .tenths:
        return round(value * 10) / 10.0
    case .hundredths:
        return round(value * 100) / 100.0
    }
}
