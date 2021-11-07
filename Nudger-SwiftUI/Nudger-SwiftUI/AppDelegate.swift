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

class AppDelegate: NSObject, NSApplicationDelegate {

    // popover
    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view (i.e. the content).
        
        let contentView = PersonList()

        // Create the popover and sets ContentView as the rootView
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        
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
            if self.popover.isShown {
                self.popover.performClose(sender)
            } else {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
}
