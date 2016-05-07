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
    
    private let urlSession = NSURLSession.sharedSession()
    
    private let httpPOSTMethod = "POST"
    private let timeoutInSeconds = 15.0
    
    
    func executeHTTPSPOSTCall(baseURL baseURL:String, params:[String], successHandler:([String:String]) -> Void, failureHandler: () -> ()) {
        let urlAsString = baseURL
       
        
        let url = NSURL(string: urlAsString)
        let urlRequest = NSMutableURLRequest(URL: url!, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: timeoutInSeconds)
        urlRequest.HTTPMethod = httpPOSTMethod
        
        let postParamString = params.joinWithSeparator("&")
        
        let body = postParamString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        urlRequest.HTTPBody = body
//        Logger.debug("URL: \(urlRequest.URL?.absoluteString)")
        let queue = NSOperationQueue()
        queue.qualityOfService = NSQualityOfService.Background
        urlSession.dataTaskWithRequest(urlRequest) { (returnData:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            if let data = returnData where data.length > 0 && error == nil {
                //                let html = NSString(data: data, encoding: NSUTF8StringEncoding)
                let parser = NSXMLParser(data: data)
                let parserDelegate = SimpleXMLParserDelegate()
                parser.delegate = parserDelegate
                parser.parse()
//                Logger.debug("html response = \(html)")
//                Logger.debug("xmlInfo dictionary = \(parserDelegate.xmlInfo.description)")
                
                successHandler(parserDelegate.xmlInfo)
                
            } else if let data = returnData where data.length == 0 && error == nil {
                Logger.debug("nothing was downloaded")
            } else if error != nil {
                Logger.debug("Error occurred: \(error)")
                failureHandler()
            }
            
        }.resume()
    }
   
}

 //MARK: NSXMLParserDelegate properties and methods
final class SimpleXMLParserDelegate : NSObject, NSXMLParserDelegate {
    
    var xmlInfo:[String:String] = [String:String]()
    var elements:[String] = [String]()
    
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?,
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
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        if let elementName = elements.last {
            xmlInfo[elementName]?.appendContentsOf(string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elements.count > 0 {
            elements.removeLast()
        }
    }
    
}