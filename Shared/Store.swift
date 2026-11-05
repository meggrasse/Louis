//
//  Store.swift
//  louis
//
//  Created by Meg Grasse on 10/15/26.
//

import Foundation
import SwiftData

struct Store {
    private static let config = ModelConfiguration(groupContainer: .identifier("group.com.grasse.louis"))
    // TODO just developemnet
//    private static let config = ModelConfiguration(isStoredInMemoryOnly: true)
    static let container: ModelContainer = {
        do {
            // TODO: move elsewhere?
            ValueTransformer.setValueTransformer(VolumeUnitTransformer(), forName: .init("VolumeUnitTransformer"))
            return try ModelContainer(for: Meal.self, configurations: config)
        }
        catch {
            // TODO: You should still be able to see the record view.
            // Also there should be some error UI
            fatalError("Failed to create App Group ModelContainer: \(error)")
        }
    }()
}
