//
//  FormView.swift
//  louis
//
//  Created by Meg Grasse on 10/15/26.
//

import SwiftUI
import SwiftData
import WidgetKit

enum FormField {
    case finishWeight
    case startWeight
    case waterQuantity
}

struct FormView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Meal> { $0.endDate == nil }) private var openMeals: [Meal]
    
    @State private var finishWeight: Double?
    @State private var startWeight: Double?
    @State private var brand: Brand = .royalCanin(.chicken)
    @State private var waterQuantity: Double? = WaterDefaults.quatity
    @State private var waterUnits = WaterDefaults.units
    @State private var fresh = true
    
    @FocusState private var focus: FormField?
    
    struct WaterDefaults {
        static let quatity: Double = 1
        static let units = UnitVolume.tablespoons
    }
    
    enum AlertState {
        case missingAllWeights
        case overlapsLastMeal
        case onlyUpdateLastMeal(Meal, Double)
        case writeFailed
        
        var title: String {
            switch self {
            case .missingAllWeights:
                return "No weights were provided."
            case .overlapsLastMeal:
                return "Provide finish weight before recording a new meal."
            case .onlyUpdateLastMeal:
                return "Are you sure you want to record the last meal without starting a new one?"
            case .writeFailed:
                return "Write to storage failed."
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
    
    @State private var alertState: AlertState?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle().fill(.green.gradient)
                    .opacity(0.6)
                    .ignoresSafeArea()
                Form {
                    Section {
                        LastMealView(finishWeight: $finishWeight, focusBinding: $focus, openMeal: openMeals.first)
                    } header: {
                        VStack(alignment: .leading) {
                            Text("Last Meal")
                            Text(
                                "Start \(Image(systemName: "scalemass")): \(openMeals.first?.startWeight.formattedWeight ?? "N/A")"
                            )
                            .font(.subheadline)
                        }
                    }
                    .card()
                    
                    Section(header: Text("New Meal")) {
                        CurrentMealView(
                            brand: $brand,
                            fresh: $fresh,
                            waterQuantity: $waterQuantity,
                            waterUnits: $waterUnits,
                            startWeight: $startWeight,
                            focusBinding: $focus
                        )
                        .card()
                    }
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
                .navigationTitle("Record Meal")
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
                            recordLastMeal(meal: meal, weight: weight)
                            write()
                        }
                    case .missingAllWeights, .overlapsLastMeal, .writeFailed:
                        Button(role: .cancel) {}
                    }
                }
            }
        }
    }
    
    func save() {
        switch (openMeals.first, finishWeight, startWeight) {
        case (_, .none, .none):
            // Regardless of if a meal was open, neither finish or start weight were provided.
            // A new meal can't be recorded without a start weight.
            alertState = .missingAllWeights
        case (.some, .none, .some):
            // A start weight was provided with no finish weight, and there was already a meal going on.
            // This would imply overlapping meals, which isn't allowed
            alertState = .overlapsLastMeal
        case let (meal?, weight?, .none):
            // If only the last meal weight was provided, we're ending a meal without
            // starting a new one. This is an unexpected case so warn the user.
            alertState = .onlyUpdateLastMeal(meal, weight)
        case let (meal?, finishWeight?, startWeight?):
            // Normal case: all fields are provided (and last mean was open).
            recordLastMeal(meal: meal, weight: finishWeight)
            recordNewMeal(weight: startWeight)
            write()
        case let (.none, .none, weight?):
            // Normal case: last meal has already ended
            recordNewMeal(weight: weight)
            write()
        case (.none, .some, _):
            // There's no open last meal, but the user inputted data.
            // This should be protected against in the UI.
            assertionFailure("User shouldn't be able to provide last meal weight when last meal isn't open.")
        }
    }
    
    func recordLastMeal(meal: Meal, weight: Double) {
        meal.endDate = Date.now
        meal.endWeight = weight
    }
    
    func recordNewMeal(weight: Double) {
        let volume = waterUnits.converter.baseUnitValue(fromValue: waterQuantity ?? 0)
        let newMeal = Meal(
            startDate: Date.now,
            startWeight: weight,
            brand: brand,
            waterVolume: volume,
            fresh: fresh
        )
        context.insert(newMeal)
    }
    
    func write() {
        do {
            try context.save()
            WidgetCenter.shared.reloadAllTimelines()
            resetState()
        }
        catch {
            // Use next run loop in case the write fails from confirming the
            // only last meal alert.
            Task { @MainActor in alertState = .writeFailed }
        }
    }
    
    func resetState() {
        finishWeight = nil
        startWeight = nil
        waterQuantity = WaterDefaults.quatity
        waterUnits = WaterDefaults.units
        focus = nil
    }
}

struct LastMealView: View {
    @Binding var finishWeight: Double?
    var focusBinding: FocusState<FormField?>.Binding
    var openMeal: Meal?
    var body: some View {
        TextField("Finish weight", value: $finishWeight, format: .number)
            .focused(focusBinding, equals: .finishWeight)
            .keyboardType(.decimalPad)
            .disabled(openMeal == nil)
    }
}

struct CurrentMealView: View {
    @Binding var brand: Brand
    @Binding var fresh: Bool
    @Binding var waterQuantity: Double?
    @Binding var waterUnits: UnitVolume
    @Binding var startWeight: Double?
    var focusBinding: FocusState<FormField?>.Binding
    
    var body: some View {
        Picker("Brand", selection: $brand) {
            ForEach(Brand.allCases) {
                Text($0.label).tag($0)
            }
        }
        .pickerStyle(.segmented)
        
        Toggle(isOn: $fresh) {
            Text("New?")
        }
        
        TextField("Start weight", value : $startWeight, format: .number)
            .focused(focusBinding, equals: .startWeight)
            .keyboardType(.decimalPad)
        
        LabeledContent {
            HStack {
                TextField("Amount", value: $waterQuantity, format: .number)
                    .focused(focusBinding, equals: .waterQuantity)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Picker("Unit", selection: $waterUnits) {
                    Text(UnitVolume.tablespoons.symbol).tag(UnitVolume.tablespoons)
                    Text(UnitVolume.teaspoons.symbol).tag(UnitVolume.teaspoons)
                }
                .pickerStyle(.segmented)
            }
        } label: {
            Image(systemName: ("waterbottle"))
                .font(.headline)
        }
    }
}

extension Optional<FormView.AlertState> {
    var title: String { self?.title ?? "" }
}

extension View {
    fileprivate func card() -> some View {
        listRowBackground(Rectangle().fill(.ultraThinMaterial))
    }
}

extension Brand {
    fileprivate static var allCases: [Brand] {
        RoyalCaninFlavor.allCases.map { .royalCanin($0) }
    }
}

extension Double {
    var formattedWeight: String {
        formatted(.number.precision(.fractionLength(2)))
    }
}

#Preview {
    FormView()
}

