//
//  souvenirApp.swift
//  souvenir
//
//  Created by Erick Barcelos on 26/08/24.
//

import SwiftUI

@main
struct souvenirApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
