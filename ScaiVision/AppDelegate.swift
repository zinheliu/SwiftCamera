//
//  AppDelegate.swift
//  ScaiVision
//
//  Created by Liu on 2021/12/8.
//

import UIKit
import AWSCore
import AWSCognito
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    var dicDataResponse = [String: Any]()
    
    func initializeS3(){
        let poolID = "ap-northeast-1:25525d14-4071-47d0-97b8-42b915401fc0"
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.APNortheast1, identityPoolId:poolID)
        
        let configuration = AWSServiceConfiguration(region:.APNortheast1, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.initializeS3()
        return true
    }

    // MARK: UISceneSession Lifecycle

//    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
//        // Called when a new scene session is being created.
//        // Use this method to select a configuration to create the new scene with.
//        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
//    }
//
//    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
//        // Called when the user discards a scene session.
//        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
//        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
//    }


}

