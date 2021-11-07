//
//  AppDelegate.swift
//  Nudger-SwiftUI
//
//  Created by shekar ramaswamy on 11/1/21.
//

import Foundation
import Cocoa
import SwiftUI

let dataAPI = Data()
let suggestionAPI = Suggestion()
let apiManager = APIManager()

let popover = NSPopover()

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusBarItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view (i.e. the content).
        
        let contentView = PersonList()

        // Create the popover and sets ContentView as the rootView
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        // Create the status bar item
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        
        if let button = self.statusBarItem.button {
            button.image = NSImage(named: "home")
            button.action = #selector(togglePopover(_:))
        }
    }
    
    // Toggles popover
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = self.statusBarItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
}
