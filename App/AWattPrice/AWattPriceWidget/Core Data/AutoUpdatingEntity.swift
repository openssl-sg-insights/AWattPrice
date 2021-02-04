//
//  CurrentConfigurationSetting.swift
//  AWattPrice
//
//  Created by Léon Becker on 24.12.20.
//

import CoreData

/// Object which holds a certain CoreData object. Using NSFetchedResultsController the object is updated if any changes occur to it.
class AutoUpdatingEntity<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate, ObservableObject {
    var managedObjectContext: NSManagedObjectContext // managed object context is stored with this object because it is later needed to change settings
    let entityController: NSFetchedResultsController<T> // settings controller which reports changes in the persistent stored Setting object
    var entity: T?

    init(_ entityName: String, _ managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext

        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
//        if T.self == NotificationSetting.self {
//            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \NotificationSetting.getNewPricesAvailableNotification, ascending: true)]
//        } else {
        fetchRequest.sortDescriptors = []
//        }
        entityController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)

        super.init()
        entityController.delegate = self
        do {
            try entityController.performFetch()
        } catch {
            print("Error performing fetch request on Setting-Item out of Core Data.")
        }

        if T.self == Setting.self {
            entity = getCurrentSetting(
                entityName: entityName,
                managedObjectContext: self.managedObjectContext,
                fetchRequestResults: (entityController as? NSFetchedResultsController<Setting>)?.fetchedObjects ?? []
            ) as? T
        }
    }

    func controllerWillChangeContent(_: NSFetchedResultsController<NSFetchRequestResult>) {
        objectWillChange.send()
    }
}
