//
//  AppDelegate.swift
//  plistutilSwift
//
//  Created by DE4ME on 17.05.2023.
//

import Cocoa;


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        NSApplication.shared.keyWindow?.contentViewController?.representedObject = filename;
        return true;
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true;
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true;
    }

}

