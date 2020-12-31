//
//  Setting+CoreDataProperties.swift
//  AwattarApp
//
//  Created by Léon Becker on 11.09.20.
//
//

import Foundation
import CoreData

extension Setting {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Setting> {
        return NSFetchRequest<Setting>(entityName: "Setting")
    }
    
    /// The splash screen must only be shown once. This persistent stored value ensures that this is the case.
    @NSManaged public var splashScreensFinished: Bool
    
    /// If set to true a whats new page will be shown
    @NSManaged public var showWhatsNew: Bool
    
    /// Identifies for which region the user gets aWATTar prices
    @NSManaged public var regionIdentifier: Int16
    
    /// Boolean which sets if prices throughout the app will be calculated with or without VAT/tax included
    @NSManaged public var pricesWithVAT: Bool
    
    /// Index representing an energy tariff/profile
    @NSManaged public var awattarTariffIndex: Int16
    /// The base energy price which must be individually set by the user
    @NSManaged public var awattarBaseElectricityPrice: Double
    
    /// The last power usage which was typed in on the cheapest time page
    @NSManaged public var cheapestTimeLastPower: Double
    /// The last total consumption which was typed in on the cheapest time page
    @NSManaged public var cheapestTimeLastConsumption: Double
}
