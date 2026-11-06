//
//  updater.swift
//  updater
//
//  Created by Meg Grasse on 10/14/26.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

struct Serve: AppIntent {
    static var title: LocalizedStringResource = "Serve"
    static var description = IntentDescription("Insert serving associated with current meal.")
    
    func perform() async throws -> some IntentResult {
        var mealDescriptor = FetchDescriptor<Meal>(
            predicate: #Predicate { $0.endDate == nil }
        )
        mealDescriptor.fetchLimit = 1
        
        let context = ModelContext(Store.container)
        guard let meal = try? context.fetch(mealDescriptor).first
        else {
            // TODO: handle error - also is this the right thing to return
            return .result()
        }
        
//        let louisLocation: LouisLocation
//        if ServingDefault.carried {
//            louisLocation = .here(.carried(sleeping: false))
//        }
//        else {
//            louisLocation = .here(.provisioned(sleeping: false))
//        }
        
//        let serving = Serving(meal: meal, startDate: Date.now, pets: false, bowlLocation: .hall, louisLocation: louisLocation)
//        context.insert(serving)

        try context.save()
        return .result()
    }
    
}

enum ServingDefault {
    static let defaults = UserDefaults(suiteName: "group.com.grasse.louis")!
    
    static var carried: Bool {
        get { defaults.bool(forKey: "serving.carried") }
        set { defaults.set(newValue, forKey: "serving.carried") }
    }
    // same for sleeping, pets, and location (store BowlLocation.rawValue)
}

struct ToggleCarried: AppIntent {
    static let title: LocalizedStringResource = "Toggle Serving Carried"
    func perform() async throws -> some IntentResult {
        ServingDefault.carried.toggle()
        return .result()
    }
}

// TODO: Update casing of all file names
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
//        .init(date: .init(), mealDate: nil, servingCount: nil, servingCarried: false)
        .init(date: .init(), mealDate: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let date = Date()
        let entry: Entry
        
        guard context.isPreview else { return }
//        entry = .init(date: date, mealDate: nil, servingCount: nil, servingCarried: false)
        entry = .init(date: date, mealDate: nil)
        
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let context = ModelContext(Store.container)
        var descriptor = FetchDescriptor<Meal>(
            sortBy: [
                .init(\.startDate, order: .reverse) // TODO
            ]
        )
        descriptor.fetchLimit = 1
        
        let meal = try? context.fetch(descriptor).first
        
        let date = Date.now
//        let entry = Entry(date: date, mealDate: meal?.startDate, servingCount: meal?.servings.count, servingCarried: ServingDefault.carried)
        let entry = Entry(date: date, mealDate: meal?.startDate)
        
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
//    let servingCount: Int?
//    let servingCarried: Bool
}

struct MainView: View {
    var entry: Provider.Entry
//    @State var bowlLocation: BowlLocation = .hall
    @State var carried: Bool = false
    @State var sleeping: Bool = false
    @State var pets: Bool = false

    var body: some View {
        VStack {
            Text("Last Meal:")
            if let mealDate = entry.mealDate {
                Text(mealDate, style: .date)
                Text(mealDate, style: .time)
//                Text("Servings: \(String(describing: entry.servingCount))")
//                Picker("Bowl Location", selection: $bowlLocation) {
//                    ForEach(BowlLocation.allCases) {
//                        Image(systemName: $0.icon).tag($0)
//                    }
//                }
//                .pickerStyle(.segmented)
//                HStack {
//                    Toggle(isOn: entry.servingCarried, intent: ToggleCarried()) {
//                        Label("Carried", systemImage: LouisLocation.Means.Kind.carried.icon)
//                    }
//                    .toggleStyle(.button)
//                    .labelStyle(.iconOnly)
//                    Toggle(isOn: $sleeping) {
//                        Label("Carried", systemImage: "moon.zzz")
//                    }
//                    .toggleStyle(.button)
//                    .labelStyle(.iconOnly)
//                    Toggle(isOn: $pets) {
//                        Label("Carried", systemImage: "pawprint")
//                    }
//                    .toggleStyle(.button)
//                    .labelStyle(.iconOnly)
//                    Button(intent: Serve()) {
//                        Image(systemName: "spoon.serving")
//                    }
//                }
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
//        servingCount: 2,
//        servingCarried: false
    )
}
