//
//  RecordView.swift
//  louis
//
//  Created by Meg Grasse on 10/15/26.
//

import SwiftUI
import SwiftData


// TODO: Fix deletion animation
// TODO: Add indicator for currently in progress view


struct RecordView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Meal.startDate) var meals: [Meal]

    // TODO: Get section queries in macos27
    // Dictionary workaround, including redundant date key, as `@Query` can't do sections yet.
//    private var sections: [Date: [Meal]] {
//        Dictionary(grouping: meals) {
//            Calendar.current.startOfDay(for: $0.startDate)
//        }
//    }
    
    @State private var deletionMeal: Meal?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(meals) { meal in
                    // TODO: section by date
                    NavigationLink {
                        RecordDetailView(meal: meal)
                    } label: {
                        Text("Meal Start: \(meal.startDate, format: .dateTime.day().month().hour().minute())")
                    }
                    // `.onDelete` seems to remove the item from the UI.
                    // TODO: comment
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deletionMeal = meal
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .alert(
                "Are you sure you want to delete the record of this meal?",
                isPresented: .init(
                    get: { deletionMeal != nil },
                    set: { isPresented in
                        guard !isPresented else { return }
                        deletionMeal = nil
                    }
                ),
                presenting: deletionMeal
            ) { meal in
                Button("Delete", role: .destructive) {
                    context.delete(meal)
                    do { try context.save() }
                    catch { fatalError() } // TODO: real error handling
                }
                Button("Cancel", role: .cancel) {
                    // no-op
                }
            }
            .navigationTitle("Records")
        }
    }
}

#Preview {
    RecordView()
        .modelContainer(SampleData.shared.modelContainer)
}

class SampleData {
    static let shared = SampleData()
    
    let modelContainer: ModelContainer
    
    var context: ModelContext {
        modelContainer.mainContext
    }
    
    init() {
        let schema = Schema([
            Meal.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            Self.Meals.forEach { context.insert($0) }
            try context.save()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private static let Meals = [
        Meal(
            startDate: Date.now - 3 * 60 * 60, // TODO: clean up
            endDate: Date.now,
            startWeight: 5,
            endWeight: 3,
            brand: .royalCanin(.chicken),
            waterQuantity: 0,
            waterUnits: .tablespoons,
            fresh: true
        ),
        Meal(
            startDate: Date.now,
            startWeight: 5,
            brand: .royalCanin(.chicken),
            waterQuantity: 0,
            waterUnits: .tablespoons,
            fresh: false
        )
    ]
}
