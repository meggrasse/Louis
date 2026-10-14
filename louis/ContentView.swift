//
//  ContentView.swift
//  louis
//
//  Created by Meg Grasse on 10/14/26.
//

import SwiftUI
import SwiftData
import WidgetKit

@Model
class Meal {
    @Attribute(.unique) var date: Date
    
    init(date: Date = .init()) {
        self.date = date
    }
}

struct Store {
    private static let config = ModelConfiguration(groupContainer: .identifier("group.com.grasse.louis"))
    static let container: ModelContainer = {
        do { return try ModelContainer(for: Meal.self, configurations: config) }
        catch {
            // TODO: You should still be able to see the record view.
            // Also there should be some error UI
            fatalError("Failed to create App Group ModelContainer: \(error)")
        }
    }()
}

struct ContentView: View {
    var body: some View {
        TabView {
            RecordView()
            FormView()
        }
        .modelContainer(Store.container)
    }
}

struct RecordView: View {
    @Environment(\.modelContext) private var context
    @Query var meals: [Meal]
    
    var body: some View {
        List {
            ForEach(meals) { meal in
                Text(meal.date, format: .dateTime.day().month().hour().minute())
            }
        }
    }
}

struct FormView: View {
    @Environment(\.modelContext) private var context
    var body: some View {
        VStack {
            Button {
                // Debug description is shown in UTC
                
                let meal = Meal(date: Date.now)
                context.insert(meal)
                // I don't have autosave enabled
                // TODO: handle error
                do {
                    try context.save()
                    WidgetCenter.shared.reloadAllTimelines()
                    print("Writing \(Date.now) to the db")
                }
                catch {
                    print("Failed to write \(Date.now) to the db")
                }
                
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
