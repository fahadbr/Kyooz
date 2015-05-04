//
//  LasFmScrobbler.swift
//  QMP
//
//  Created by FAHAD RIAZ on 4/30/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

class LastFmScrobbler {
    
    static let instance:LastFmScrobbler = LastFmScrobbler()
    
    //MARK: Key Constants
    let API_URL = "https://ws.audioscrobbler.com/2.0/"
    let api_key = "api_key"
    let authToken = "authToken"
    let method = "method"
    let api_sig = "api_sig"
    let username = "username"
    let sk = "sk"
    let artist = "artist"
    let albumArtist = "albumArtist"
    let track = "track"
    let album = "album"
    let duration = "duration"
    let timestamp = "timestamp"
    
    let method_getUserSession = "auth.getMobileSession"
    let method_getSessionInfo = "auth.getSessionInfo"
    let method_scrobble = "track.scrobble"
    
    let status_key = "lfm.status"
    let status_ok = "ok"
    let status_failed = "failed"
    
    let error_key = "error"
    let error_code_key = "error.code"
    
    let USER_DEFAULTS_SESSION_KEY = "SESSION_KEY"
    let USER_DEFAULTS_USERNAME_KEY = "USERNAME_KEY"
    
    //MARK: Session and API Properties
    
    let api_key_value = "ed98119153a2fe3b04e57c3b3112f090"
    let api_secret = "a0444ceba4d9f49eedc519699cec2624"
    
    var username_value = "crazyfingrs"
    var password_value = "facaliber1"
    var session:String!

    var shouldCache = true
    let cacheMax = 5
    let BATCH_SIZE = 50
    var scrobbleCache = [(MPMediaItem, NSTimeInterval)]()

    var validSessionObtained:Bool = false
    
    //MARK: FUNCTIONS
    
    func initializeScrobbler() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) { [unowned self] in
            self.session = NSUserDefaults.standardUserDefaults().stringForKey(self.USER_DEFAULTS_SESSION_KEY)
            self.username_value = NSUserDefaults.standardUserDefaults().stringForKey(self.USER_DEFAULTS_USERNAME_KEY)!.lowercaseString
            
            var params:[String:String] = [
                self.api_key:self.api_key_value,
                self.sk : self.session,
                self.method: self.method_getSessionInfo,
                self.username: self.username_value
            ]
            self.buildApiSigAndCallWS(params, successHandler: { [unowned self](info:[String:NSMutableString]) in
                    Logger.debug("logging into lastfm was a SUCCESS")
                    self.validSessionObtained = true
            },  failureHandler: { [unowned self](info:[String:NSMutableString]) -> () in
                    Logger.debug("could not validate existing session because of error: \(info[self.error_key]), will attempt to get a new one")
                    self.initializeSession()
            })
        }
    }
    
    func initializeSession() {
        var params:[String:String] = [
            api_key:api_key_value,
            authToken: "\(username_value)\(password_value.md5)".md5,
            method: method_getUserSession,
            username: username_value
        ]
        
        
        buildApiSigAndCallWS(params, successHandler: { [unowned self](info:[String:NSMutableString]) in
            if let key = info["key"], let name = info["name"] {
                Logger.debug("successfully retrieved session for user \(name)")
                NSUserDefaults.standardUserDefaults().setObject(key, forKey: self.USER_DEFAULTS_SESSION_KEY)
                NSUserDefaults.standardUserDefaults().setObject(name, forKey: self.USER_DEFAULTS_USERNAME_KEY)
                self.session = key as String
                self.username_value = name as String
                self.validSessionObtained = true
            }
        },  failureHandler: { [unowned self](info:[String:NSMutableString]) -> () in
                Logger.debug("failed to retrieve session because of error: \(info[self.error_key])")
        })

    }
    
    func scrobbleMediaItem(mediaItem:MPMediaItem) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) { [unowned self]() -> Void in
            let timeStampToScrobble = NSDate().timeIntervalSince1970
            if(self.shouldCache) {
                self.addToScrobbleCache(mediaItem, timeStampToScrobble:timeStampToScrobble)
                return
            }
            
            var params:[String:String] = [
                self.track:mediaItem.title,
                self.artist:mediaItem.artist,
                self.album:mediaItem.albumTitle,
                self.duration:"\(Int(mediaItem.playbackDuration))",
                self.timestamp:"\(Int(timeStampToScrobble))",
                self.method:self.method_scrobble,
                self.api_key:self.api_key_value,
                self.sk:self.session
            ]
            
            if(mediaItem.albumArtist != mediaItem.artist) {
                params[self.albumArtist] = mediaItem.albumArtist
            }
            
            self.buildApiSigAndCallWS(params, successHandler: { [unowned self](info:[String:NSMutableString]) in
                Logger.debug("scrobble was successful for mediaItem: \(mediaItem.title)")
            },  failureHandler: { [unowned self](info:[String:NSMutableString]) -> () in
                Logger.debug("scrobble failed for mediaItem: \(mediaItem.title) with error: \(info[self.error_key])")
            })
        }
    }
    
    func submitCachedScrobbles() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), { [unowned self]() -> Void in
            Logger.debug("submitting the scrobble cache")
            var params = [String:String]()
            let maxValue = self.scrobbleCache.count
            for var i=0 ; i < maxValue ;  {
                let nextIncrement = i + self.BATCH_SIZE
                let nextIndexToUse = nextIncrement >= maxValue ? maxValue : nextIncrement
                self.submitBatchOfScrobbles(self.scrobbleCache[i..<(nextIndexToUse)])
                i = nextIndexToUse
            }
        })
    }
    
    private func submitBatchOfScrobbles(scrobbleBatch:ArraySlice<(MPMediaItem, NSTimeInterval)>) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), { [unowned self]() -> Void in
            Logger.debug("submitting the scrobble batch of size \(scrobbleBatch.count)")
            var params = [String:String]()
            for i in 0..<scrobbleBatch.count {
                let mediaItem = scrobbleBatch[i].0
                let timestamp_value = scrobbleBatch[i].1
                params[self.track + "[\(i)]" ] = mediaItem.title
                params[self.artist + "[\(i)]" ] = mediaItem.albumArtist
                params[self.album + "[\(i)]" ] = mediaItem.albumTitle
                params[self.duration + "[\(i)]" ] = "\(Int(mediaItem.playbackDuration))"
                params[self.timestamp + "[\(i)]" ] = "\(Int(timestamp_value))"

            }
            params[self.method] = self.method_scrobble
            params[self.api_key] = self.api_key_value
            params[self.sk] = self.session
            
            self.buildApiSigAndCallWS(params, successHandler: { [unowned self](info:[String : NSMutableString]) -> Void in
                Logger.debug("scrobble was successful for \(scrobbleBatch.count) mediaItems")
                self.scrobbleCache.removeAll(keepCapacity: true)
                }, failureHandler: { [unowned self](info:[String : NSMutableString]) -> () in
                    Logger.debug("failed to scrobble \(scrobbleBatch.count) mediaItems because of the following error: \(info[self.error_key])")
                    self.scrobbleCache.removeAll(keepCapacity: true)
                })
            })
    }
    
    private func addToScrobbleCache(mediaItemToScrobble: MPMediaItem, timeStampToScrobble:NSTimeInterval) {
        Logger.debug("caching the scrobble")
        scrobbleCache.append((mediaItemToScrobble, timeStampToScrobble))
        if(scrobbleCache.count >= cacheMax) {
            submitCachedScrobbles()
        }
    }
    
    private func buildApiSigAndCallWS(params:[String:String], successHandler lastFmSuccessHandler:([String:NSMutableString]) -> Void, failureHandler lastFmFailureHandler: ([String:NSMutableString]) -> ()) {

        
        var orderedParamKeys = getOrderedParamKeys(params)
        let apiSig = buildApiSig(params, orderedParamKeys: orderedParamKeys)
        
        var newParams = [String]()
        
        for paramKey in orderedParamKeys{
            newParams.append("\(paramKey)=\(params[paramKey]!.urlEncodedString)")
        }
        
        newParams.append("\(api_sig)=\(apiSig)")
        
        SimpleWSClient.instance.executeHTTPSPOSTCall(baseURL: API_URL, params: newParams,
            successHandler: { [unowned self](info:[String:NSMutableString]) in
                if(info[self.status_key]! == self.status_ok) {
                    lastFmSuccessHandler(info)
                } else if (info[self.status_key]! == self.status_failed) {
                    lastFmFailureHandler(info)
                }
                
            },  failureHandler: { [unowned self]() -> () in
                Logger.debug("http failure occured")
        })
    }
    
    //MARK: Parameter builders

    
    private func getOrderedParamKeys(params:[String:String]) -> [String] {
        var orderedParamKeys = [String]()
        for (key, value) in params {
            orderedParamKeys.append(key)
        }
        orderedParamKeys.sort { (val1:String, val2:String) -> Bool in
            
//            var isArrayComponent = val1[val1.endIndex.predecessor()] == "]"
//            if(isArrayComponent) {
//                let parsedString1 = self.parseString(val1)
//                let parsedString2 = self.parseString(val2)
//                if(parsedString1.name == parsedString2.name) {
//                    return self.isInASCIIOrder(parsedString1.numberString, val2: parsedString2.numberString)
//                }
//            }
            
            return val1.caseInsensitiveCompare(val2) == NSComparisonResult.OrderedAscending
        }
        return orderedParamKeys
    }
    
    private func isInASCIIOrder(val1:String, val2:String) -> Bool{
        let lastChar1 = val1[val1.endIndex.predecessor()]
        let lastChar2 = val2[val2.endIndex.predecessor()]
        if(lastChar1 == lastChar2) {
            let count1 = count(val1)
            let count2 = count(val2)
            if(count1 == count2) {
                let range1 = val1.startIndex..<val1.endIndex
                let range2 = val2.startIndex..<val2.endIndex
                return isInASCIIOrder(val1[range1], val2: val2[range2])
            } else {
                return count1 < count2
            }
        } else {
            return (lastChar1 < lastChar2)
        }
    }

    
    private func parseString(string:String) -> (name:String, numberString:String) {
        var finishedName = false
        var name = ""
        var numberString = ""
        for char in string {
            if(char == "[") {
                finishedName = true
                continue
            } else if (char == "]") {
                continue
            } else if (finishedName) {
                numberString.append(char)
            } else {
                name.append(char)
            }
        }
        return (name, numberString)
    }
    
    
    private func buildApiSig(params:[String:String], orderedParamKeys:[String]) -> String {
        var apiSig = NSMutableString()
        for paramKey in orderedParamKeys {
            apiSig.appendString("\(paramKey)\(params[paramKey]!)")
        }
        apiSig.appendString(api_secret)
        return (apiSig as String).md5
    }
    
}