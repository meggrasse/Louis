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
    // For development
//    private static let config = ModelConfiguration(isStoredInMemoryOnly: true)
    static let container: ModelContainer = {
        do {
            ValueTransformer.setValueTransformer(VolumeUnitTransformer(), forName: .init("VolumeUnitTransformer"))
            return try ModelContainer(for: Meal.self, configurations: config)
        }
        catch {
            fatalError("Failed to create App Group ModelContainer: \(error)")
        }
    }()
}
