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
    @State private var bowlLocation: BowlLocation = .hall
    @State private var pets: Bool = true
//    @State private var eating = true
//    @State private var kind: LouisLocation.Means.Kind? = .selfInitiated
//    @State private var sleeping: Bool?
    @State private var louisLocation: LouisLocation = .here(.selfInitiated)
    
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
//                Rectangle().fill(.green.gradient)
//                    .opacity(0.6)
//                    .ignoresSafeArea()
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
                    
                    Section(header: Text("Serving")) {
                        ServingView(
                            bowlLocation: $bowlLocation,
                            pets: $pets,
                            louisLocation: $louisLocation
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
        let now = Date.now
        let newMeal = Meal(
            startDate: now,
            startWeight: weight,
            brand: brand,
            waterVolume: volume,
            fresh: fresh
        )
        
        let serving = Serving(
            meal: newMeal,
            startDate: Date.now,
            pets: pets,
            bowlLocation: bowlLocation,
            louisLocation: louisLocation
        )
        
        context.insert(newMeal)
        context.insert(serving)
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

struct ServingView: View {
    @Binding var bowlLocation: BowlLocation
    @Binding var pets: Bool
    @Binding var louisLocation: LouisLocation
//    @Binding var eating: Bool
//    @Binding var kind: LouisLocation.Means.Kind?
//    @Binding var sleeping: Bool?
    var body: some View {
        LabeledContent {
            Picker("Bowl Location", selection: $bowlLocation) {
                ForEach(BowlLocation.allCases) {
                    Image(systemName: $0.icon).tag($0)
                }
            }
            .pickerStyle(.segmented)
        } label: {
//            Image(systemName: "location")
            Text("Where?")
        }
        
        LabeledContent {
            HStack {
                Toggle(isOn: $louisLocation.here) {
                    Label("Here", systemImage: "location")
                }
                .toggleStyle(.button)
                .labelStyle(.iconOnly)
                
                Picker("Kind", selection: $louisLocation.kind) {
                    ForEach(LouisLocation.Means.Kind.allCases) {
                        Image(systemName: $0.icon).tag($0)
                    }
                }
                .disabled(!louisLocation.here)
                .pickerStyle(.segmented)
                
                Toggle(
                    isOn: Binding(
                        get: { louisLocation.sleeping == true},
                        set: { louisLocation.sleeping = $0 }
                    )
                ) {
                    Label("Bowl", systemImage: "moon.zzz")
                }
                .toggleStyle(.button)
                .labelStyle(.iconOnly)
                .disabled(louisLocation.kind == nil || louisLocation.kind == .selfInitiated)
            }
        } label: {
            Text("Here?")
        }
        
        Toggle(isOn: $pets) {
            Text("Pets?")
        }
        
//        .onChange(of: louisLocation.here) { _, newValue in
//            guard !newValue else { return }
//            louisLocation.k = nil
//        }
//        .onChange(of: transportKind) { _, newValue in
//            if newValue == nil || newValue == .agentic {
//                sleeping = nil
//            }
//        }
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

extension BowlLocation {
    fileprivate var label: String {
        "\(self.rawValue.capitalized)"
    }
}

extension LouisLocation {
    var here: Bool {
        get {
            switch self {
            case .here: true
            default: false
            }
        }
        set {
            guard here != newValue else { return }
            if newValue {
                self = .here(.selfInitiated)
            } else {
                self = .missing
            }
        }
    }
    
    var kind: Means.Kind? {
        get {
            switch self {
            case .here(let means): means.kind
            case .missing: nil
            }
        }
        set {
            guard kind != newValue else { return }
            guard let newValue else {
                self = .missing
                return
            }
            switch newValue {
            case .selfInitiated: self = .here(.selfInitiated)
            case .provisioned: self = .here(.provisioned(sleeping: sleeping == true))
            case .carried: self = .here(.carried(sleeping: sleeping == true))
            }
        }
    }
    
    var sleeping: Bool? {
        get {
            switch self {
            case .here(.provisioned(sleeping: let sleeping)):
                sleeping
            case .here(.carried(sleeping: let sleeping)):
                sleeping
            default: nil
            }
        }
        set {
            guard sleeping != newValue else { return }
            guard let newValue else {
                assertionFailure("`LouisLocation.Means.Kind.sleeping` shouldn't be set to nil by the UI.")
                return
            }
            switch self {
            case .missing:
                assertionFailure("`LouisLocation.Means.Kind.sleeping` was set from a `.missing` state.")
            case .here(let means):
                switch means {
                case .selfInitiated:
                    assertionFailure("`LouisLocation.Means.Kind.sleeping` was set from a `.selfInitiated` state.")
                case .provisioned(_):
                    self = .here(.provisioned(sleeping: newValue))
                case .carried(_):
                    self = .here(.carried(sleeping: newValue))
                }
            }
        }
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

