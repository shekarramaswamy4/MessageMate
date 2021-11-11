//
//  NSStatusItem+Extensions.swift
//  Nudger-SwiftUI
//
//  Created by shekar ramaswamy on 11/11/21.
//

import Foundation
import Cocoa

extension NSStatusItem {
    func setMenuText(title: String) {
        if let button = self.button {
            button.title = title
        }
    }
}
