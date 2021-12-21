//
//  AppDelegate.swift
//  Scaivision
//
//  Created by Liu on 2021/12/16.
//

import Foundation
import UIKit
import AWSCore
import AWSCognito

class AppDelegate: NSObject, UIApplicationDelegate {
    func initializeS3(){
            let poolID = "ap-northeast-1:25525d14-4071-47d0-97b8-42b915401fc0"
            let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.APNortheast1, identityPoolId:poolID)
            
            let configuration = AWSServiceConfiguration(region:.APNortheast1, credentialsProvider: credentialsProvider)
            AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        self.initializeS3()
        return true
    }
}
