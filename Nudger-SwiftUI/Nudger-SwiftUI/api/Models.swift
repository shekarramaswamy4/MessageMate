//
//  Models.swift
//  Assistant
//
//  Created by shekar ramaswamy on 10/31/21.
//

import Foundation

struct MessageData: Identifiable {
    let id = UUID()
    
    let timestamp: Double
    let timeDelta: Double
    let text: String
    let isFromMe: Bool
}

struct ContactMessageHistory: Identifiable {
    let id = UUID()
    
    let phoneNum: String
    let name: String
    let messageData: [MessageData]
}

