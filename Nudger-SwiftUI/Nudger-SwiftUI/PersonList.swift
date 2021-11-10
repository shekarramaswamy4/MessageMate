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
            }
        })
        VStack(alignment: .leading, spacing: nil, content: {
            ForEach(recents, id: \.self) {
                md in HStack(alignment: .top, spacing: nil, content: {
                    Text(String(Int(md.timeDelta / 60 / 60 / 24)) + "d")
                    Text(md.text)
                })
            }
        })
    }
}

struct NoAccessView: View {
    var url: URL
    
    var body: some View {
        VStack(alignment: .center, spacing: nil, content: {
            Text("""
Please enable full disk access to use this app. In system preferences, click the + button and add the iMessage Assistant.


All data is kept on your Mac.
Please contact Shekar with any questions or concerns!
""").multilineTextAlignment(TextAlignment.center)
            Link("Enable access", destination: url)
        })
    }
}

struct FooterView: View {
    
    var body: some View {
        HStack(alignment: .top, spacing: nil, content: {
            Text("⌘⇧M to open")
            Spacer()
            Button(action: {
                NSApp.terminate(nil)
            }) {
                Text("Quit")
            }
        })
    }
}

struct PersonList: View {
    @ObservedObject var apiM = apiManager

    var body: some View {
        let suggestions = apiManager.suggestionList.data
        
        return VStack(alignment: .center, spacing: nil, content: {
            if apiM.hasFullDiskAccess {
                List(suggestions) { s in
                    PersonRow(cmh: s)
                    Divider()
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
