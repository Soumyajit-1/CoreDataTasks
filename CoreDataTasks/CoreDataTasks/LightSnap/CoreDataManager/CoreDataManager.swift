//
//  CoreDataManager.swift
//  CoreDataTasks
//
//  Created by Soumyajit Pal on 31/07/25.
//
// Photo+CoreDataClass.swift
import Foundation
import CoreData
import UIKit

@objc(Photo)
public class Photo: NSManagedObject {
    
}

// Photo+CoreDataProperties.swift
extension Photo {
    @NSManaged public var assetIdentifier: String
    @NSManaged public var filename: String
    @NSManaged public var imageData: Data
    @NSManaged public var creationDate: Date?
    @NSManaged public var modificationDate: Date?
    @NSManaged public var location: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var width: Int32
    @NSManaged public var height: Int32
    @NSManaged public var fileSize: Int64
    @NSManaged public var cameraModel: String?
    @NSManaged public var lensModel: String?
    @NSManaged public var isoSpeed: Int32
    @NSManaged public var focalLength: Double
    @NSManaged public var aperture: Double
    @NSManaged public var shutterSpeed: Double
    @NSManaged public var flash: Bool
    @NSManaged public var compressionQuality: Double
    @NSManaged public var savedDate: Date
}

    

class CoreDataStack {
    static let shared = CoreDataStack()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel") // Replace with your .xcdatamodeld name
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
}

