//
//  Data.swift
//  Nudger-SwiftUI
//
//  Created by shekar ramaswamy on 11/2/21.
//

import Foundation
import GRDB

class Data {
    
    func getData() -> [ContactMessageHistory]? {
        let numToName = self.readAndFormatContacts()
        let data = self.readAndFormatChats(numToName: numToName)
        return data
    }
    
    private func readAndFormatChats(numToName: [String:String]) -> [ContactMessageHistory]? {
        var url = try? FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        url = url!.appendingPathComponent("Messages", isDirectory: true).appendingPathComponent("chat.db", isDirectory: false)
                
        var numToMessages: [String: [MessageData]] = [:]
        do {
            let dbQueue = try DatabaseQueue(path: url!.absoluteString)
            
            let currentDate = Date()
            let referenceDate = Calendar.current.date(from: DateComponents(year: 2001, month: 1, day: 1))!
            let nanosecondsSince2001 = Int(currentDate.timeIntervalSince(referenceDate) * 1_000_000_000)
            // Defaults to three months ago to look at messages
            let past = nanosecondsSince2001 - (60 * 60 * 24 * 90 * 1000000000)
            
            let query = """
SELECT
    message.date as messageDate,
    message.text as text,
    chat.chat_identifier as chatId,
    message.is_from_me as isFromMe
FROM
    chat
    JOIN chat_message_join ON chat. "ROWID" = chat_message_join.chat_id
    JOIN message ON chat_message_join.message_id = message. "ROWID"
WHERE
    service = 'iMessage' and message.date > \(past)
ORDER BY
    messageDate DESC
"""
            try dbQueue.read { db in
                let rows = try Row.fetchCursor(db, sql: query)
                while let row = try rows.next() {
                    let chatId: String? = row["chatId"]
                    if chatId == nil || chatId!.starts(with: "chat") || chatId!.contains("icloud") {
                        continue
                    }
                    
                    let cleaned = Utils.formatTelephoneNumber(num: chatId!)
                    if cleaned == nil {
                        continue
                    } else if numToName.index(forKey: cleaned!) == nil { // If number wasn't in contacts, skip
                        continue
                    }
                    
                    let timestamp: Double = row["messageDate"]
                    let text: String? = row["text"]
                    let isFromMe: Bool = row["isFromMe"]
                    
                    // 2001-01-01 00:00:00 UTC
                    // https://towardsdatascience.com/heres-how-you-can-access-your-entire-imessage-history-on-your-mac-f8878276c6e9
                    let baseDate = Date(timeIntervalSince1970: 978307200)
                    let date = Date(timeInterval: timestamp / 1000000000, since: baseDate)
                                                                                                    
                    let now = Date(timeIntervalSinceNow: 0)
                    let md = MessageData(timestamp: date.timeIntervalSince1970,
                                         timeDelta: now.timeIntervalSince1970 - date.timeIntervalSince1970, text: text ?? "",
                                         isFromMe: isFromMe)
                    
                    if numToMessages.index(forKey: cleaned!) == nil {
                        numToMessages[cleaned!] = [md]
                    } else {
                        var c = numToMessages[cleaned!]!
                        c.append(md)
                        numToMessages[cleaned!] = c
                    }
                }
            }
        } catch {
            if error.localizedDescription.contains("authorization denied") {
                return nil
            }
            print("read and format chats error")
            print(error)
        }
        
        var cmh: [ContactMessageHistory] = []
        for (key, val) in numToMessages {
            let c = ContactMessageHistory(phoneNum: key, name: numToName[key]!, messageData: val)
            cmh.append(c)
        }
        
        return cmh
    }
    
    private func readAndFormatContacts() -> [String:String] {
        var url = try? FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        url = url!.appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("AddressBook", isDirectory: true)
            .appendingPathComponent("Sources", isDirectory: true)
        
        // Remove file:// from beginning of string
        var cleaned = String(url!.absoluteString.dropFirst(7))
        // Clean URL string encoding
        cleaned = cleaned.replacingOccurrences(of: "%20", with: " ")

        let fileList = try? FileManager.default.contentsOfDirectory(atPath: cleaned)
        
        var idToName: [String:String] = [:]
        var numToName: [String:String] = [:]
        for f in fileList ?? [] {
            if f == ".DS_Store" { continue }
            var dbUrl = url
            dbUrl = dbUrl!.appendingPathComponent(f, isDirectory: true)
                .appendingPathComponent("AddressBook-v22.abcddb", isDirectory: false)
            
            do {
                let dbQueue = try DatabaseQueue(path: dbUrl!.absoluteString)
                
                let query = "select Z_PK as id, ZSORTINGFIRSTNAME as name from ZABCDRECORD order by Z_PK asc"
                try dbQueue.read { db in
                    let rows = try Row.fetchCursor(db, sql: query)
                    while let row = try rows.next() {
                        let id: String? = row["id"]
                        let name: String? = row["name"]
                        if id == nil || name == nil {
                            continue
                        }
                        
                        if name!.count == 0 {
                            continue
                        }
                        
                        idToName[id!] = Utils.cleanName(name: name!)
                    }
                }
            } catch {
                print("read and format contacts, name")
                print(error)
            }
            
            do {
                let dbQueue = try DatabaseQueue(path: dbUrl!.absoluteString)
                
                let query = "select ZOWNER as id, ZFULLNUMBER as number from ZABCDPHONENUMBER order by ZOWNER asc"
                try dbQueue.read { db in
                    let rows = try Row.fetchCursor(db, sql: query)
                    while let row = try rows.next() {
                        let id: String? = row["id"]
                        let number: String? = row["number"]
                        if id == nil || number == nil {
                            continue
                        }
                        
                        if idToName.index(forKey: id!) != nil {
                            let cleaned = Utils.formatTelephoneNumber(num: number!)
                            if cleaned == nil {
                                continue
                            }
                            numToName[cleaned!] = idToName[id!]
                        } else {
                            // TODO: log this
                        }
                    }
                }
            } catch {
                print("read and format contacts, number")
                print(error)
            }
        }
        
        return numToName
    }
}

