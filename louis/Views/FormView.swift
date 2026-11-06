//
//  FormView.swift
//  louis
//
//  Created by Meg Grasse on 10/15/26.
//

import SwiftUI
import SwiftData

// TODO: Ensure all cells are the same height.

struct FormView: View {
    
    // MARK: State
    
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Meal> { $0.endDate == nil }) private var openMeals: [Meal]
    
    // I'm simply using scalars to denote mass here as `Measurement<UnitMass>` can't be persisted by SwiftData
    // (it doesn't know how to store `UnitMass` types). Yes, I could try `Measurement`'s codable conformance
    // but we don't yet need to support multiple mass units, so it's simpler to just store a scalar.
    @State private var nextMealStartWeight: Double?
    @State private var lastMealEndWeight: Double?
    @State private var brand: Brand = .royalCanin(.chicken)
    @State private var waterQuantity: Double? = DefaultValues.waterQuantity // TextField's need optional bindings
    @State private var waterUnits = DefaultValues.waterUnits
    @State private var fresh = true
    
    @FocusState private var showKeyboard: Bool
    
    // TODO: Add alert à la `onlyUpdateLastMeal` if end weight is greater than start weight.
    enum AlertState {
        case missingAllWeights
        case overlapsLastMeal
        case onlyUpdateLastMeal(Meal, Double) // TODO: Is this too messy?
        case writeFailed
        
        var title: String {
            switch self {
            case .missingAllWeights:
                return "No weights were provided."
            case .overlapsLastMeal:
                return "Provide finish weight before recording a new meal."
            case .onlyUpdateLastMeal:
                return "Are you sure you want to end the last meal without starting a new one?"
            case .writeFailed:
                return "Write to storage failed."
            }
        }
    }
    
    // TODO: Create Alertable protocol? Including titles for shared errors (e.g., `writeFailed`).
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
    
    @State private var alertState: AlertState?
    
    // MARK: View
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Finish weight", value: $lastMealEndWeight, format: .number)
                        .focused($showKeyboard)
                        .keyboardType(.decimalPad)
                        .disabled(openMeals.first == nil)
                } header: {
                    VStack(alignment: .leading) {
                        Text("Last Meal")
                        if let open = openMeals.first {
                            Text("Start weight: " + open.startWeight.displayWeight)
                                .font(.subheadline)
                        }
                        else {
                            Text("No currently open meal") // TODO: should this be part of the in progress story?
                                .font(.subheadline)
                        }
                    }
                }
                .card()
                
                Section(header: Text("Next Meal")) {
                    WeightTextField(
                        label: "Start weight",
                        weight: $nextMealStartWeight
                    )
                    .focused($showKeyboard)
                    
                    MetadataFormView(
                        brand: $brand,
                        fresh: $fresh,
                        waterQuantity: $waterQuantity,
                        waterUnits: $waterUnits,
                        startWeight: $nextMealStartWeight,
                        showKeyboardBinding: $showKeyboard
                    )
                }
                .card()
            }
            .onAppear {
                guard openMeals.count <= 1
                else {
                    assertionFailure("Multiple meals are currently open.")
                    return
                }
                
                if let open = openMeals.first {
                    brand = open.brand
                    fresh = !open.fresh
                }
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Mealtime")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        save()
                    } label: {
                        Image(systemName: "fork.knife")
                    }
                }
            }
            .alert(
                alertState.title,
                isPresented: isAlertPresented,
                presenting: alertState
            ) { state in
                switch state {
                case .onlyUpdateLastMeal(let meal, let weight):
                    Button(role: .cancel) {}
                    Button("Yes", role: .confirm) {
                        recordLastMeal(meal: meal, endWeight: weight)
                        write()
                    }
                case .missingAllWeights, .overlapsLastMeal, .writeFailed:
                    Button(role: .cancel) {}
                }
            }
        }
    }
    
    // MARK: Helpers
    
    func save() {
        switch (openMeals.first, lastMealEndWeight, nextMealStartWeight) {
        case (_, .none, .none):
            // Regardless of if a meal was open, neither finish or start weight were provided.
            // A new meal can't be recorded without a start weight.
            alertState = .missingAllWeights
        case (.some, .none, .some):
            // A start weight was provided with no finish weight, and there was already a meal going on.
            // This would imply overlapping meals, which isn't allowed
            alertState = .overlapsLastMeal
        case let (meal?, endWeight?, .none):
            // If only the last meal weight was provided, we're ending a meal without
            // starting a new one. This is an unexpected case so warn the user.
            alertState = .onlyUpdateLastMeal(meal, endWeight)
        case let (meal?, endWeight?, startWeight?):
            // Normal case: all fields are provided (and last meal was open).
            recordLastMeal(meal: meal, endWeight: endWeight)
            recordNewMeal(startWeight: startWeight)
            write()
        case let (.none, .none, startWeight?):
            // Normal case: last meal has already ended
            recordNewMeal(startWeight: startWeight)
            write()
        case (.none, .some, _):
            // There's no open last meal, but the user inputted data.
            // This should be protected against in the UI.
            assertionFailure("User shouldn't be able to provide last meal weight when last meal isn't open.")
        }
    }
    
    func recordLastMeal(meal: Meal, endWeight: Double) {
        meal.endDate = Date.now
        meal.endWeight = endWeight
    }
    
    func recordNewMeal(startWeight: Double) {
        let now = Date.now
        let newMeal = Meal(
            startDate: now,
            startWeight: startWeight,
            brand: brand,
            waterQuantity: waterQuantity ?? 0,
            waterUnits: waterUnits,
            fresh: fresh
        )
        
        context.insert(newMeal)
    }
    
    func write() {
        do {
            try context.save()
            // TODO: Hook up to widget
//            WidgetCenter.shared.reloadAllTimelines()
            resetState()
        }
        catch {
            // Use next run loop in case the write fails from confirming the
            // only last meal alert.
            Task { @MainActor in alertState = .writeFailed }
        }
    }
    
    func resetState() {
        lastMealEndWeight = nil
        nextMealStartWeight = nil
        waterQuantity = DefaultValues.waterQuantity
        waterUnits = DefaultValues.waterUnits
        showKeyboard = false
    }
}

// TODO: Move
struct DefaultValues {
    static let waterQuantity: Double? = nil
    static let waterUnits = UnitVolume.tablespoons
}

// TODO: Move to Alertable protocol?
extension Optional<FormView.AlertState> {
    var title: String { self?.title ?? "" }
}

// TODO: Move to a general purpose place
extension View {
    func card() -> some View {
        listRowBackground(Rectangle().fill(.ultraThinMaterial))
    }
}

extension Double {
    var displayWeight: String {
        formatted(.number.precision(.fractionLength(2))) + " " +  Meal.weightUnit.symbol
    }
    
    // TODO: where am i using this?
    func displayVolume(with unit: UnitVolume) -> String {
        formatted(.number.precision(.fractionLength(0))) + " " +  unit.symbol
    }
}

#Preview {
    FormView()
}
