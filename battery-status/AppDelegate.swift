//
//  AppDelegate.swift
//  battery-status
//
//  Created by Rares Popa on 17/04/2020.
//  Copyright © 2020 Danutz. All rights reserved.
//

import Cocoa
import SwiftUI
import Foundation
import IOKit.ps
import RxSwift
import AppKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    
    @objc dynamic var statusBarItem: NSStatusItem!

    func setNotifications(button: NSStatusBarButton, menuItem1: NSMenuItem, menuItem2: NSMenuItem) -> Void {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        for ps in sources {
            let info = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as! [String: AnyObject]

            //info baterie si print
            if let bhealth = info[kIOPSBatteryHealthKey] as? String,
                let btimer = info[kIOPSTimeToEmptyKey] as? Int,
                let bproccur = info[kIOPSCurrentCapacityKey] as?  Int {
                    if (menuItem1.title != "Battery health is \(bhealth)") {
                        menuItem1.title = "Battery health is \(bhealth)"
                    }
                    
                    if (menuItem2.title != "\(bproccur)% (Running on battery)") {
                        menuItem2.title = "\(bproccur)% (Running on battery)"
                    }

                    if (btimer > 0) {
                        button.title = "Time left: \((btimer % 3600)/60)h \((btimer % 3600) % 60)m"
                    } else if (btimer == 0) {
                        let timeLeftTillFullyCharged = info[kIOPSTimeToFullChargeKey]
                        button.title = "Plugged In"
                        menuItem2.title = "\(bproccur)% (Time left until full: \(timeLeftTillFullyCharged!))"
                    } else {
                        button.title = "Calculating..."
                    }
                }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // initialize the statusBar and button
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        let statusBarButton = statusBarItem.button!
        
        // set button default title
        statusBarButton.title = "Loading..."

        // initialize the NSMenu for the statusBar
        let statusBarMenu = NSMenu(title: "Battery Status")
        statusBarMenu.autoenablesItems = false
        statusBarItem.menu = statusBarMenu

        // initialize the NSMenuItems
        let batteryHealthItem = NSMenuItem(title: "Loading...", action: nil, keyEquivalent: "")
        let batteryPercentageItem = NSMenuItem(title: "Loading...", action: nil, keyEquivalent: "")
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        // disable the required NSMenuItems
        batteryHealthItem.isEnabled = false
        batteryPercentageItem.isEnabled = false

        // set the NSMenuItems for the statusBar
        statusBarMenu.addItem(batteryPercentageItem)
        statusBarMenu.addItem(batteryHealthItem)
        statusBarMenu.addItem(NSMenuItem.separator())
        statusBarMenu.addItem(quitItem)
        
        // create an Observable, that will emit events every 1000ms, that runs on the main thread
        // only when we subscribe we start emitting events
        // in this case every 1000ms we check if any of the battery params have changed and set them if so
        let scheduler = SerialDispatchQueueScheduler(qos: .default)
        let _ = Observable<Int>.interval(.milliseconds(1000), scheduler: scheduler)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { value in
                self.setNotifications(
                    button: statusBarButton,
                    menuItem1: batteryHealthItem,
                    menuItem2: batteryPercentageItem)
            })
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
