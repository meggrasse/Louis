//
//  MetadataFormView.swift
//  louis
//
//  Created by Meg Grasse on 06/11/2026.
//

import SwiftUI

struct MetadataFormView: View {
    @Binding var brand: Brand
    @Binding var fresh: Bool
    @Binding var waterQuantity: Double?
    @Binding var waterUnits: UnitVolume
    @Binding var startWeight: Double?
    var showKeyboardBinding: FocusState<Bool>.Binding
    
    var body: some View {
        LabeledContent {
            Picker("Brand", selection: $brand) {
                ForEach(Brand.allCases) {
                    Text($0.label).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: brand) {
                showKeyboardBinding.wrappedValue = false
            }
        } label: {
            Text("Flavor")
        }
        
        LabeledContent {
            HStack {
                TextField("Quantity", value: $waterQuantity, format: .number)
                    .focused(showKeyboardBinding)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Picker("Unit", selection: $waterUnits) {
                    Text(UnitVolume.tablespoons.symbol).tag(UnitVolume.tablespoons)
                    Text(UnitVolume.teaspoons.symbol).tag(UnitVolume.teaspoons)
                }
                .pickerStyle(.segmented)
                .onChange(of: waterUnits) {
                    showKeyboardBinding.wrappedValue = false
                }
            }
        } label: {
            Image(systemName: ("waterbottle"))
                .font(.headline)
        }
        
        Toggle(isOn: $fresh) {
            Text("Fresh?")
        }
        .onChange(of: fresh) {
            showKeyboardBinding.wrappedValue = false
        }
    }
}

extension Brand {
    static var allCases: [Brand] {
        RoyalCaninFlavor.allCases.map { .royalCanin($0) }
    }
}
