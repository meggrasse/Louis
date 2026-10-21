//
//  Models.swift
//  louis
//
//  Created by Meg Grasse on 10/15/26.
//

import SwiftData
import Foundation

// TODO: make string for Python
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

enum BowlLocation: String, CaseIterable, Identifiable, Codable {
    case hall
    case livingRoom
    case carrier
    case furniture
    case bedroom
    
    var icon: String {
        switch self {
        case .hall: "wifi.router"
        case .livingRoom: "table.furniture"
        case .carrier: "pet.carrier"
        case .furniture: "sofa"
        case .bedroom: "bed.double"
        }
    }
    
    // MARK: Identifiable
    
    var id: Self { self }
}

enum LouisLocation: Hashable, Identifiable, Codable {
    case here(Means)
    case missing
    
    enum Means: Hashable, Identifiable, Codable {
        /// He brought himself under his own volition
        case selfInitiated
        /// Bowl was brought to him
        case provisioned(sleeping: Bool)
        /// I brought him to the bowl
        case carried(sleeping: Bool)
        
        enum Kind: String, CaseIterable, Identifiable {
            case selfInitiated, provisioned, carried
            var id: Self { self }
            
            var icon: String {
                switch self {
                case .selfInitiated: "figure.walk.motion"
                case .provisioned: "figure.stand"
                case .carried: "stroller"
                }
            }
        }
        
        var kind: Kind {
            switch self {
            case .selfInitiated: return .selfInitiated
            case .provisioned: return .provisioned
            case .carried: return .carried
            }
        }
        
        // MARK: Identifiable
        
        var id: Self { self }
    }
    
    // MARK: Identifiable
    
    var id: Self { self }
}

///// How he connects to the start of the serving.
//enum Pathway: Hashable, Identifiable, Codable {
//    /// Associated value expresses if he was sleeping
//    case serveHim(Bool)
//    /// I carry or direct him to the serving.
//    case bringHim
//    /// He's outside or elsewhere in the house.
//    case none
//    
//    // MARK: Identifiable
//    
//    var id: Self { self }
//}

@Model
class Meal {
    @Attribute(.unique) var startDate: Date
    var endDate: Date?
    var startWeight: Double
    var endWeight: Double?
    var brand: Brand
    var waterVolume: Double
    var fresh: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \Serving.meal)
    var servings: [Serving] = []
    
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

@Model
class Serving {
    var startDate: Date
    var pets: Bool
    var meal: Meal
    var bowlLocation: BowlLocation
    var louisLocation: LouisLocation
    
    init(meal: Meal, startDate: Date, pets: Bool, bowlLocation: BowlLocation, louisLocation: LouisLocation) {
        self.meal = meal
        self.startDate = startDate
        self.pets = pets
        self.bowlLocation = bowlLocation
        self.louisLocation = louisLocation
    }
    
}

extension Meal {
    static let weightUnit = UnitMass.kilograms
    static let waterVolumeUnit = UnitVolume.liters
}

// TODO:
//extension LouisLocation {
//    init(eating: Bool, transportKind: LouisLocation.Transport.Kind?, sleeping: Bool?) {
//        switch (eating, transportKind, sleeping) {
//        case (false, .none, .none):
//            self = .missing
//        case (false, _, _):
//            fatalError()
//        case (true, .none, .none):
//            fatalError()
//        case (true, .none, .some):
//            fatalError()
//        case (true, .agentic, .none):
//            self = .bowl(.agentic)
//        case (true, .agentic, .some):
//            fatalError()
//        case let (true, .carried, .some(sleeping)):
//            self = .bowl(.carried(sleeping: sleeping))
//        case let (true, .servedInPlace, .some(sleeping)):
//            self = .bowl(.none(sleeping: sleeping))
//        case (true, .some, .none):
//            fatalError()
//        }
//    }
//}
