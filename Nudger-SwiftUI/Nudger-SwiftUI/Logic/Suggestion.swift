//
//  Suggestion.swift
//  Assistant
//
//  Created by shekar ramaswamy on 10/31/21.
//

import Foundation

class Suggestion {
    
    func makeSuggestions(cmh: [ContactMessageHistory]) -> [ContactMessageHistory] {
        var suggestions: [ContactMessageHistory] = []
        for cm in cmh {
            if self.scoreContact(cm: cm) == 1 {
                print(cm.name)
                var i = 0
                while i < cm.messageData.count && cm.messageData[i].isFromMe == false {
                    print(cm.messageData[i].text)
                    i += 1
                }
                print("open sms:" + String(cm.phoneNum.filter { !$0.isWhitespace }))
                suggestions.append(cm)
            }
        }
        return suggestions
    }
    
    // Pretty jank scoring mechanism to determine if a contact should be suggested
    private func scoreContact(cm: ContactMessageHistory) -> Float {
        let rm = self.getRecentBurst(cm: cm)
        if rm.count == 0 {
            return 0
        }
        
        var allORC = true
        for m in rm {
            let scalars = m.text.unicodeScalars
            if scalars[scalars.startIndex].value != 65533 && scalars[scalars.startIndex].value != 65532 {
                allORC = false
                break
            }
        }
        if allORC {
            return 0
        }
        
        // Check if recent burst occurred over a day ago
        if rm[0].timeDelta < 86400 {
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
        } else if loweredText.contains("loved") || loweredText.contains("liked") || loweredText.contains("emphazied") {
            // Attempt to filter out reactions
            return 0
        } else if loweredText.count < 4 {
            return 0
        } else if loweredText.contains("thank") || loweredText.contains("sounds good") {
            return 0
        }
        
        return 1
    }
    
    private func getRecentBurst(cm: ContactMessageHistory) -> [MessageData] {
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
