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
    @Published var firstLoad = true
    @Published var remindWindow = Constants.defaultRemindWindow
    
    @Published var paymentStatus = "freeTrial"
    @Published var initializeUnixSecond = 0.0
    @Published var paymentURL = ""
    @Published var paymentError = false
    
    var fullDiskAccessURL: URL!
    
    var isProcessing = false
    
    init() {
        let urlStr = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        if let url = URL(string: urlStr) {
            fullDiskAccessURL = url
        } else {
            // Should use neeva.com, but not everybody has an account yet!
            fullDiskAccessURL = URL(string: "https://www.google.com/search?q=how%20to%20enable%20full%20disk%20access%20for%20mac%20app")
        }
        
        remindWindow = defaults.object(forKey: DefaultsConstants.remindWindow) as? Int ?? Constants.defaultRemindWindow
        
        // Initialize payment variables
        let deviceId = defaults.object(forKey: DefaultsConstants.deviceId) as? String
        if deviceId == nil {
            let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
            let randomString = (0..<10).map { _ in
                letters.randomElement()!
            }
            defaults.set(String(randomString), forKey: DefaultsConstants.deviceId)
            
            let currentDate = Date()
            let unixTimestamp = currentDate.timeIntervalSince1970
            defaults.set(unixTimestamp, forKey: DefaultsConstants.initializeUnixSecond)
            defaults.set(false, forKey: DefaultsConstants.hasPaid)
            
            defaults.synchronize()
        }
        let storedInitUnixSecond = defaults.object(forKey: DefaultsConstants.initializeUnixSecond) as! Double
        self.initializeUnixSecond = storedInitUnixSecond
        
        let realDeviceId = defaults.object(forKey: DefaultsConstants.deviceId) as! String
        PaymentAPI.getPaymentURL(deviceId: realDeviceId) { result in
            switch result {
            case .success(let res):
                self.paymentURL = res.url
            case .failure(let error):
                // Fallback case
                self.paymentURL = Constants.stripeProdPaymentLink + "?client_reference_id=" + realDeviceId
            }
        }
        
        startPerforming()
    }
    
    func validatePaymentCode(code: String) {
        if code.count != 7 {
            DispatchQueue.main.async {
                self.paymentError = true
            }
            return
        }
        let deviceId = defaults.object(forKey: DefaultsConstants.deviceId) as! String
        PaymentAPI.validatePaymentCode(deviceId: deviceId, paymentCode: code) { result in
            switch result {
            case .success(let res):
                DispatchQueue.main.async {
                    if res.validated {
                        self.paymentStatus = "paid"
                        defaults.set(true, forKey: DefaultsConstants.hasPaid)
                        defaults.synchronize()
                        // Forcing a refresh
                        self.setRemindWindow(window: self.remindWindow)
                    }
                    self.paymentError = true
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.paymentError = true
                }
                // TODO: how to handle error?
                print("Error: \(error)")
            }
        }
    }
    
    func setRemindWindow(window: Int) {
        remindWindow = window
        firstLoad = true
        defaults.set(window, forKey: DefaultsConstants.remindWindow)
        defaults.synchronize()
        
        popover.performClose(nil)
        DispatchQueue.main.async {
            statusBarItem.setMenuText(title: "💬 (🔄)")
        }
        
        // TODO: watch out for race condition
    }
    
    func forceUpdateRemindWindow() {
        let temp = remindWindow
        remindWindow = 0
        remindWindow = temp
    }
    
    private func startPerforming() {
        DispatchQueue.global().async {
            while true {
                // Check payments
                let initializeUnixSecond = defaults.object(forKey: DefaultsConstants.initializeUnixSecond) as? Double ?? 0.0
                let hasPaid = defaults.object(forKey: DefaultsConstants.hasPaid) as? Bool ?? false
                
                if hasPaid {
                    // If paid, perform
                    DispatchQueue.main.async {
                        self.paymentStatus = "paid"
                    }
                    self.perform()
                } else {
                    let diff = Date().timeIntervalSince1970 - initializeUnixSecond
                    if Int(diff) > Constants.freeTrialDuration * 60 * 60 {
                        DispatchQueue.main.async {
                            self.paymentStatus = "needsPayment"
                            statusBarItem.setMenuText(title: "💬⚠️")
                        }
                    } else {
                        // Still on free trial
                        self.perform()
                    }
                }
                
                Thread.sleep(forTimeInterval: 5)
            }
        }
    }
    
    // dismissSuggestion adds a person to the blocklist in localstorage and
    // removes the element at the matching index.
    func dismissSuggestion(cmh: ContactMessageHistory) {
        var dismissed = defaults.object(forKey: DefaultsConstants.dismissedDict) as? [String:Double]
        if dismissed == nil {
            dismissed = [:]
        }
        
        dismissed![cmh.phoneNum] = cmh.messageData[0].timestamp
        defaults.set(dismissed, forKey: DefaultsConstants.dismissedDict)
        defaults.synchronize()
        
        for i in 0...self.suggestionList.data.count - 1 {
            if self.suggestionList.data[i].phoneNum == cmh.phoneNum {
                self.suggestionList.data.remove(at: i)
                break
            }
        }
        
        setMenuText()
    }
    
    private func setMenuText() {
        DispatchQueue.main.async {
            if self.suggestionList.data.count == 0 {
                statusBarItem.setMenuText(title: "💬✅")
            } else {
                statusBarItem.setMenuText(title: "💬 (\(self.suggestionList.data.count))")
            }
        }
    }
    
    private func perform() {
        if isProcessing {
            return
        }
        
        isProcessing = true
        
        DispatchQueue.global().async {
            let data = dataAPI.getData()
            
            DispatchQueue.main.async {
                self.firstLoad = false
                
                if data == nil {
                    self.hasFullDiskAccess = false
                    
                    DispatchQueue.main.async {
                        statusBarItem.setMenuText(title: "⚠️")
                    }
                    
                    // Purposefully mark processing as not finished because we don't have disk access
                    return
                } else if self.hasFullDiskAccess == false {
                    // To prevent unecessary re-renders
                    self.hasFullDiskAccess = true
                }
                
                
                let suggestions = suggestionAPI.makeSuggestions(cmh: data!, remindWindow: self.remindWindow)
                self.suggestionList = ContactMessageHistoryList(data: suggestions)
                
                self.setMenuText()
                
                self.isProcessing = false
            }
        }
    }
}
