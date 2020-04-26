//
//  Photo+CoreDataProperties.swift
//  photorama
//
//  Created by user163057 on 4/26/20.
//  Copyright © 2020 Joshua Vandermost. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var photoID: String?
    @NSManaged public var title: String?
    @NSManaged public var remoteURL: NSURL?
    @NSManaged public var dateTaken: Date?

}
