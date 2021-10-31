//
//  Data.swift
//  Assistant
//
//  Created by shekar ramaswamy on 10/31/21.
//

import Foundation
import GRDB

class Data {
    
    func getData() {
        let numToName = self.readAndFormatContacts()
        let data = self.readAndFormatChats(numToName: numToName)
        print(data.count)
        print(data[0].name)
        print(data[0].phoneNum)
    }
    
    private func readAndFormatChats(numToName: [String:String]) -> [ContactMessageHistory] {
        var url = try? FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        url = url!.appendingPathComponent("Messages", isDirectory: true).appendingPathComponent("chat.db", isDirectory: false)
        
        print(url?.absoluteString)
        
        var numToMessages: [String: [MessageData]] = [:]
        do {
            let dbQueue = try DatabaseQueue(path: url!.absoluteString)
            
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
ORDER BY
    message_date DESC
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
                    
                    let prettyDate: String = row["messageDate"]
                    let text: String? = row["text"]
                    let isFromMe: Bool = row["isFromMe"]
                    
                    let md = MessageData(prettyDate: prettyDate, timestamp: 0, timeDelta: 0, text: text ?? "", isFromMe: isFromMe)
                    
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
            print(error)
        }
        
        var cmh: [ContactMessageHistory] = []
        for (key, val) in numToMessages {
            let c = ContactMessageHistory(phoneNum: key, name: numToName[key]!, messageData: val)
            cmh.append(c)
        }
        
        return cmh
    }
    
    func readAndFormatContacts() -> [String:String] {
        var url = try? FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        url = url!.appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("AddressBook", isDirectory: true)
            .appendingPathComponent("Sources", isDirectory: true)
        
        // Remove file:// from beginning of string
        var cleaned = String(url!.absoluteString.dropFirst(7))
        // Clean URL string encoding
        cleaned = cleaned.replacingOccurrences(of: "%20", with: " ")

        let fileList = try! FileManager.default.contentsOfDirectory(atPath: cleaned)
        
        var idToName: [String:String] = [:]
        var numToName: [String:String] = [:]
        for f in fileList {
            if f == ".DS_Store" { continue }
            var dbUrl = url
            dbUrl = dbUrl!.appendingPathComponent(f, isDirectory: true)
                .appendingPathComponent("AddressBook-v22.abcddb", isDirectory: false)
                    
            do {
                let dbQueue = try DatabaseQueue(path: dbUrl!.absoluteString)
                
                var query = "select Z_PK as id, ZSORTINGFIRSTNAME as name from ZABCDRECORD order by Z_PK asc"
                try dbQueue.read { db in
                    let rows = try Row.fetchCursor(db, sql: query)
                    while let row = try rows.next() {
                        let id: String? = row["id"]
                        let name: String? = row["name"]
                        if id == nil || name == nil {
                            continue
                        }
                        
                        // TODO: clean name
                        idToName[id!] = name!
                    }
                }
                
                query = "select ZOWNER as id, ZFULLNUMBER as number from ZABCDPHONENUMBER order by ZOWNER asc"
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
                print(error)
            }
        }
        
        return numToName
    }
}
