//
//  updater.swift
//  updater
//
//  Created by Meg Grasse on 10/14/26.
//

import WidgetKit
import SwiftUI
import SwiftData

// TODO: This needs to be shared in a library
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

// TODO: Update casing of all file names
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        .init(date: .init(), mealDate: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let date = Date()
        let entry: Entry
        
        guard context.isPreview else { return }
        entry = .init(date: date, mealDate: nil)
        
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        var descriptor = FetchDescriptor<Meal>(
            sortBy: [
                .init(\.date, order: .reverse) // TODO
            ]
        )
        descriptor.fetchLimit = 1
        
        let meal = try? ModelContext(Store.container).fetch(descriptor).first
        
        let date = Date.now
        let entry = Entry(date: date, mealDate: meal?.date)
        
        
        // Create the timeline with the entry and a reload policy with the date
        // for the next update.
        let timeline = Timeline(
            entries: [entry],
            // We reload when the user submits in the main app.
            policy: .never
        )
        
        
        // In this example, if the widget didn’t have the current status from the server,
        // it could store a reference to the completion, perform an asynchronous request
        // to the server to fetch the game status, and call the completion when that
        // request completes.
        completion(timeline)
    }
}

struct Entry: TimelineEntry {
    let date: Date
    let mealDate: Date?
}

struct MainView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Last Meal:")
            if let mealDate = entry.mealDate {
                Text(mealDate, style: .date)
                Text(mealDate, style: .time)
            }
            else {
                Text("None")
            }
            
        }
        .containerBackground(.green.gradient, for: .widget)
    }
}

// TODO
//@main
struct Updater: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.grasse.louis.updater",
            provider: Provider(),
        ) { entry in
            MainView(entry: entry)
        }
        .configurationDisplayName("Louis Updater")
        .description("Update configuration of most recent meal")
        // TODO - this didn't seem to matter for the preview
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    Updater()
} timeline: {
    Entry(
        date: .now,
        mealDate: Calendar.current.date(
            from: DateComponents(
                year: 2026,
                month: 10,
                day: 14,
                hour: 9,
                minute: 0
            )
        )!
    )
}
