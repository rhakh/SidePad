//
//  Helpers.swift
//  SidePad Server
//
//  Created by Роман Гах on 24.09.2021.
//  Copyright © 2021 Роман Гах. All rights reserved.
//

import Foundation

func parseWith(for regex: String, in text: String) -> [String] {

    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}

func parseFloats(in text: String) -> [Float] {
    let regex = "[+-]?([0-9]*[.])?[0-9]+"

    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        return results.map {
            Float(text[Range($0.range, in: text)!])!
        }
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}
