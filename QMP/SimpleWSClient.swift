//
//  SimpleWSClient.swift
//  QMP
//
//  Created by FAHAD RIAZ on 5/2/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

class SimpleWSClient {
    
    static let instance:SimpleWSClient = SimpleWSClient()
    
    private let httpPOSTMethod = "POST"
    private let timeoutInSeconds = 15.0
    
    func executeHTTPSPOSTCall(#baseURL:String, params:[String:String], orderedParamKeys:[String],
        successHandler:([String:NSMutableString]) -> Void, failureHandler: () -> ()) {
        var urlAsString = baseURL
       
        
        let url = NSURL(string: urlAsString)
        let urlRequest = NSMutableURLRequest(URL: url!, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: timeoutInSeconds)
        urlRequest.HTTPMethod = httpPOSTMethod
        
        var postParamString = ""
        for paramKey in orderedParamKeys {
            postParamString += "&\(paramKey)=\(params[paramKey]!)"
        }
        Logger.debug("URL BODY: \(postParamString)")
        let body = postParamString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        urlRequest.HTTPBody = body
        let queue = NSOperationQueue()
        queue.qualityOfService = NSQualityOfService.Background
        
        NSURLConnection.sendAsynchronousRequest(urlRequest, queue: queue) { (response:NSURLResponse!, data:NSData!, error:NSError!) -> Void in
            if data != nil && data.length > 0 && error == nil {
                let html = NSString(data: data, encoding: NSUTF8StringEncoding)
                var parser = NSXMLParser(data: data)
                var parserDelegate = SimpleXMLParserDelegate()
                parser.delegate = parserDelegate
                parser.parse()
                Logger.debug("html response = \(html)")
                Logger.debug("xmlInfo dictionary = \(parserDelegate.xmlInfo.description)")
                
                successHandler(parserDelegate.xmlInfo)
                
            } else if data != nil && data.length == 0 && error == nil {
                Logger.debug("nothing was downloaded")
            } else if error != nil {
                Logger.debug("Error occurred: \(error)")
                failureHandler()
            }
        }
        
    }

   
}

 //MARK: NSXMLParserDelegate properties and methods
class SimpleXMLParserDelegate : NSObject, NSXMLParserDelegate {
    
    var xmlInfo:[String:NSMutableString] = [String:NSMutableString]()
    var elements:[String] = [String]()
    
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?,
        qualifiedName qName: String?, attributes attributeDict: [NSObject : AnyObject]) {
            xmlInfo[elementName] = NSMutableString()
            elements.append(elementName)
            
            if attributeDict.count > 0 {
                for (cObj, sObj) in attributeDict {
                    let key = cObj as? String
                    let value = sObj as? NSMutableString
                    if(key != nil && value != nil) {
                        xmlInfo["\(elementName).\(key!)"] = value!
                    }
                }
            }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
        if let elementName = elements.last {
            xmlInfo[elementName]?.appendString(string!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elements.count > 0 {
            elements.removeLast()
        }
    }
    
}