//
//  EditView.swift
//  louis
//
//  Created by Meg Grasse on 05/11/2026.
//

import SwiftUI
import SwiftData

// TODO: Ensure height of each row is uniform
// TODO: Is there a better way to represent start/end weight for in-progress meals?
// TODO: All previews should pull from the same sample data.

// TODO: I think I want a utility where form fields can be populated from a meal. To avoid this redundant init.
// TODO: We also want to add a warning if start weight is less than end weight,
// like in FormView.
// TODO: Changing water units when quantity is 0 allows you to save changes. 
struct EditView: View {
    
    // MARK: API
    
    // TODO: Should Meal be a binding in case it's changed in the DB?
    var meal: Meal
    
    // MARK: Init
    
    init(meal: Meal) {
        self.meal = meal
        self._startDate = State(wrappedValue: meal.startDate)
        self._endDate = State(wrappedValue: meal.endDate)
        self._endWeight = State(wrappedValue: meal.endWeight)
        self._startWeight = State(wrappedValue: meal.startWeight)
        self._brand = State(wrappedValue: meal.brand)
        self._waterQuantity = State(wrappedValue: meal.waterQuantity)
        self._waterUnits = State(wrappedValue: meal.waterUnits)
        self._fresh = State(wrappedValue: meal.fresh)
    }
    
    // MARK: State
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @State private var startDate: Date
    @State private var endDate: Date?
    @State private var endWeight: Double?
    @State private var startWeight: Double? // `TextField`s need optional bindings
    @State private var brand: Brand = .royalCanin(.chicken)
    @State private var waterQuantity: Double? // `TextField`s need optional bindings
    @State private var waterUnits: UnitVolume
    @State private var fresh: Bool
    
    @State private var alertState: AlertState?
    
    @FocusState private var showKeyboard: Bool
    
    // TODO: Add alert (or warning, if applicable) when a field is missing
    enum AlertState {
        case invalidStartWeight
        case unsavedChanges
        case writeFailed
        
        var title: String {
            switch self {
            case .invalidStartWeight:
                return "Invalid start weight."
            case .unsavedChanges:
                return "Are you sure you want to discard your changes?"
            case .writeFailed:
                return "Write to storage failed." // TODO: duplicated
            }
        }
    }
    
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
    
    // MARK: View
    
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
                .card()
                
                Section {
                    WeightTextField(label: "Start weight", weight: $startWeight)
                        .focused($showKeyboard)
                    // Only show `endWeight` if it's been input on the Mealtime
                    // screen, for now.
                    if endWeight != nil {
                        WeightTextField(label: "End weight", weight: $endWeight)
                            .focused($showKeyboard)
                    }
                    
                }
                .card()
                
                MetadataFormView(
                    brand: $brand,
                    fresh: $fresh,
                    waterQuantity: $waterQuantity,
                    waterUnits: $waterUnits,
                    startWeight: $startWeight,
                    showKeyboardBinding: $showKeyboard,
                )
                .card()
            }
            .navigationTitle("Edit Meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        cancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        save()
                    }
                    .disabled(!hasChanges)
                }
            }
            .alert(
                alertState.title,
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
            .scrollContentBackground(.hidden)
        }
    }
    
    var hasChanges: Bool {
        // Unfortunately, `Model()` implements `Equatable` using pointer identity.
        if
            startDate == meal.startDate,
            endDate == meal.endDate,
            startWeight == meal.startWeight,
            endWeight == meal.endWeight,
            brand == meal.brand,
            waterQuantity == meal.waterQuantity,
            waterUnits == meal.waterUnits,
            fresh == meal.fresh
        {
            return false
        }
        return true
    }
    
    
    func save() {
        guard let startWeight else {
            // TODO: This should also be presented if the startWeight is
            // negative or 0
            alertState = .invalidStartWeight
            return
        }
        
        meal.startDate = startDate
        meal.endDate = endDate
        meal.startWeight = startWeight
        meal.endWeight = endWeight
        meal.brand = brand
        meal.waterQuantity = waterQuantity ?? 0
        meal.waterUnits = waterUnits
        meal.fresh = fresh
        
        do {
            try context.save()
            dismiss()
        }
        catch {
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

// TODO: Move to `Alertable` protocol.
extension Optional<EditView.AlertState> {
    var title: String { self?.title ?? "" }
}

#Preview {
    EditView(
        meal: .init(
            startDate: Date.now - 3 * 60 * 60,
            endDate: Date.now,
            startWeight: 2,
            endWeight: 5,
            brand: .royalCanin(.fish),
            waterQuantity: 0,
            waterUnits: .tablespoons,
            fresh: false
        )
    )
}
