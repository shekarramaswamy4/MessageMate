//
//  AppDelegate.swift
//  Nudger-SwiftUI
//
//  Created by shekar ramaswamy on 11/1/21.
//

import Foundation
import Cocoa
import SwiftUI
import HotKey

let dataAPI = Data()
let suggestionAPI = Suggestion()
let apiManager = APIManager()
let defaults = UserDefaults.standard

let popover = NSPopover()
let statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))

let hotKey = HotKey(key: .m, modifiers: [.command, .shift])

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view (i.e. the content).
        
        let contentView = PersonList()

        // Create the popover and sets ContentView as the rootView
        popover.contentSize = NSSize(width: 400, height: 550)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        if let button = statusBarItem.button {
            button.action = #selector(togglePopover(_:))
        }
        statusBarItem.setMenuText(title: "💬")
        
        hotKey.keyDownHandler = {
            self.togglePopover(nil)
        }
    }
    
    // Toggles popover
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
}
