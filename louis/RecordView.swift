//
//  RecordView.swift
//  louis
//
//  Created by Meg Grasse on 10/15/26.
//

import SwiftUI
import SwiftData

struct RecordView: View {
    @Environment(\.modelContext) private var context
    @Query var meals: [Meal]
    
    var body: some View {
        List {
            ForEach(meals) { meal in
                VStack {
                    Text("Meal Start: \(meal.startDate, format: .dateTime.day().month().hour().minute())")
                    Text("Start Weight: \(meal.startWeight) \(Meal.weightUnit.symbol)")
                    Text("Meal End: \(String(describing: meal.endDate?.formatted(.dateTime.day().month().hour().minute())))")
                    Text("End Weight: \(meal.startWeight) \(Meal.weightUnit.symbol)")
                    Text("Brand: \(meal.brand.label)")
                    Text("Water: \(meal.waterVolume) \(Meal.waterVolumeUnit.symbol)")
                    Text("Fresh: \(meal.fresh)")
                }
                ForEach(meal.servings) { serving in
                    VStack {
                        Text("Serving start: \(serving.startDate)")
//                        Text("Bowl location: \(serving.bowlLocation)")
//                        Text("louis location: \(serving.louisLocation.label)")
                        Text("pets: \(serving.pets)")
                    }
                }
                .border(Color.gray)
                .padding()
            }
        }
    }
}
