//
//  LasFmScrobbler.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/30/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

final class LastFmScrobbler {
    
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
    let httpFailure = "httpFailure"
    
    let USER_DEFAULTS_SESSION_KEY = "SESSION_KEY"
    let USER_DEFAULTS_USERNAME_KEY = "USERNAME_KEY"
    
    //MARK: Session and API Properties
    
    let api_key_value = "ed98119153a2fe3b04e57c3b3112f090"
    let api_secret = "a0444ceba4d9f49eedc519699cec2624"
    
    var username_value:String!
    var session:String!

    var shouldCache = false
    let cacheMax = 5
    let BATCH_SIZE = 50
    var scrobbleCache = [[String:String]]()

    private (set) var validSessionObtained:Bool = false {
        didSet {
            ApplicationDefaults.evaluateMinimumFetchInterval()
        }
    }
    
    var mediaItemToScrobble:AudioTrack!
    
    //MARK: FUNCTIONS
    
    init() {
        if let scrobbles = TempDataDAO.instance.getLastFmScrobbleCacheFromFile() {
            Logger.debug("restoring scrobble cache")
            self.scrobbleCache = scrobbles
        }
    }
    
    func initializeScrobbler() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) { [unowned self] in
            if(self.validSessionObtained) { return }
            
            if let session = NSUserDefaults.standardUserDefaults().stringForKey(self.USER_DEFAULTS_SESSION_KEY),
                let username_value = NSUserDefaults.standardUserDefaults().stringForKey(self.USER_DEFAULTS_USERNAME_KEY) {
                    self.session = session
                    self.username_value = username_value.lowercaseString

            } else {
                return
            }
            
            let params:[String:String] = [
                self.api_key:self.api_key_value,
                self.sk : self.session,
                self.method: self.method_getSessionInfo,
                self.username: self.username_value
            ]
            self.buildApiSigAndCallWS(params, successHandler: { [unowned self](info:[String:String]) in
                    Logger.debug("logging into lastfm was a SUCCESS")
                    self.validSessionObtained = true
            },  failureHandler: { [unowned self](info:[String:String]) -> () in
                    Logger.debug("could not validate existing session because of error: \(info[self.error_key]), will attempt to get a new one")
            })
        }
    }
    
    func initializeSession(usernameForSession usernameForSession:String, password:String, completionHandler:(String, logInSuccessful:Bool) -> Void) {
        Logger.debug("attempting to log in as \(usernameForSession)")
        let params:[String:String] = [
            api_key:api_key_value,
            authToken: "\(usernameForSession)\(password.md5)".md5,
            method: method_getUserSession,
            username: usernameForSession
        ]
        
        
        buildApiSigAndCallWS(params, successHandler: { [unowned self](info:[String:String]) in
            if let key = info["key"], let name = info["name"] {
                Logger.debug("successfully retrieved session for user \(name)")
                NSUserDefaults.standardUserDefaults().setObject(key, forKey: self.USER_DEFAULTS_SESSION_KEY)
                NSUserDefaults.standardUserDefaults().setObject(name, forKey: self.USER_DEFAULTS_USERNAME_KEY)
                self.session = key as String
                self.username_value = name as String
                self.validSessionObtained = true
                completionHandler("Logged in as \(self.username_value)", logInSuccessful:true)
            }
        },  failureHandler: { [unowned self](info:[String:String]) -> () in
                Logger.debug("failed to retrieve session because of error: \(info[self.error_key])")
            completionHandler("Failed to log in: \(info[self.error_key])", logInSuccessful:false)
        })

    }
    
    func removeSession() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(USER_DEFAULTS_SESSION_KEY)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(USER_DEFAULTS_USERNAME_KEY)
        username_value = nil
        validSessionObtained = false
    }
    
    func scrobbleMediaItem() {
        if(mediaItemToScrobble == nil) { return }
        
        let mediaItem = mediaItemToScrobble
        mediaItemToScrobble = nil
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) { [unowned self]() -> Void in
            let timeStampToScrobble = NSDate().timeIntervalSince1970
            
            var params:[String:String] = [
                self.track:mediaItem.trackTitle,
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
            
            self.buildApiSigAndCallWS(params, successHandler: { (info:[String:String]) in
                Logger.debug("scrobble was successful for mediaItem: \(mediaItem.trackTitle)")
            },  failureHandler: { [unowned self](info:[String:String]) -> () in
                Logger.debug("scrobble failed for mediaItem: \(mediaItem.trackTitle) with error: \(info[self.error_key])")
                if(info[self.error_key] != nil && info[self.error_key]! == self.httpFailure) {
                    self.addToScrobbleCache(mediaItem, timeStampToScrobble: timeStampToScrobble)
                }
            })
        }
    }
    
    func submitCachedScrobbles() {
        if(scrobbleCache.isEmpty) { return }
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), { [scrobbleCache = self.scrobbleCache]() -> Void in
            Logger.debug("submitting the scrobble cache")
            let maxValue = scrobbleCache.count
            for var i=0 ; i < maxValue ;  {
                let nextIncrement = i + self.BATCH_SIZE
                let nextIndexToUse = nextIncrement >= maxValue ? maxValue : nextIncrement
                self.submitBatchOfScrobbles(scrobbleCache[i..<(nextIndexToUse)])
                i = nextIndexToUse
            }
        })
    }
    
    private func submitBatchOfScrobbles(scrobbleBatch:ArraySlice<([String:String])>) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), { [unowned self]() -> Void in
            Logger.debug("submitting the scrobble batch of size \(scrobbleBatch.count)")
            var params = [String:String]()
            for scrobbleDict in scrobbleBatch {
                for(key, value) in scrobbleDict {
                    params[key] = value
                }
            }
            params[self.method] = self.method_scrobble
            params[self.api_key] = self.api_key_value
            params[self.sk] = self.session
            
            self.buildApiSigAndCallWS(params, successHandler: { [unowned self](info:[String : String]) -> Void in
                Logger.debug("scrobble was successful for \(scrobbleBatch.count) mediaItems")
                self.scrobbleCache.removeAll(keepCapacity: true)
                }, failureHandler: { [unowned self](info:[String : String]) -> () in
                    Logger.debug("failed to scrobble \(scrobbleBatch.count) mediaItems because of the following error: \(info[self.error_key])")
                    if(info[self.error_key] != nil && info[self.error_key]! != self.httpFailure) {
                        self.scrobbleCache.removeAll()
                    }
                })
            })
    }
    
    func addToScrobbleCache(mediaItemToScrobble: AudioTrack, timeStampToScrobble:NSTimeInterval) {
        Logger.debug("caching the scrobble for track: \(mediaItemToScrobble.trackTitle) - \(mediaItemToScrobble.artist)")
        let i = scrobbleCache.count
        var scrobbleDict = [String:String]()
        scrobbleDict[self.track + "[\(i)]" ] = mediaItemToScrobble.trackTitle
        scrobbleDict[self.artist + "[\(i)]" ] = mediaItemToScrobble.albumArtist //this is different (using albumArtist) from the single api call above intentionally
        scrobbleDict[self.album + "[\(i)]" ] = mediaItemToScrobble.albumTitle
        scrobbleDict[self.duration + "[\(i)]" ] = "\(Int(mediaItemToScrobble.playbackDuration))"
        scrobbleDict[self.timestamp + "[\(i)]" ] = "\(Int(timeStampToScrobble))"
        scrobbleCache.append(scrobbleDict)
    }
    
    private func buildApiSigAndCallWS(params:[String:String], successHandler lastFmSuccessHandler:([String:String]) -> Void, failureHandler lastFmFailureHandler: ([String:String]) -> ()) {

        
        let orderedParamKeys = getOrderedParamKeys(params)
        let apiSig = buildApiSig(params, orderedParamKeys: orderedParamKeys)
        
        var newParams = [String]()
        
        for paramKey in orderedParamKeys{
            newParams.append("\(paramKey)=\(params[paramKey]!.urlEncodedString)")
        }
        
        newParams.append("\(api_sig)=\(apiSig)")
        
        SimpleWSClient.instance.executeHTTPSPOSTCall(baseURL: API_URL, params: newParams,
            successHandler: { [unowned self](info:[String:String]) in
                if(info[self.status_key]! == self.status_ok) {
                    lastFmSuccessHandler(info)
                } else if (info[self.status_key]! == self.status_failed) {
                    lastFmFailureHandler(info)
                }
                
            },  failureHandler: { [unowned self]() -> () in
                Logger.debug("http failure occured, caching scrobble for now")
                lastFmFailureHandler([self.error_key:self.httpFailure])
        })
    }
    
    //MARK: Parameter builders

    
    private func getOrderedParamKeys(params:[String:String]) -> [String] {
        var orderedParamKeys = [String]()
        for (key, _) in params {
            orderedParamKeys.append(key)
        }
        orderedParamKeys.sortInPlace { (val1:String, val2:String) -> Bool in
            return val1.caseInsensitiveCompare(val2) == NSComparisonResult.OrderedAscending
        }
        return orderedParamKeys
    }
    
    
    private func buildApiSig(params:[String:String], orderedParamKeys:[String]) -> String {
        let apiSig = NSMutableString()
        for paramKey in orderedParamKeys {
            apiSig.appendString("\(paramKey)\(params[paramKey]!)")
        }
        apiSig.appendString(api_secret)
        return (apiSig as String).md5
    }
    
}
