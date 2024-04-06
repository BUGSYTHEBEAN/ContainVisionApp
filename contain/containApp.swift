//
//  containApp.swift
//  contain
//
//  Created by Andrei Freund on 3/25/24.
//

import SwiftUI

@main
struct containApp: App {
    @StateObject private var coreDataStack = CoreDataStack.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataStack.persistentContainer.viewContext)
        }.windowStyle(.volumetric)
        
        WindowGroup("Info", id: "info-window") {
            InfoView()
        }.defaultSize(CGSize(width: 500, height: 400))
    }
}
