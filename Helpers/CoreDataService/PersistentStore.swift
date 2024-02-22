//
//  PersistentStore.swift
//  
//
//  Created by Roman Rakhlin on 2/18/24.
//

import CoreData

class PersistentStore {
    
    let container: NSPersistentContainer
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    init() {
        let resultEntity = NSEntityDescription()
        resultEntity.name = "ResultObject"
        resultEntity.managedObjectClassName = "ResultObject"
        
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.type = .string
        resultEntity.properties.append(idAttribute)
        
        let videoAttribute = NSAttributeDescription()
        videoAttribute.name = "video"
        videoAttribute.type = .binaryData
        resultEntity.properties.append(videoAttribute)
        
        let thumbnailAttribute = NSAttributeDescription()
        thumbnailAttribute.name = "thumbnail"
        thumbnailAttribute.type = .binaryData
        resultEntity.properties.append(thumbnailAttribute)
        
        let dateAttribute = NSAttributeDescription()
        dateAttribute.name = "date"
        dateAttribute.type = .date
        resultEntity.properties.append(dateAttribute)
        
        let model = NSManagedObjectModel()
        model.entities = [resultEntity]
        
        let container = NSPersistentContainer(name: "VideoResultModel", managedObjectModel: model)
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("failed with: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        self.container = container
    }
    
    func saveContext() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch let error as NSError {
            NSLog("Unresolved error saving context: \(error), \(error.userInfo)")
        }
    }
}
