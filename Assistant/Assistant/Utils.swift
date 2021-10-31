//
//  Utils.swift
//  Assistant
//
//  Created by shekar ramaswamy on 10/31/21.
//

import Foundation
import PhoneNumberKit

let phoneNumberKit = PhoneNumberKit()

class Utils {
    static func formatTelephoneNumber(num: String) -> String? {
        do {
            let pn = try phoneNumberKit.parse(num)
            return phoneNumberKit.format(pn, toType: .international)
        }
        catch {
            // TODO: log this
            return nil
        }
    }
    
    static func cleanName(name: String) -> String {
        return ""
    }
}
