//
//  Constants.swift
//  Nudger-SwiftUI
//
//  Created by shekar ramaswamy on 11/11/21.
//

import Foundation

// For user defaults
struct DefaultsConstants {
    static let dismissedDict = "dismissedDict"
    static let remindWindow = "remindWindow"
    static let deviceId = "deviceId"
    static let paymentStatus = "paymentStatus"
    static let initializeUnixSecond = "initializeUnixSecond"
    static let hasPaid = "hasPaid"
    static let manuallyTriggeredRestart = "manuallyTriggeredRestart"
}

struct Constants {
    // Hours
    static let defaultRemindWindow = 12
    // Hours
    static let freeTrialDuration = 24 * 6
    
    static let apiUrl = "https://api.messagemate.io"
    
    static let stripeProdPaymentLink = "https://buy.stripe.com/dR6bMec4f8vvbU4cMM"
}
