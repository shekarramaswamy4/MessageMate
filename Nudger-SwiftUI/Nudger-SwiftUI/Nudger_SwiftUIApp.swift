//
//  Nudger_SwiftUIApp.swift
//  Nudger-SwiftUI
//
//  Created by shekar ramaswamy on 11/1/21.
//

import SwiftUI
import Cocoa

@main
struct Nudger_SwiftUIApp: App {
    let persistenceController = PersistenceController.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
        }
    }
}
