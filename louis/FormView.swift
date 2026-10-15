//
//  FormView.swift
//  louis
//
//  Created by Meg Grasse on 10/15/26.
//

import SwiftUI
import SwiftData
import WidgetKit

struct FormView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Meal> { $0.endDate == nil }) private var openMeals: [Meal]
    
    @State private var oldWeight: Double?
    @State private var newWeight: Double?
    
    @FocusState private var focus: FormField?
    
    enum FormField {
        case oldWeight
        case newWeight
        case waterQuantity
    }
    
    @State private var brand: Brand?
    @State private var waterQuantity: Double = 0
    @State private var waterUnits: UnitVolume = .tablespoons
    
    var body: some View {
        VStack {
            TextField("Old Weight (Kg)", value: $oldWeight, format: .number)
                .focused($focus, equals: .oldWeight)
                .keyboardType(.decimalPad)
            TextField("New Weight (Kg)", value: $newWeight, format: .number)
                .focused($focus, equals: .newWeight)
                .keyboardType(.decimalPad)
            
            
            Picker("Brand", selection: $brand) {
                Text("").tag(Brand?.none)
                ForEach(Brand.allCases) {
                    Text($0.label).tag($0, includeOptional: true)
                }
            }
            
            HStack {
                TextField("Amount", value: $waterQuantity, format: .number)
                    .focused($focus, equals: .waterQuantity)
                    .keyboardType(.decimalPad)
                Picker("Unit", selection: $waterUnits) {
                    Text(UnitVolume.tablespoons.symbol).tag(UnitVolume.tablespoons)
                    Text(UnitVolume.teaspoons.symbol).tag(UnitVolume.teaspoons)
                }
            }
            
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
                
                let volume = waterUnits.converter.baseUnitValue(fromValue: waterQuantity)
                if let newWeight, let brand {
                    let newMeal = Meal(startDate: now, startWeight: newWeight, brand: brand, waterVolume: volume)
                    context.insert(newMeal)
                }
                else {
                    // TODO: error handling. this is actually interesting as to how to best
                    // handle individual missing fields
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
        // TODO: test with persistent db
        .onAppear {
            brand = openMeals.first?.brand
        }
        .padding()
    }
}
