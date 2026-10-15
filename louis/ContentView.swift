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
    @Attribute(.unique) var startDate: Date
    var endDate: Date?
    var startWeight: Double
    var endWeight: Double?
    
    init(startDate: Date, endDate: Date? = nil, startWeight: Double, endWeight: Double? = nil) {
        self.startDate = startDate
        self.endDate = endDate
        self.startWeight = startWeight
        self.endWeight = endWeight
    }
}

struct Store {
//    private static let config = ModelConfiguration(groupContainer: .identifier("group.com.grasse.louis"))
    // TODO just developemnet
    private static let config = ModelConfiguration(isStoredInMemoryOnly: true)
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

struct RecordView: View {
    @Environment(\.modelContext) private var context
    @Query var meals: [Meal]
    
    var body: some View {
        List {
            ForEach(meals) { meal in
                VStack {
                    Text("Meal Start: \(meal.startDate, format: .dateTime.day().month().hour().minute())")
                    Text("Weight (kg): \(meal.startWeight)")
                    Text("Meal End: \(String(describing: meal.endDate?.formatted(.dateTime.day().month().hour().minute())))")
                    Text("Weight (kg): \(String(describing: meal.endWeight))")
                }
                .border(Color.gray)
                .padding()
            }
        }
    }
}

struct FormView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Meal> { $0.endDate == nil }) private var openMeals: [Meal]
 
    @State private var oldWeight: Double?
    @State private var newWeight: Double?
    
    @FocusState private var focus: FormField?
    
    enum FormField {
        case oldWeight
        case newWeight
    }
    
    var body: some View {
        VStack {
            VStack {
                TextField("Old Weight (Kg)", value: $oldWeight, format: .number)
                    .focused($focus, equals: .oldWeight)
                TextField("New Weight (Kg)", value: $newWeight, format: .number)
                    .focused($focus, equals: .newWeight)
            }
            .keyboardType(.decimalPad)
            Button {
                // Close the previous meal, if there is one
                if openMeals.count > 1 {
                    // TODO: handle unexpected state
                }
                let now = Date.now
                if let openMeal = openMeals.first {
                    openMeal.endDate = now
                    openMeal.endWeight = oldWeight
                }
                // TODO hanlde if one isn't found
                
                if let newWeight {
                    let newMeal = Meal(startDate: now, startWeight: newWeight)
                    context.insert(newMeal)
                }
                // TODO hanlde if nothing appeared
                
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
                
                // reset state
                oldWeight = nil
                newWeight = nil
                focus = nil
                
            } label: {
                Text("Lunch time!")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
