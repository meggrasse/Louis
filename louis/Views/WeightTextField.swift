//
//  WeightTextField.swift
//  louis
//
//  Created by Meg Grasse on 06/11/2026.
//

import SwiftUI

// TODO: Rename to LabeledWeightTextField. And include a wildcard arg in the init for `label`.
struct WeightTextField: View {
    var label: String
    @Binding var weight: Double?
    
    var body: some View {
        LabeledContent {
            HStack {
                TextField("Measurement", value: $weight, format: .number)
                    .keyboardType(.decimalPad)
                Text(Meal.weightUnit.symbol)
                    .foregroundStyle(.primary)
            }
            .multilineTextAlignment(.trailing)
        } label: {
            Text(label)
        }
    }
}
