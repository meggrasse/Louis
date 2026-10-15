//
//  ContentView.swift
//  louis
//
//  Created by Meg Grasse on 10/14/26.
//

import SwiftUI
import WidgetKit
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Weigh", systemImage: "scalemass") {
                FormView()
            }
            Tab("Records", systemImage: "list.star") {
                RecordView()
            }
        }
        .modelContainer(Store.container)
    }
}

#Preview {
    ContentView()
}
