//
//  AppDelegate.swift
//  Muvr
//
//  Created by Jan Machacek on 3/27/15.
//  Copyright (c) 2015 Muvr. All rights reserved.
//

import UIKit

@UIApplicationMain
class MRAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var deviceToken: NSData?

    private func registerSettingsAndDelegates() {
        let settings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
        // LiftServer.sharedInstance.setDelegate(self, delegateQueue: dispatch_get_main_queue())
    }

    private func startWithStoryboardId(storyboard: UIStoryboard, id: String) {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window!.makeKeyAndVisible()
        window!.rootViewController = storyboard.instantiateViewControllerWithIdentifier(id) as? UIViewController!
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // if LiftUserDefaults.isRunningTests { return true }
        
        // notifications et al
        registerSettingsAndDelegates()
        
        // initialize the data models
        MRDataModel.create()
        
        // main initialization
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let lis = MRApplicationState.loggedInState {
            lis.checkAccount { r in
                if let x = self.deviceToken { lis.registerDeviceToken(x) }
                
                //self.startWithStoryboardId(storyboard, id: r.cata({ err in if err.code == 404 { return "login" } else { return "offline" } }, { x in return "main" }))
                
                // notice that we have no concept of "offline": if the server is unreachable, we'll
                // give the user the benefit of doubt.
                
                self.startWithStoryboardId(storyboard, id: r.cata({ err in if err.code == 404 { return "login" } else { return "main" } }, r: { x in return "main" }))
            }
        } else {
            self.startWithStoryboardId(storyboard, id: "login")
        }
                
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        self.deviceToken = deviceToken
        NSLog("Token \(deviceToken)")
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        let data: [UInt8] = [0x5A, 0xB8, 0x48, 0x05, 0xF8, 0xD0, 0xCC, 0x63, 0x0A, 0x89, 0x90, 0xA8, 0x4D, 0x48, 0x08, 0x41, 0xC3, 0x68, 0x40, 0x03, 0x6C, 0x12, 0x2C, 0x8E, 0x52, 0xA8, 0xDC, 0xFD, 0x68, 0xA6, 0xF6, 0xF8]
        let buf = UnsafePointer<[UInt8]>(data)
        let deviceToken = NSData(bytes: buf, length: data.count)
        self.deviceToken = deviceToken
        NSLog("Not registered \(error)")
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        NSLog("settings %@", notificationSettings)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        NSLog("Got remote notification %@", userInfo)
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        MRMuvrServer.sharedInstance.setBaseUrlString(MRUserDefaults.muvrServerUrl)
    }

}

