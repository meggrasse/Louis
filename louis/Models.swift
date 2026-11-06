//
//  Models.swift
//  louis
//
//  Created by Meg Grasse on 10/15/26.
//

import SwiftData
import Foundation

// TODO: explore modeling `endTime`/`endWeight` as a single struct so they can't get out of sync wrt nullability.
// TODO: Does SwiftData automatically add an identifier/UUID to each record?
// TODO: Add unit tests

// TODO: convert to String so data can be more easily handled in Python.
enum Brand: Hashable, Identifiable, Codable {
    
    case royalCanin(RoyalCaninFlavor)
    enum RoyalCaninFlavor: String, CaseIterable, Codable {
        case chicken
        case beef
        case fish
    }
    
    // MARK: Identifiable
    
    var id: Self { self }
    
    // MARK: API
    
    var label: String {
        switch self {
        case .royalCanin(let flavor): "\(flavor.rawValue.capitalized)"
        }
    }
}

// `endDate` and `endWeight` are optional so in-progress meals
// can be persisted.
@Model
class Meal {
    @Attribute(.unique) var startDate: Date
    var endDate: Date?
    var startWeight: Double
    var endWeight: Double?
    // Although `Brand` only has a single case (royal canin)
    // I'm still storing the `Brand` instance rather than
    // `Flavor` to hopefully avoid db migrations later, if I
    // add other brands.
    var brand: Brand
    // TODO: Upgrade app to iOS 27.0+ (and Mac to macOS 27.0+) and
    // explore consoliding into a `Measurement`, using the new
    // `.codable` attribute (as `Measurement` conforms to `Codable`).
//    var waterMeasurement: Measurement<UnitVolume>
    var waterQuantity: Double
    // It's worth noting that `UnitVolume` is really finicky: you can't archive/unarchive instances
    // created with the symbol initializer (the data produced by the archiver doesn't contain any
    // value info, so unarchiving fails). And I believe I encountered an issue where duplicate references
    // weren't considered equal. However, I'm using it carefully to avoid redundantly Foundation types.
    // Also, the reason we're persisting units is so we can show the most user-friendly units when editing,
    // rather than an awkward conversion to a base unit.
    @Attribute(.transformable(by: VolumeUnitTransformer.self)) var waterUnits: UnitVolume
    
    var fresh: Bool
    
    init(
        startDate: Date,
        endDate: Date? = nil,
        startWeight: Double,
        endWeight: Double? = nil,
        brand: Brand,
        waterQuantity: Double,
        waterUnits: UnitVolume,
        fresh: Bool
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.startWeight = startWeight
        self.endWeight = endWeight
        self.brand = brand
        self.waterQuantity = waterQuantity
        self.waterUnits = waterUnits
        self.fresh = fresh
    }
}

extension Meal {
    static let weightUnit = UnitMass.kilograms
}
    
class VolumeUnitTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        // Per CoreData documentation (which SwiftData is based on).
        return UnitVolume.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let unitVolume = value as? UnitVolume else { return nil }
        do {
            return try NSKeyedArchiver.archivedData(
                withRootObject: unitVolume,
                requiringSecureCoding: true
            )
        } catch {
            fatalError("Failed to archive UnitVolume: \(error)")
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(
                ofClass: UnitVolume.self,
                from: data
            )
        } catch {
            fatalError("Failed to unarchive UnitVolume: \(error)")
        }
    }
}
