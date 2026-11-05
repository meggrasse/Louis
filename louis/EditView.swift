//
//  EditView.swift
//  louis
//
//  Created by Meg Grasse on 05/11/2026.
//

import SwiftUI
import SwiftData

// I think I want a utility where form fields can be populated from a meal.
struct EditView: View {
    @Environment(\.modelContext) private var context
    var meal: Meal
    @Environment(\.dismiss) private var dismiss
    
    init(meal: Meal) {
        self.meal = meal
        self._startDate = State(wrappedValue: meal.startDate)
        self._endDate = State(wrappedValue: meal.endDate)
        self._endWeight = State(wrappedValue: meal.endWeight)
        self._startWeight = State(wrappedValue: meal.startWeight)
        self._brand = State(wrappedValue: meal.brand)
        self._waterQuantity = State(wrappedValue: meal.waterQuanitity)
        self._waterUnits = State(wrappedValue: meal.waterUnits.symbol)
        self._fresh = State(wrappedValue: meal.fresh)
    }
    
    
    @State private var startDate: Date
    @State private var endDate: Date?
    @State private var endWeight: Double?
    @State private var startWeight: Double? // `TextField`s need optional bindings
    @State private var brand: Brand = .royalCanin(.chicken)
    @State private var waterQuantity: Double? // `TextField`s need optional bindings
    @State private var waterUnits: String
    @State private var fresh: Bool
    
    @FocusState private var focus: FormField?
    @State private var alertState: AlertState?
    
    enum AlertState {
        case invalidStartWeight
        case unsavedChanges
        case writeFailed
        
        var title: String {
            switch self {
            case .invalidStartWeight:
                return "Invalid start weight." // TODO: also ensure positive int
            case .unsavedChanges:
                return "Are you sure you want to discard your changes?"
            case .writeFailed:
                return "Write to storage failed." // TODO: duplicated
            }
        }
    }
    
    // Good candidate for an `Alertable` protocol
    var isAlertPresented: Binding<Bool> {
        Binding(
            get: { alertState != nil },
            set: { isPresented in
                guard !isPresented else {
                    assertionFailure("We don't expect SwiftUI to ever set an alert presentation binding to true.")
                    return
                }
                alertState = nil
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Start time", selection: $startDate)
                    if let unwrappedEndDate = endDate {
                        DatePicker(
                            "End time",
                            selection: .init(
                                get: { unwrappedEndDate },
                                set: { endDate = $0 }
                            )
                        )
                    }
                }
//                .card()  maybe an issue
                
                // mention units?
                Section {
                    LabeledContent {
                        TextField("Weight", value: $startWeight, format: .number)
                    } label: {
                        Text("Start weight")
                    }
//                        .focused(focusBinding, equals: .startWeight)
                        .keyboardType(.decimalPad)
                    LabeledContent {
                        TextField("Weight", value: $endWeight, format: .number)
                    } label: {
                        Text("End weight")
                    }
                    //                        .focused(focusBinding, equals: .startWeight)
                    .keyboardType(.decimalPad)
                }
                .multilineTextAlignment(.trailing)
//                .card()
                
                CurrentMealView(
                    editing: true,
                    brand: $brand,
//                    startDate: $startDate,
                    fresh: $fresh,
                    // TODO: remember units for editing
                    waterQuantity: $waterQuantity,
                    waterUnits: $waterUnits,
                    startWeight: $startWeight,
                    focusBinding: $focus
                )
//                .card()
            }
            .navigationTitle("Edit Meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        cancel()
                    }
                    // TODO: show alert if changes have been made.
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        save()
                    }
                    .disabled(!hasChanges)
                }
            }
            .alert(
                alertState?.title ?? "", // TODO
                isPresented: isAlertPresented,
                presenting: alertState
            ) { state in
                switch state {
                case .unsavedChanges:
                    Button("Back", role: .cancel) {}
                    Button("Discard", role: .destructive) {
                        dismiss()
                    }
                case .invalidStartWeight, .writeFailed:
                    Button(role: .cancel) {}
                }
            }
            .interactiveDismissDisabled(hasChanges)
        }
    }
    
    var hasChanges: Bool {
        // Unfortunately, `Model()` implements `Equatable` using pointer identitiy.
        // TODO: move to an extension
        if
            startDate == meal.startDate,
            endDate == meal.endDate,
            startWeight == meal.startWeight,
            endWeight == meal.endWeight,
            brand == meal.brand,
            waterQuantity == meal.waterQuanitity,
            waterUnits == meal.waterUnits.symbol, // something weird with UnitVolume...
            fresh == meal.fresh
        {
            return false
        }
        return true
    }
    
    
    func save() {
        // TODO: Alert
        guard let startWeight else {
            alertState = .invalidStartWeight
            return
        }
        
        // TODO: move to extension
        meal.startDate = startDate
        meal.endDate = endDate
        meal.startWeight = startWeight
        meal.endWeight = endWeight
        meal.brand = brand
        meal.waterQuanitity = waterQuantity ?? 0
        meal.waterUnits = .init(symbol: waterUnits)
        meal.fresh = fresh
        
        // The real tricky pattern is this could've changed in the DB. So maybe it should be a binding?
        do {
            try context.save()
            print("saved")
            dismiss()
            // dismiss
        }
        catch {
            // TODO: figure out if I want to reuse or create my own alerts
            Task { @MainActor in alertState = .writeFailed }
        }
        
        
    }
    
    func cancel() {
        if hasChanges {
            alertState = .unsavedChanges
        }
        else {
            dismiss()
        }
    }
}

#Preview {
    EditView(meal: .init(startDate: Date.now, startWeight: 2, brand: .royalCanin(.fish), waterQuantity: 0, waterUnits: .tablespoons, fresh: false))
    // Interesting, maybe different stuff needs to be used for water units? only two are supported in the UI.
}

// TODO: handle missing data in alert, etc.
// also i seem to be missing water bindings
