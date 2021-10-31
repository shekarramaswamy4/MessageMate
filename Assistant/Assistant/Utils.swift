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
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        for i in 0...n.count - 1 {
            let prefix = String(n.lowercased().prefix(i))
            let suffix = String(n.lowercased().suffix(n.count - i))
            let shouldContinue = suffix.pyContains(prefix)
            if shouldContinue {
                continue
            }
            
            let out = n.suffix(n.count - i)
            return out.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // TODO: log this
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension String {
    // Same as Swift contains, but returns true if comparison string is empty
    // (like python)
    func pyContains(_ other: String) -> Bool {
        if other == "" {
            return true
        }
        return self.contains(other)
    }
}
