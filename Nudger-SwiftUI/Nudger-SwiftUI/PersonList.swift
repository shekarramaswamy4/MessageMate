//
//  PersonList.swift
//  Nudger-SwiftUI
//
//  Created by shekar ramaswamy on 11/2/21.
//

import Foundation
import SwiftUI

// A view that shows the data for one Person row.
struct PersonRow: View {
    var cmh: ContactMessageHistory
    
    var body: some View {
        let recents = suggestionAPI.getRecentBurst(cm: cmh)
        
        HStack(alignment: .top, spacing: nil, content: {
            Text("\(cmh.name)")
                .bold()
            Spacer()
            Button(action: {
                apiManager.dismissSuggestion(cmh: cmh)
            }) {
                Text("Dismiss")
            }
            Button(action: {
                let urlStr = "sms:" + String(cmh.phoneNum.filter { !$0.isWhitespace })
                if let url = URL(string: urlStr) {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Text("Open")
            }.background(Color.blue)
                .cornerRadius(4)
        })
        VStack(alignment: .leading, spacing: nil, content: {
            ForEach(recents, id: \.self) {
                md in HStack(alignment: .top, spacing: nil, content: {
                    Text(convertTime(d: md.timeDelta))
                    Text(md.text)
                })
            }
        })
    }
}

struct PaymentView: View {
    @ObservedObject var apiM = apiManager
    
    @State private var codeInput: String = ""
    @State private var inputError: Bool = false
    
    var body: some View {
        let url = URL(string: apiM.paymentURL)!
        VStack(alignment: .center, spacing: 24, content: {
            Text("""
Your free trial has expired.

Pay $7 once to use MessageMate forever with updates.
""").multilineTextAlignment(TextAlignment.center)
            Button(action: {NSWorkspace.shared.open(url)}) {
                Link("Pay Now", destination: url).foregroundColor(Color.black)
            }.background(Color.blue).cornerRadius(4)
            Text("""
After you pay, enter the code you receive by email here:
""").multilineTextAlignment(TextAlignment.center)
            TextField("", text: $codeInput)
                .frame(width: 100)
                .multilineTextAlignment(.center)
                .foregroundColor(apiM.paymentError ? Color.red : Color.primary)
                .onAppear {
                    DispatchQueue.main.async {
                        NSApp.keyWindow?.makeFirstResponder(nil)
                    }
                }.onChange(of: codeInput) { newValue in
                    apiM.paymentError = false
                }
            Button(action: {
                apiM.validatePaymentCode(code: codeInput)
            }) {
                Text("Enter Code")
            }
        })
    }
}

struct NoAccessView: View {
    var url: URL
    
    var body: some View {
        VStack(alignment: .center, spacing: 24, content: {
            // TODO: format this better probably
            Text("""
Please allow file access to use MessageMate.

Your data never leaves your Mac.
""").multilineTextAlignment(TextAlignment.center)
            Button(action: {NSWorkspace.shared.open(url)}) {
                Link("Allow Access", destination: url).foregroundColor(Color.black)
            }.background(Color.blue).cornerRadius(4)
        })
    }
}

struct NoSuggestionsView: View {
    var body: some View {
        VStack(alignment: .center, spacing: nil, content: {
            Text("""
No reminders!

Enjoy the peace of mind. 😌
""").multilineTextAlignment(TextAlignment.center)
        })
    }
}

struct LoadingFirstTimeView: View {
    var body: some View {
        VStack(alignment: .center, spacing: nil, content: {
            Text("""
Loading your reminders!

This one-time setup should take a few minutes.
""").multilineTextAlignment(TextAlignment.center)
        })
    }
}

struct FreeTrialView: View {
    @ObservedObject var apiM = apiManager
    
    @State private var trialLeft: String = ""
    
    init() {
        let endOfTrial = apiM.initializeUnixSecond + Double(Constants.freeTrialDuration) * 60 * 60
        _trialLeft = State(initialValue: convertTime(d: endOfTrial - Date().timeIntervalSince1970))
    }
    
    var body: some View {
        Spacer()
        VStack(alignment: .center) {
            Text("\(trialLeft) left in free trial")
        }
        Spacer()
    }
}

struct FooterView: View {
    var showRemindMeAfterPrompt: Bool
    var showSupportEmail: Bool = false
    
    @ObservedObject var apiM = apiManager
    
    @State private var remindWindow: String = "24"
    @State private var canBeDone: Bool = false
    @State private var inputError: Bool = false

    init(showRemindMeAfterPrompt: Bool, showSupportEmail: Bool = false) {
        self.showRemindMeAfterPrompt = showRemindMeAfterPrompt
        self.showSupportEmail = showSupportEmail
        _remindWindow = State(initialValue: "\(apiM.remindWindow)")
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: nil, content: {
            if showRemindMeAfterPrompt {
                HStack {
                    Text("Remind me after")
                    
                    TextField("", text: $remindWindow)
                        .frame(width: 40)
                        .multilineTextAlignment(.center)
                        .foregroundColor(inputError ? Color.red : Color.primary)
                        .onAppear {
                            DispatchQueue.main.async {
                                NSApp.keyWindow?.makeFirstResponder(nil)
                            }
                        }
                    
                    Text("h")
                    
                    if canBeDone {
                        Button(action: {
                            // Perform action when done button is tapped
                            // For example: schedule reminder with remindHours value
                            canBeDone = false
                            apiM.setRemindWindow(window: Int(remindWindow) ?? Constants.defaultRemindWindow)
                        }) {
                            Text("Done")
                        }
                    }
                }.onChange(of: remindWindow) { newValue in
                    let intValue = Int(newValue)
                    if intValue == nil {
                        canBeDone = false
                        inputError = true
                        return
                    }
                    if intValue! <= 0 {
                        canBeDone = false
                        inputError = true
                        return
                    }
                    inputError = false
                    if apiM.remindWindow == intValue! {
                        canBeDone = false
                        return
                    }
                    canBeDone = true
                }
            }
            if showSupportEmail {
                Text("Email shekar@ramaswamy.org for help")
            }
            
            Spacer()
            
            Button(action: {
                NSApp.terminate(nil)
            }) {
                Text("Quit")
            }
        }).foregroundColor(.primary)
            .onReceive(apiM.$remindWindow) { newValue in
            // This onReceive is essentially a proxy for when the popup reopens
            remindWindow = "\(newValue)"
            inputError = false
            DispatchQueue.main.async {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
    }
}

struct PersonList: View {
    @ObservedObject var apiM = apiManager
    
    var body: some View {
        let suggestions = apiManager.suggestionList.data
        
        return VStack(alignment: .center, spacing: nil, content: {
            if apiM.paymentStatus == "freeTrial" || apiM.paymentStatus == "paid" {
                if apiM.hasFullDiskAccess {
                    if apiM.firstLoad {
                        LoadingFirstTimeView()
                            .frame(width: 400, height: 300, alignment: .center)
                        FooterView(showRemindMeAfterPrompt: false).padding()
                    } else if suggestions.count == 0 {
                        NoSuggestionsView()
                            .frame(width: 400, height: 300, alignment: .center)
                        FooterView(showRemindMeAfterPrompt: true).padding()
                    } else {
                        if apiM.paymentStatus == "freeTrial" {
                            FreeTrialView().frame(width: 400, height: 10)
                        }
                        List(suggestions) { s in
                            PersonRow(cmh: s)
                            Divider()
                        }
                        FooterView(showRemindMeAfterPrompt: true).padding()
                    }
                } else {
                    NoAccessView(url: apiM.fullDiskAccessURL)
                        .frame(width: 400, height: 300, alignment: .center)
                    FooterView(showRemindMeAfterPrompt: false).padding()
                }
            } else {
                PaymentView()
                        .frame(width: 400, height: 300, alignment: .center)
                FooterView(showRemindMeAfterPrompt: false, showSupportEmail: true).padding()
            }
        })
    }
}

func printv( _ data : Any) -> EmptyView {
    print(data)
    return EmptyView()
}

func convertTime(d: Double) -> String {
    let days = Int(d / 60 / 60 / 24)
    if days != 0 {
        return String(days) + "d"
    }
    
    let hours = Int(d / 60 / 60)
    return String(hours) + "h"
}
