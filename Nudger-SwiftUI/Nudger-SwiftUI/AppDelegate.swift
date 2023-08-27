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
    var eventMonitor: EventMonitor?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view (i.e. the content).
        
       
        let contentView = PersonList()

        // Create the popover and sets ContentView as the rootView
        popover.contentSize = NSSize(width: 450, height: 550)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        if let button = statusBarItem.button {
            button.action = #selector(togglePopover(_:))
        }
        statusBarItem.setMenuText(title: "💬 (🔄)")
        
        hotKey.keyDownHandler = {
            
            DispatchQueue.main.async {
                apiManager.suggestionList = ContactMessageHistoryList(data: [])
                statusBarItem.setMenuText(title: "💬✅")
            }

            // self.togglePopover(nil)
        }
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if popover.isShown {
                if ((popover.contentViewController?.view.frame.contains(event!.locationInWindow)) != nil) {
                    self?.togglePopover(nil)
                }
            }
        }
        eventMonitor?.start()
    }
    
    // Toggles popover
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                // This is a hack to forcibly make the default text of the text view equal to what the apiManager's current remindWindow is
                // This ensures the user's previous value that they hadn't confirmed is wiped
                apiManager.forceUpdateRemindWindow()
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
}
