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
                    Text("Weight (kg): \(meal.startWeight)")
                    Text("Meal End: \(String(describing: meal.endDate?.formatted(.dateTime.day().month().hour().minute())))")
                    Text("Weight (kg): \(String(describing: meal.endWeight))")
                    Text("Brand: \(meal.brand.label)")
                    Text("Water: \(meal.waterVolume) l")
                    Text("Fresh: \(meal.fresh)")
                }
                .border(Color.gray)
                .padding()
            }
        }
    }
}
