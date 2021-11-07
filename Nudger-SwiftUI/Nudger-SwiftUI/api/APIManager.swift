//
//  APIManager.swift
//  Nudger-SwiftUI
//
//  Created by shekar ramaswamy on 11/7/21.
//

import Foundation

class APIManager: ObservableObject {
    @Published var suggestionList = ContactMessageHistoryList(data: [])
    
    init() {
        perform()
        // TODO: this can probably be optimized to time with popover open / closing
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            if !popover.isShown {
                self.perform()
            }
        }
    }
    
    private func perform() {
        print("doing")
        let data = dataAPI.getData()
        let suggestions = suggestionAPI.makeSuggestions(cmh: data)
        self.suggestionList = ContactMessageHistoryList(data: suggestions)
    }
}
