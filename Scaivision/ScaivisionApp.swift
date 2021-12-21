//
//  ScaivisionApp.swift
//  Scaivision
//
//  Created by Liu on 2021/12/15.
//

import SwiftUI

@main
struct ScaivisionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            CameraView()
        }
    }
}
