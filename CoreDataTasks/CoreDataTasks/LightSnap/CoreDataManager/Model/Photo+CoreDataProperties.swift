//
//  Photo+CoreDataProperties.swift
//  CoreDataTasks
//
//  Created by Soumyajit Pal on 06/08/25.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var assetIdentifier: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var filename: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var location: String?
    @NSManaged public var savedDate: Date?

}

extension Photo : Identifiable {

}
