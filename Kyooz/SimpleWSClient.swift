//
//  SimpleWSClient.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/2/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

class SimpleWSClient {
    
    static let instance:SimpleWSClient = SimpleWSClient()
    
    private let urlSession = URLSession.shared
    
    private let httpPOSTMethod = "POST"
    private let timeoutInSeconds = 15.0
    
    
    func executeHTTPSPOSTCall(baseURL:String, params:[String], successHandler:([String:String]) -> Void, failureHandler: () -> ()) {
        let urlAsString = baseURL
       
        
        let url = URL(string: urlAsString)
        var urlRequest = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: timeoutInSeconds)
        urlRequest.httpMethod = httpPOSTMethod
        
        let postParamString = params.joined(separator: "&")
        
        let body = postParamString.data(using: String.Encoding.utf8, allowLossyConversion: false)
        urlRequest.httpBody = body
//        Logger.debug("URL: \(urlRequest.URL?.absoluteString)")
        let queue = OperationQueue()
        queue.qualityOfService = QualityOfService.background
        urlSession.dataTask(with: urlRequest) { (returnData:Data?, response:URLResponse?, error:Error?) -> Void in
            if let data = returnData , data.count > 0 && error == nil {
                //                let html = NSString(data: data, encoding: NSUTF8StringEncoding)
                let parser = XMLParser(data: data)
                let parserDelegate = SimpleXMLParserDelegate()
                parser.delegate = parserDelegate
                parser.parse()
//                Logger.debug("html response = \(html)")
//                Logger.debug("xmlInfo dictionary = \(parserDelegate.xmlInfo.description)")
                
                successHandler(parserDelegate.xmlInfo)
                
            } else if let data = returnData , data.count == 0 && error == nil {
                Logger.debug("nothing was downloaded")
            } else if error != nil {
                Logger.debug("Error occurred: \(error)")
                failureHandler()
            }
            
        }.resume()
    }
   
}

 //MARK: NSXMLParserDelegate properties and methods
final class SimpleXMLParserDelegate : NSObject, XMLParserDelegate {
    
    var xmlInfo:[String:String] = [String:String]()
    var elements:[String] = [String]()
    
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
        qualifiedName qName: String?, attributes attributeDict: [String : String]) {
            xmlInfo[elementName] = ""
            elements.append(elementName)
            
            if attributeDict.count > 0 {
                for (cObj, sObj) in attributeDict {
                    let key = cObj
                    let value = sObj

                    xmlInfo["\(elementName).\(key)"] = value

                }
            }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if let elementName = elements.last {
            xmlInfo[elementName]?.append(string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elements.count > 0 {
            elements.removeLast()
        }
    }
    
}
