//
//  APIManager.swift
//  Nudger-SwiftUI
//
//  Created by shekar ramaswamy on 11/7/21.
//

import Foundation

class APIManager: ObservableObject {
    @Published var suggestionList = ContactMessageHistoryList(data: [])
    @Published var hasFullDiskAccess = true
    
    var fullDiskAccessURL: URL!
    
    init() {
        let urlStr = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        if let url = URL(string: urlStr) {
            fullDiskAccessURL = url
        } else {
            // Should use neeva.com, but not everybody has an account yet!
            fullDiskAccessURL = URL(string: "https://www.google.com/search?q=how%20to%20enable%20full%20disk%20access%20for%20mac%20app")
        }
        
        perform()
        // TODO: this can probably be optimized to time with popover open / closing
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            if !popover.isShown {
                self.perform()
            }
        }
    }
    
    // dismissSuggestion adds a person to the blocklist in localstorage and
    // removes the element at the matching index.
    func dismissSuggestion(cmh: ContactMessageHistory) {
        var dismissed = defaults.object(forKey: "dismissedDict") as? [String:Double]
        if dismissed == nil {
            dismissed = [:]
        }
        
        dismissed![cmh.phoneNum] = cmh.messageData[0].timestamp
        defaults.set(dismissed, forKey: "dismissedDict")
        
        for i in 0...self.suggestionList.data.count - 1 {
            if self.suggestionList.data[i].phoneNum == cmh.phoneNum {
                self.suggestionList.data.remove(at: i)
                break
            }
        }
    }
    
    private func perform() {
        let data = dataAPI.getData()
        let suggestions = suggestionAPI.makeSuggestions(cmh: data)
        self.suggestionList = ContactMessageHistoryList(data: suggestions)
        
        // TODO: show better message if no data found
        if data.count == 0 && suggestions.count == 0 {
            self.hasFullDiskAccess = false
        } else if self.hasFullDiskAccess == false {
            // To prevent unecessary re-renders
            self.hasFullDiskAccess = true
        }
    }
}