//
//  CoreDataService.swift
//  
//
//  Created by Roman Rakhlin on 2/18/24.
//

import Foundation
import CoreData

class CoreDataService: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    
    @Published var objects: [ResultObject] = [] {
        didSet {
            objectWillChange.send()
        }
    }
    
    private let fetchedObjects: NSFetchedResultsController<ResultObject>
    private var managedObjectContext: NSManagedObjectContext
    
    override init() {
        let persistentStore = PersistentStore()
        
        self.managedObjectContext = persistentStore.context
        
        let fetchRequest: NSFetchRequest<ResultObject> = ResultObject.fetchRequest() as! NSFetchRequest<ResultObject>
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        
        fetchedObjects = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
                
        super.init()
        
        fetchedObjects.delegate = self
        try? fetchedObjects.performFetch()
        objects = fetchedObjects.fetchedObjects ?? []
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let newObjects = controller.fetchedObjects as? [ResultObject] else { return }
        objects = newObjects
    }
}

// MARK: - Add

extension CoreDataService {
    func create(_ entity: ResultModel) {
        let newObject = ResultObject(context: managedObjectContext)
        
        guard
            let video = try? Data(contentsOf: entity.video),
            let thumbnail = try? Data(contentsOf: entity.thumbnail)
        else {
            print("Failed")
            return
        }
        
        newObject.setValue(entity.id, forKey: "id")
        newObject.setValue(video, forKey: "video")
        newObject.setValue(thumbnail, forKey: "thumbnail")
        
        saveContext()
    }
}

// MARK: - Delete

extension CoreDataService {
    func deleteObjectWith(id: String) {
        let predicate = NSPredicate(format: "id = %@", id as CVarArg)
        let currentObject = findObjectWith(predicate: predicate)
        
        switch currentObject {
        case .success(let managedObject):
            if let managedObject {
                managedObjectContext.delete(managedObject)
            }
        case .failure(_):
            print("Couldn't fetch TodoMO to save")
        }
        
        saveContext()
    }
}

// MARK: - Fetch

extension CoreDataService {
    func getObjectWith(id: String) -> ResultObject? {
        let predicate = NSPredicate(format: "id = %@", id as CVarArg)
        let currentObject = findObjectWith(predicate: predicate)
        
        switch currentObject {
        case .success(let managedObject):
            return managedObject
        case .failure(_):
            return nil
        }
    }
}

// MARK: - Helpers

extension CoreDataService {
    private func saveContext() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch let error as NSError {
                NSLog("Unresolved error saving context: \(error), \(error.userInfo)")
            }
        }
    }
    
    private func findObjectWith(predicate: NSPredicate?) -> Result<ResultObject?, Error> {
        let request = ResultObject.fetchRequest()
        request.predicate = predicate
        request.fetchLimit = 1
        
        do {
            let result = try managedObjectContext.fetch(request)
            return .success(result.first as? ResultObject)
        } catch {
            return .failure(error)
        }
    }
}
