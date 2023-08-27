//
//  Suggestion.swift
//  Nudger-SwiftUI
//
//  Created by shekar ramaswamy on 11/2/21.
//

import Foundation

class Suggestion {
    
    func makeSuggestions(cmh: [ContactMessageHistory], remindWindow: Int) -> [ContactMessageHistory] {
        var dismissed = defaults.object(forKey: DefaultsConstants.dismissedDict) as? [String:Double] ?? [:]
        
        var suggestions: [ContactMessageHistory] = []
        for cm in cmh {
            if cm.messageData.count == 0 {
                continue
            } else if dismissed.index(forKey: cm.phoneNum) != nil {
                let val = dismissed[cm.phoneNum]!
                // Been dismissed
                if val == cm.messageData[0].timestamp {
                    continue
                } else { // New messages have come in, so delete entry
                    dismissed.removeValue(forKey: cm.phoneNum)
                }
            }
            
            if self.scoreContact(cm: cm, remindWindow: remindWindow) == 1 {
                var i = 0
                while i < cm.messageData.count && cm.messageData[i].isFromMe == false {
                    i += 1
                }
                suggestions.append(cm)
            }
        }
        suggestions.sort(by: sortSuggestions)
        
        defaults.set(dismissed, forKey: DefaultsConstants.dismissedDict)
        defaults.synchronize()
        
        let c1 = ContactMessageHistory(phoneNum: "+14088585444", name: "Shekar Ramaswamy", messageData: [
            MessageData(timestamp: 0, timeDelta: 60 * 60 * 26, text: "Hey! Want to get brunch this weekend? im staying in soho with my buddy john from high school", isFromMe: false)])
        let c2 = ContactMessageHistory(phoneNum: "+16462705561", name: "Cece Vogler", messageData: [
            MessageData(timestamp: 0, timeDelta: 60 * 60 * 14, text: "okk text me when you arrive 🛩", isFromMe: false)])
        let c3 = ContactMessageHistory(phoneNum: "+14089929103", name: "James Rogers", messageData: [
            MessageData(timestamp: 0, timeDelta: 60 * 60 * 22, text: "it was great to chat! thanks for your time, talk soon", isFromMe: false)])

        return [c2, c3, c1]
    }
    
    // Both this and that are required to have at least one message in MessageData
    private func sortSuggestions(this: ContactMessageHistory, that: ContactMessageHistory) -> Bool {
        return this.messageData[0].timeDelta < that.messageData[0].timeDelta
    }
    
    // Pretty jank scoring mechanism to determine if a contact should be suggested
    private func scoreContact(cm: ContactMessageHistory, remindWindow: Int) -> Float {
        let rm = self.getRecentBurst(cm: cm)
        if rm.count == 0 {
            return 0
        }
        
        var allORC = true
        for m in rm {
            let scalars = m.text.unicodeScalars
            
            // idk what this case really means in practice but it's a quick fix
            if scalars.count == 0 {
                allORC = false
                break
            }
            if scalars[scalars.startIndex].value != 65533 && scalars[scalars.startIndex].value != 65532 {
                allORC = false
                break
            }
        }
        if allORC {
            return 0
        }
        
        // Check if recent burst occurred over remindWindow hours ago
        // Computed in seconds
        if rm[0].timeDelta < Double(remindWindow) * 60 * 60 {
            return 0
        }
        
        if rm.count > 1 {
            return 1
        }
        
        let latest = rm[0]
        if latest.text == "" {
            return 0
        }
        
        let loweredText = latest.text.lowercased()
        if loweredText.contains("?") {
            return 1
        } else if loweredText.contains("loved") || loweredText.contains("liked") || loweredText.contains("emphasized") {
            // Attempt to filter out reactions
            return 0
        } else if loweredText.count < 4 {
            return 0
        } else if loweredText.contains("thank") || loweredText.contains("sounds good") {
            return 0
        }
        
        return 1
    }
    
    func getRecentBurst(cm: ContactMessageHistory) -> [MessageData] {
        if cm.messageData.count == 0 {
            return []
        } else if cm.messageData[0].isFromMe {
            return []
        }
        
        var recentBurst: [MessageData] = []
        for c in cm.messageData {
            if c.isFromMe {
                break
            }
            recentBurst.append(c)
        }
        return recentBurst
    }
}

