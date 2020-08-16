//
//  CDGetInputViewController.swift
//  C+++
//
//  Created by 23786 on 2020/8/15.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//

import Cocoa

class CDGetInputViewController: NSViewController {
    
    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var inputField: NSTextField!
    var completionHandler: (String) -> Void = { _ in
        
    }
    
    @IBAction func end(_ sender: Any?) {
        
        self.completionHandler(self.inputField.stringValue)
        self.dismiss(nil)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}

func CDGetInput(title: String, placeholder: String, completionHandler: @escaping (String) -> Void) {
    
    let vc = CDGetInputViewController()
    vc.completionHandler = completionHandler
    vc.loadView()
    vc.label.stringValue = title
    vc.inputField.placeholderString = placeholder
    NSApplication.shared.keyWindow?.contentViewController?.presentAsSheet(vc)
    
}
