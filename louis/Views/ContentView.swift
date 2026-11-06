//
//  ContentView.swift
//  louis
//
//  Created by Meg Grasse on 10/14/26.
//

import SwiftUI
import WidgetKit
import SwiftData

// TODO: Consistent card and background treatment between all views.

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Bon Appetit!", systemImage: "fork.knife") {
                FormView()
            }
            Tab("Records", systemImage: "list.bullet") {
                RecordsView()
            }
        }
        .modelContainer(Store.container)
    }
}

#Preview {
    ContentView()
}
