//
//  AppDelegate.swift
//  C+++
//
//  Created by apple on 2020/3/23.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//

import Cocoa

// MARK: - Global Variables

var GlobalLaunchViewController: CDLaunchViewController!
var GlobalMainWindowController: CDMainWindowController!
var GlobalLSPClient: CDLanguageServerClient?

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, CDLanguageServerClientDelegate {
    
    let documentController = CDDocumentController()
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        
        
        CDSnippetController.shared.initialize()
        if !CDSettings.isInitialized {
            CDSettings.setDefault()
        }
        
        GlobalMainWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "Document Window Controller") as? CDMainWindowController
        
        // CDServer.shared.start()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        GlobalLSPClient = CDLanguageServerClient()
        GlobalLSPClient?.startServer()
        GlobalLSPClient?.delegate = self
        signal(SIGPIPE, SIG_IGN)
        
        if CDSettings.checksUpdateAfterLaunching {
            NSApplication.shared.checkUpdate(alsoShowAlertWhenUpToDate: false)
        }
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return .terminateNow
    }
    
    func receivedDiagnostics(for file: String, diagnostics: [CDDiagnostic]) {
        
        DispatchQueue.main.async {
            
            if file == GlobalMainWindowController.document?.fileURL?.path ?? "" {
                GlobalMainWindowController.displayDiagnosticsForCurrentFile(diagnostics)
            }
            
        }
    }
    
}
