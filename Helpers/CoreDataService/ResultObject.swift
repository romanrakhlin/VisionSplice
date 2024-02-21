//
//  ResultObject.swift
//
//
//  Created by Roman Rakhlin on 2/18/24.
//

import SwiftUI
import CoreData

@objc(ResultObject)
class ResultObject: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var video: Data
    @NSManaged var thumbnail: Data
    @NSManaged var date: Date
}
