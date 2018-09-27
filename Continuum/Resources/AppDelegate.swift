//
//  AppDelegate.swift
//  Continuum
//
//  Created by John Tate on 9/25/18.
//  Copyright © 2018 John Tate. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PostController.shared.checkAccountStatus { (success) in
            
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (success, error) in
            if let error = error {
                print("There was an error in \(#function) ; \(error)  ; \(error.localizedDescription)")
                return
            }
            success ? print("Successfully authorized to send push notification") : print("Denied--can't send this person notificiation")
        }
        
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Recieved a notificaton")

        PostController.shared.fetchPostsFromCloudKit { (_) in
            
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler([.alert, .sound])
    }
}

