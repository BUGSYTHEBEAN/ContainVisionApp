//
//  DataStore.swift
//  contain
//
//  Created by Andrei Freund on 3/30/24.
//

import Foundation
import CoreData

// Encapsulate all Core Data-related functionality.
// https://developer.apple.com/documentation/coredata/setting_up_a_core_data_stack
class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "GameData")
        container.loadPersistentStores { _, error in
            if let error {
                // TODO: remove
                print("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
        return container
    }()
        
    private init() { }
}
