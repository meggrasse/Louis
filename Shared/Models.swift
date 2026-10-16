//
//  Models.swift
//  louis
//
//  Created by Meg Grasse on 10/15/26.
//

import SwiftData
import Foundation

enum Brand: Hashable, Identifiable, Codable {
    
    case royalCanin(RoyalCaninFlavor)
    enum RoyalCaninFlavor: String, CaseIterable, Codable {
        case chicken
        case beef
        case fish
    }
    var id: Self { self }
    
    // MARK: - API
    
    var label: String {
        switch self {
        case .royalCanin(let flavor): "\(flavor.rawValue.capitalized)"
        }
    }
}

@Model
class Meal {
    @Attribute(.unique) var startDate: Date
    var endDate: Date?
    var startWeight: Double
    var endWeight: Double?
    var brand: Brand
    var waterVolume: Double // liters
    var fresh: Bool
    
    init(startDate: Date, endDate: Date? = nil, startWeight: Double, endWeight: Double? = nil, brand: Brand, waterVolume: Double, fresh: Bool) {
        self.startDate = startDate
        self.endDate = endDate
        self.startWeight = startWeight
        self.endWeight = endWeight
        self.brand = brand
        self.waterVolume = waterVolume
        self.fresh = fresh
    }
}

extension Meal {
    static let weightUnit = UnitMass.kilograms
    static let waterVolumeUnit = UnitVolume.liters
}
