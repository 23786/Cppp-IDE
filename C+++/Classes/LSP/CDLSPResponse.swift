//
//  CDLanguageServerResponse.swift
//  C+++
//
//  Created by 23786 on 2021/2/7.
//  Copyright © 2021 Zhu Yixuan. All rights reserved.
//

import Foundation

extension CDLanguageServerClient {
    
    
    func readResponse(_ data: Data) {
        
        do {
            let res = try CDLSPProcessDataFromServer(from: data)
            
            if res is CDLSPNotification {
                if res.method == "textDocument/publishDiagnostics" {
                    processDiagnostics(response: res as! CDLSPNotification)
                }
            }
            // else ...
            
        } catch {
            print(error)
        }
        
    }
    
    private func processDiagnostics(response: CDLSPNotification) {
        
        let uri = response.params["uri"]
        guard let str = uri as? String, let url = URL(string: str)?.path else {
            return
        }
        let diagnostics = response.params["diagnostics"]
        guard let array = diagnostics as? [Dictionary<String, Any>] else {
            return
        }
        
        var diagnosticsArray = [CDDiagnostic]()
        
        for item in array {
            diagnosticsArray.append( CDDiagnostic(dict: item) )
        }
        
        self.delegate?.receivedDiagnostics(for: url, diagnostics: diagnosticsArray)
        
    }
    
    
}


/// Class for processing response fom the LSP.
class CDLSPResponse: NSObject, CDLSPBase {
    
    private(set) var res: Dictionary<String, Any> = [ : ]
    private(set) var id: Int = -1
    private(set) var method: String = ""
    
    init(id: Int, method: String, res: [String : Any]) {
        self.id = id
        self.res = res
        self.method = method
    }
    
}
