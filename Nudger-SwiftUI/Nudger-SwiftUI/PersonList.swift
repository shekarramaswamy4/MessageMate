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

struct PersonList: View {
    @ObservedObject var apiManager = APIManager()

    var body: some View {
        let suggestions = apiManager.suggestionList.data
        printv(suggestions.count)
                
        return List(suggestions) { s in
            PersonRow(cmh: s)
            Divider()
        }
    }
}

func printv( _ data : Any) -> EmptyView {
     print(data)
     return EmptyView()
}
