//
//  ContentView.swift
//  louis
//
//  Created by Meg Grasse on 10/14/26.
//

import SwiftUI
import SwiftData

@Model
class Meal {
    @Attribute(.unique) var date: Date
    
    init(date: Date = .init()) {
        self.date = date
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Button {
                // Debug description is shown in UTC
                print(Date.now)
            } label: {
                Text("Feed")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

// I probably want to be able to visualize the data in the app as well. I.e. a records view
