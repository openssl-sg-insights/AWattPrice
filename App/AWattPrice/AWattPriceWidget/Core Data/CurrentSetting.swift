//
//  CurrentSetting.swift
//  AWattPrice
//
//  Created by Léon Becker on 23.12.20.
//

import CoreData

/// Object which holds the current Setting object. Using NSFetchedResultsController the current setting stored in this object is updated if any changes occur to it.
class CurrentSetting: AutoUpdatingEntity<Setting> {
    @Published var currentVATToUse = GlobalAppSettings.normalVATAmount

    init(managedObjectContext: NSManagedObjectContext) {
        super.init(entityName: "Setting", managedObjectContext: managedObjectContext)
    }
}

func getCurrentSetting(entityName: String, managedObjectContext: NSManagedObjectContext, fetchRequestResults: [Setting]) -> Setting? {
    if fetchRequestResults.count == 1 {
        // Settings file was found correctly
        return fetchRequestResults[0]

    } else if fetchRequestResults.count == 0 {
        // No Settings object is yet created. Create a new Settings object with default values and save it to the persistent store
        if let entityDesciptor = NSEntityDescription.entity(forEntityName: entityName, in: managedObjectContext) {
            let newSetting = Setting(entity: entityDesciptor, insertInto: managedObjectContext)
            newSetting.showWhatsNew = false
            newSetting.splashScreensFinished = false
            newSetting.regionIdentifier = 0
            newSetting.pricesWithVAT = true
            newSetting.awattarTariffIndex = -1
            newSetting.awattarBaseElectricityPrice = 0
            newSetting.cheapestTimeLastPower = 0
            newSetting.cheapestTimeLastConsumption = 0

            do {
                try managedObjectContext.save()
            } catch {
                print("Error storing new settings object.")
                return nil
            }

            return newSetting
        } else {
            return nil
        }
    } else {
        // Shouldn't happen because would mean that there are multiple Settings objects stored in the persistent storage
        // Only one should exist
        print("Multiple Settings objects found in persistent storage. This shouldn't happen with Settings objects. Will delete all Settings objects except of the last which is kept.")

        for x in 0 ... (fetchRequestResults.count - 1) {
            // Deletes all Settings objects except of the last
            if !(x == fetchRequestResults.count - 1) {
                managedObjectContext.delete(fetchRequestResults[x])
            }
        }

        do {
            try managedObjectContext.save()
        } catch {
            print("Error storing new settings object.")
            return nil
        }

        return fetchRequestResults[fetchRequestResults.count - 1]
    }
}
