//
//  AdblockApp.swift
//  Adblock
//
//  Created by Евгений on 31.01.2026.
//

import SwiftUI

@main
struct AdblockApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                GeneralView()
            }
        }
    }
}
