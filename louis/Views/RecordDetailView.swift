//
//  RecordDetailView.swift
//  louis
//
//  Created by Meg Grasse on 04/11/2026.
//

import SwiftUI
import SwiftData

// TODO: Better indication of an in-progress meal.

struct RecordDetailView: View {
    @State var meal: Meal
    
    // TODO: Stop edit button from turning into a checkmark when we present the sheet.
    @Environment(\.editMode) private var editMode
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent {
                        Text(
                            meal.startDate.formatted(
                                date: .abbreviated,
                                time: .shortened
                            )
                        )
                    } label: {
                        Text("Start time")
                    }
                    LabeledContent {
                        Text(
                            meal.endDate?.formatted(
                                date: .abbreviated,
                                time: .shortened
                            ) ?? "None"
                        )
                    } label: {
                        Text("End time")
                    }
                }
                Section {
                    LabeledContent {
                        Text(meal.startWeight.displayWeight)
                    } label: {
                        Text("Start weight")
                    }
                    LabeledContent {
                        if let endWeight = meal.endWeight {
                            Text(endWeight.displayWeight)
                        }
                        else {
                            Text("None")
                        }
                    } label: {
                        Text("End weight")
                    }
                }
                LabeledContent {
                    Text(meal.brand.label)
                } label: {
                    Text("Flavor")
                }
                LabeledContent {
                    Text(meal.waterQuantity.displayVolume(with: meal.waterUnits))
                } label: {
                    Text("Water")
                }
                LabeledContent {
                    Text(meal.fresh.formatted())
                } label: {
                    Text("Fresh?")
                }
                
            }
            .navigationTitle("Meal")
            .toolbar { EditButton() }
        }
        .sheet(
            isPresented: .init(
                // Per `EditMode` docs, use `wrappedValue`.
                get: { editMode?.wrappedValue.isEditing == true},
                set: { isPresenting in
                    guard !isPresenting else { return }
                    editMode?.wrappedValue = .inactive
                }
            ),
        ) {
            EditView(meal: meal)
        }

    }
}

#Preview {
    RecordDetailView(
        meal: .init(
            startDate: Date.now,
            startWeight: 5,
            brand: .royalCanin(.beef),
            waterQuantity: 0,
            waterUnits: .tablespoons,
            fresh: true
        )
    )
}

extension Bool {
    func formatted() -> String {
        self ? "Yes" : "No"
    }
}
