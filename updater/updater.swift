//
//  updater.swift
//  updater
//
//  Created by Meg Grasse on 10/14/26.
//

import WidgetKit
import SwiftUI

// TODO: Update casing of all file names
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        .init(date: .init())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let date = Date()
        let entry: Entry
        
        guard context.isPreview else { return }
        entry = .init(date: date)
        
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // Create a timeline entry for "now."
        let date = Date()
        let entry = Entry(date: date)
        
        
        // Create a date that's 15 minutes in the future.
        guard let update = Calendar.current.date(
            byAdding: .minute,
            value: 15,
            to: date
        )
        // TODO: is this allowed?
        else { return }
        
        
        // Create the timeline with the entry and a reload policy with the date
        // for the next update.
        let timeline = Timeline(
            entries: [entry],
            policy: .after(update)
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
}

struct MainView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("Time:")
            Text(entry.date, style: .time)
        }
        .containerBackground(.red.gradient, for: .widget)
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
    Entry(date: .now)
}
