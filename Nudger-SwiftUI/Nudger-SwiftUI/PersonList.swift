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
                let urlStr = "sms:" + String(cmh.phoneNum.filter { !$0.isWhitespace })
                if let url = URL(string: urlStr) {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Text("Open")
            }
            Button(action: {
                apiManager.dismissSuggestion(cmh: cmh)
            }) {
                Text("Done")
            }.background(Color.blue)
                .foregroundColor(Color.white)
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

struct NoAccessView: View {
    var url: URL
    
    var body: some View {
        VStack(alignment: .center, spacing: 24, content: {
            Text("""
Please enable full disk access to use the iMessage Assistant.

No data ever leaves your Mac.
""").multilineTextAlignment(TextAlignment.center)
            Button(action: {NSWorkspace.shared.open(url)}) {
                Link("Enable Access", destination: url).foregroundColor(Color.black)
            }.background(Color.blue).cornerRadius(4)
        })
    }
}

struct NoSuggestionsView: View {
    var body: some View {
        VStack(alignment: .center, spacing: nil, content: {
            Text("""
No suggestions! Enjoy the peace of mind. 😌
""").multilineTextAlignment(TextAlignment.center)
        })
    }
}

struct LoadingFirstTimeView: View {
    var body: some View {
        VStack(alignment: .center, spacing: nil, content: {
            Text("""
Loading your suggestions!

The icon will change once finished.
""").multilineTextAlignment(TextAlignment.center)
        })
    }
}

struct FooterView: View {
    
    var body: some View {
        // TODO: customize time window
        HStack(alignment: .top, spacing: nil, content: {
            Text("⌘⇧M to open")
            Spacer()
            Button(action: {
                NSApp.terminate(nil)
            }) {
                Text("Quit")
            }
        }).foregroundColor(.primary)
    }
}

struct PersonList: View {
    @ObservedObject var apiM = apiManager

    var body: some View {
        let suggestions = apiManager.suggestionList.data
        
        return VStack(alignment: .center, spacing: nil, content: {
            if apiM.hasFullDiskAccess {
                if apiM.firstLoad {
                    LoadingFirstTimeView()
                        .frame(width: 400, height: 300, alignment: .center)
                } else if suggestions.count == 0 {
                    NoSuggestionsView()
                        .frame(width: 400, height: 300, alignment: .center)
                } else {
                    List(suggestions) { s in
                        PersonRow(cmh: s)
                        Divider()
                    }
                }
            } else {
                NoAccessView(url: apiM.fullDiskAccessURL)
                    .frame(width: 400, height: 300, alignment: .center)
            }
            FooterView().padding()
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
