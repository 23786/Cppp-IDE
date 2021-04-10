//
//  CDTestViewController.swift
//  C+++
//
//  Created by 23786 on 2020/6/3.
//  Copyright © 2020 Zhu Yixuan. All rights reserved.
//

import Cocoa

class CDTestViewController: NSViewController {
    
    var fileURL: String = ""
    
    @IBOutlet weak var first: CDTestPointView!
    @IBOutlet weak var second: CDTestPointView!
    @IBOutlet weak var third: CDTestPointView!
    @IBOutlet weak var fourth: CDTestPointView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        for i in [first!, second!, third!, fourth!] {

            i.isEnabled = true
            i.inputTextView.font = menloFont(ofSize: 12.0)
            i.outputTextView.font = menloFont(ofSize: 12.0)
            i.actualOutputTextView.font = menloFont(ofSize: 12.0)
            i.actualOutputTextView.isEditable = false
            
        }
        
    }
    
    @IBAction func end(_ sender: Any?) {
        
        self.dismiss(self)
        
    }
    
    @IBAction func start(_ sender: Any?) {
        
        let executablePath = self.fileURL.nsString.deletingPathExtension
        
        let exsists = FileManager().fileExists(atPath: executablePath)
        
        guard exsists else {
            self.showAlert("Warning", "Please compile the file first." )
            return
        }
        
        for i in [first!, second!, third!, fourth!] {
            
            i.result = "Not tested"

            if i.isEnabled {
                
                RunShellCommand("\"\(executablePath)\"", i.input! + "\nEOF\n") { (ans) in
                    
                    let first = ans.first
                    i.actualOutput = first
                    
                    if first?.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .newlines) == i.output?.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: .newlines) {
                        i.result = "Correct"
                    } else {
                        i.result = "Incorrect"
                    }
                    
                }
                
            }
            
        }
        
    }
    
}
