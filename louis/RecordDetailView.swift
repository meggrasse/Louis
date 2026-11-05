//
//  RecordDetailView.swift
//  louis
//
//  Created by Meg Grasse on 04/11/2026.
//

import SwiftUI
import SwiftData

// TODO: Consider sections and how to represent an in progress meal
// TODO: seperate into subview properties

// TODO: edit button turns into a checkmark

struct RecordDetailView: View {
    @State var meal: Meal
    
    @Environment(\.editMode) private var editMode
    // hmm
    @FocusState private var focus: FormField?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent {
//                        if editMode?.wrappedValue.isEditing == true {
//                            DatePicker(selection: $meal.startDate) { EmptyView() } // TODO: better pattern for hiding label?
//                                .datePickerStyle(.wheel)
//                        }
//                        else {
                            Text(
                                meal.startDate.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                            )
//                        }
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
                        Text(meal.startWeight.formattedWeight + " " +  Meal.weightUnit.symbol)
                    } label: {
                        Text("Start weight")
                    }
                    LabeledContent {
                        // TODO: use pattern above?
                        if let endWeight = meal.endWeight {
                            Text(endWeight.formattedWeight + " " +  Meal.weightUnit.symbol)
                        }
                        else {
                            // TODO: nothing?
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
                    // TODO: rename formattedWeight. Or making a formatting
                    // function with symbol
                    Text(meal.waterQuanitity.formattedWeight + " " + meal.waterUnits.symbol)
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
            // TODO: Add weights
            // TODO: extension around water i think
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

// TODO: vomit tracker

//// TODO: is it wrong to use wrappedvalue here
//extension Binding where Value == EditMode {
//    var isPresenting: Binding<Bool> {
//        Binding<Bool>(
//            get: { self.wrappedValue.isEditing },
//            set: { isPresenting in
//                guard !isPresenting else { return }
//                self.wrappedValue = .inactive
//            }
//        )
//    }
//}
