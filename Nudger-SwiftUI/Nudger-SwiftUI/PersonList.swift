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
        Text("\(cmh.name)")
    }
}

struct PersonList: View {

    var body: some View {
        Print("Refreshing data...")

        let data = dataAPI.getData()
        let suggestions = suggestionAPI.makeSuggestions(cmh: data)
        
        return List(suggestions) { s in
            PersonRow(cmh: s)
        }
    }
}

func printv( _ data : Any) -> EmptyView {
     print(data)
     return EmptyView()
}
