//
//  LSPUtilities.swift
//  C+++
//
//  Created by 23786 on 2021/2/9.
//  Copyright © 2021 Zhu Yixuan. All rights reserved.
//

import Cocoa


struct CDLSPError: Error, CustomStringConvertible {
    
    var error: String
    
    init(description: String) {
        self.error = description
    }
    
    var description: String {
        return "CDLanguageServerError: \(self.error)"
    }
    
}

protocol CDLSPBase: NSObject {
    
    var method: String { get }
    
}

func CDLSPProcessDataFromServer(from data: Data) throws -> CDLSPBase {
    
    guard let str = String(data: data, encoding: .utf8) else {
        throw CDLSPError(description: "Error found when decoding data.")
    }
    
    if str.isEmpty {
        throw CDLSPError(description: "Empty String.")
    }
    
    var id: Int = -1
    var method: String = ""
    
    let components = str.components(separatedBy: "\r\n")
    for component in components {
        do {
            let dictionary = try JSONSerialization.jsonObject(with: component.data(using: .utf8)!) as? Dictionary<String, Any>
            guard let dict = dictionary else {
                continue
            }
            
            if dict.keys.contains("id") {
                id = dict["id"] as? Int ?? -1
            }
            
            if dict.keys.contains("error") {
                let error = dict["error"] as! Dictionary<String, Any>
                throw CDLSPError(description: "Error from language server: \(error["message"] ?? "<Get Error Description Failed.>")")
            }
            
            if dict.keys.contains("method") {
                method = dict["method"] as? String ?? ""
            }
            
            if dict.keys.contains("result") {
                let res = dict["result"] as! Dictionary<String, Any>
                return CDLSPResponse(id: id, method: method, res: res)
            } else if dict.keys.contains("params") {
                let params = dict["params"] as! Dictionary<String, Any>
                if id == -1 {
                    return CDLSPNotification(method: method, params: params)
                } else {
                    return CDLSPRequest(method: method, id: id, params: params)
                }
            }
            
        } catch {
            if error is CDLSPError {
                throw error
            }
            continue
        }
    }
    
    throw CDLSPError(description: "Error found when decoding data.")
    
}



struct CDSourceFileLocation {
    
    var line: Int = 0
    var character: Int = 0
    
    init(dict: [String : Any]) {
        self.line = dict["line"] as! Int
        self.character = dict["character"] as! Int
    }
    
}

struct CDSourceFileRange {
    
    var start: CDSourceFileLocation
    var end: CDSourceFileLocation
    
    init(dict: [String : Any]) {
        self.start = CDSourceFileLocation(dict: dict["start"] as! [String : Any])
        self.end = CDSourceFileLocation(dict: dict["end"] as! [String : Any])
    }
    
}

struct CDDiagnostic {
    
    enum Severity: Int {
        case error = 1
        case warning = 2
        case information = 3
        case hint = 4
    }
    
    var code: String? = ""
    var message: String? = ""
    var range: CDSourceFileRange?
    var severity: Severity? = .error
    var source: String? = ""
    
    init(dict: [String : Any]) {
        self.code = dict["code"] as? String
        self.message = dict["message"] as? String
        let raw = dict["severity"] as? Int
        if raw != nil {
            self.severity = Severity(rawValue: raw!)
        }
        self.source = dict["source"] as? String
        self.range = CDSourceFileRange(dict: dict["range"] as! [String : Any])
    }
    
}
