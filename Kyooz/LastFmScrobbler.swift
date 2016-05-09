//
//  LasFmScrobbler.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/30/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer
import SystemConfiguration

//MARK: Key Constants
private let API_URL = "https://ws.audioscrobbler.com/2.0/"
private let api_key = "api_key"
private let authToken = "authToken"
private let method = "method"
private let api_sig = "api_sig"
private let username = "username"
private let sk = "sk"
private let artist = "artist"
private let albumArtist = "albumArtist"
private let track = "track"
private let album = "album"
private let duration = "duration"
private let timestamp = "timestamp"

private let method_getUserSession = "auth.getMobileSession"
private let method_getSessionInfo = "auth.getSessionInfo"
private let method_scrobble = "track.scrobble"

private let status_key = "lfm.status"
private let status_ok = "ok"
private let status_failed = "failed"

private let error_key = "error"
private let error_code_key = "error.code"
private let httpFailure = "Unable To Reach Network"

//MARK: Session and API Properties

private let api_key_value = "ed98119153a2fe3b04e57c3b3112f090"
private let api_secret = "a0444ceba4d9f49eedc519699cec2624"

final class LastFmScrobbler {
    
    static let instance:LastFmScrobbler = LastFmScrobbler(tempDataDAO: TempDataDAO.instance, wsClient: SimpleWSClient.instance)
    static let LastSessionValidationTimeKey = "LastFmLastSessionValidationTimeKey"
    
    //MARK: - Dependencies
    
    private var tempDataDAO:TempDataDAO
    private var simpleWsClient:SimpleWSClient
    
    //MARK: - initializers
    
    init(tempDataDAO:TempDataDAO, wsClient:SimpleWSClient) {
        self.tempDataDAO = tempDataDAO
        self.simpleWsClient = wsClient
        lastSessionValidationTime = tempDataDAO.getPersistentNumber(key: LastFmScrobbler.LastSessionValidationTimeKey)?.doubleValue ?? 0
    }
    
    //MARK: - Properties
    
	private (set) var username_value = NSUserDefaults.standardUserDefaults().stringForKey(UserDefaultKeys.LastFmUsernameKey) {
		didSet {
			NSUserDefaults.standardUserDefaults().setObject(username_value, forKey: UserDefaultKeys.LastFmUsernameKey)
		}
	}
	
	private (set) var session = NSUserDefaults.standardUserDefaults().stringForKey(UserDefaultKeys.LastFmSessionKey) {
		didSet {
			NSUserDefaults.standardUserDefaults().setObject(session, forKey: UserDefaultKeys.LastFmSessionKey)
		}
	}
	
    private (set) var lastSessionValidationTime:CFAbsoluteTime {
        didSet {
            tempDataDAO.addPersistentValue(key: LastFmScrobbler.LastSessionValidationTimeKey, value: NSNumber(double: lastSessionValidationTime))
        }
    }

    private var shouldCache = false
    private let cacheMax = 5
    private let BATCH_SIZE = 50
    private (set) var scrobbleCache = TempDataDAO.instance.getLastFmScrobbleCacheFromFile() ?? [[String:String]]()

    private (set) var validSessionObtained:Bool = false {
        didSet {
            ApplicationDefaults.evaluateMinimumFetchInterval()
			if validSessionObtained {
                lastSessionValidationTime = CFAbsoluteTimeGetCurrent()
				currentStateDetails = nil
			}
        }
    }
	private (set) var currentStateDetails:String?
    
    var mediaItemToScrobble:AudioTrack!
    
    //MARK: FUNCTIONS
	
    
    func initializeScrobbler(completionHandler:(()->())? = nil) {
		func initializeScrobblerSync() {
			guard !validSessionObtained else {
                completionHandler?()
                return
            }
			
			guard let session = self.session, let username_value = self.username_value else {
                completionHandler?()
				return
			}
			
			let params:[String:String] = [
				api_key:api_key_value,
				sk : session,
				method: method_getSessionInfo,
				username: username_value
			]
			buildApiSigAndCallWS(params, successHandler: { [unowned self](info:[String:String]) in
				Logger.debug("logging into lastfm was a SUCCESS")
				self.validSessionObtained = true
                completionHandler?()
				},  failureHandler: { [unowned self](info:[String:String]) -> () in
					let error = info[error_key]
					Logger.error("could not validate existing session because of error: \(error), will attempt to get a new one")
					self.currentStateDetails = error
                    completionHandler?()
				})
		}
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), initializeScrobblerSync)
	}
	

	
    func initializeSession(usernameForSession usernameForSession:String, password:String, completionHandler:() -> Void) {
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

                self.session = key
                self.username_value = name
                self.validSessionObtained = true
                completionHandler()
            }
        },  failureHandler: { [unowned self](info:[String:String]) -> () in
                Logger.debug("failed to retrieve session because of error: \(info[error_key])")
			let error = info[error_key]
			self.currentStateDetails = "Failed to log in: \(error ?? "Unknown Error")"
			completionHandler()
        })

    }
    
    func removeSession() {
        username_value = nil
		session = nil
        validSessionObtained = false
    }
    
    func scrobbleMediaItem() {
        if(mediaItemToScrobble == nil || !validSessionObtained) { return }
		
		guard let session = self.session else {
			return
		}
        
        let mediaItem = mediaItemToScrobble
        mediaItemToScrobble = nil
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) { [unowned self]() -> Void in
            let timeStampToScrobble = NSDate().timeIntervalSince1970
            
            var params:[String:String] = [
                track:mediaItem.trackTitle,
                artist:mediaItem.artist,
                album:mediaItem.albumTitle,
                duration:"\(Int(mediaItem.playbackDuration))",
                timestamp:"\(Int(timeStampToScrobble))",
                method:method_scrobble,
                api_key:api_key_value,
                sk:session
            ]
            
            if(mediaItem.albumArtist != mediaItem.artist) {
                params[albumArtist] = mediaItem.albumArtist
            }
            
            self.buildApiSigAndCallWS(params, successHandler: { (info:[String:String]) in
                Logger.debug("scrobble was successful for mediaItem: \(mediaItem.trackTitle)")
            },  failureHandler: { [unowned self](info:[String:String]) -> () in
                Logger.debug("scrobble failed for mediaItem: \(mediaItem.trackTitle) with error: \(info[error_key])")
                if(info[error_key] != nil && info[error_key]! == httpFailure) {
                    self.addToScrobbleCache(mediaItem, timeStampToScrobble: timeStampToScrobble)
                }
            })
        }
    }
    
	func submitCachedScrobbles(completionHandler:(()->())? = nil)  {
        guard !scrobbleCache.isEmpty && validSessionObtained else {
            completionHandler?()
            return
        }
        
        func submitBatchOfScrobbles(scrobbleBatch:ArraySlice<([String:String])>, completionHandler:((shouldRemove:Bool)->())? = nil) {
            Logger.debug("submitting the scrobble batch of size \(scrobbleBatch.count)")
            var params = [String:String]()
            for scrobbleDict in scrobbleBatch {
                for(key, value) in scrobbleDict {
                    params[key] = value
                }
            }
            params[method] = method_scrobble
            params[api_key] = api_key_value
            params[sk] = session
			
            buildApiSigAndCallWS(params, successHandler: { (info:[String : String]) -> Void in
                    Logger.debug("scrobble was successful for \(scrobbleBatch.count) mediaItems")
                    completionHandler?(shouldRemove:true)
                }, failureHandler: { (info:[String : String]) -> () in
                    Logger.error("failed to scrobble \(scrobbleBatch.count) mediaItems because of the following error: \(info[error_key])")
                    let removeSlice = (info[error_key] != nil && info[error_key]! != httpFailure)
                    completionHandler?(shouldRemove:removeSlice)
                })
        }
        
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), { [scrobbleCache = self.scrobbleCache]() -> Void in
            Logger.debug("submitting the scrobble cache")
            let dispatchGroup = dispatch_group_create() // use the dispatch group to know when the asynch tasks are finished
            let maxValue = scrobbleCache.count
            
            var startIndex = 0
            var splitCache = [Int:ArraySlice<[String:String]>]() //using a separate structure to be able to remove portions of the scrobble cache when each sub batch finishes
            while startIndex < maxValue {
                let endIndex = min(startIndex + self.BATCH_SIZE, maxValue)
                let slice = scrobbleCache[startIndex ..< endIndex]
                splitCache[startIndex] = slice
                
                dispatch_group_enter(dispatchGroup)
                let key = startIndex
                submitBatchOfScrobbles(slice) { (shouldRemove:Bool) -> Void in
                    if shouldRemove {
                        splitCache.removeValueForKey(key)
                    }
                    dispatch_group_leave(dispatchGroup)
                }
                startIndex = endIndex
            }
            
            dispatch_group_notify(dispatchGroup, dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                Logger.debug("completed all async tasks for submitting scrobbles")
                self.scrobbleCache = splitCache.flatMap() { return $1 } //assign back to the main scrobbleCache if any batches failed and did not remove their portion of the caches
                completionHandler?()
                TempDataDAO.instance.persistLastFmScrobbleCache()
            }
        })
    }
    

    
    func addToScrobbleCache(mediaItemToScrobble: AudioTrack, timeStampToScrobble:NSTimeInterval) {
        //check if there is a valid session before adding to the scrobble cache
        //if the session/user name exists but hasnt been validated, check that it has been validated in the last 24 hours
        //this is to prevent the scrobble cache from building up infinitely if there happens to be a username/session but no valid session
        guard validSessionObtained
            || (username_value != nil && session != nil && (CFAbsoluteTimeGetCurrent() - lastSessionValidationTime <= KyoozConstants.ONE_DAY_IN_SECONDS)) else {
            Logger.error("attempting to scrobble without a valid session")
            return
        }
        
        Logger.debug("caching the scrobble for track: \(mediaItemToScrobble.trackTitle) - \(mediaItemToScrobble.artist)")
        let i = "[\(scrobbleCache.count)]"
        var scrobbleDict = [String:String]()
        scrobbleDict[track + i] = mediaItemToScrobble.trackTitle
        scrobbleDict[artist + i] = mediaItemToScrobble.albumArtist //this is different (using albumArtist) from the single api call above intentionally
        scrobbleDict[album + i] = mediaItemToScrobble.albumTitle
        scrobbleDict[duration + i] = "\(Int(mediaItemToScrobble.playbackDuration))"
        scrobbleDict[timestamp + i] = "\(Int(timeStampToScrobble))"
        scrobbleCache.append(scrobbleDict)
    }
    
    private func buildApiSigAndCallWS(params:[String:String], successHandler lastFmSuccessHandler:([String:String]) -> Void, failureHandler lastFmFailureHandler: ([String:String]) -> ()) {
		guard KyoozUtils.internetConnectionAvailable else {
			Logger.debug("no internet connection available")
			lastFmFailureHandler([error_key:httpFailure])
			return
		}
        
        let orderedParamKeys = getOrderedParamKeys(params)
        let apiSig = buildApiSig(params, orderedParamKeys: orderedParamKeys)
        
        var newParams = [String]()
        
        for paramKey in orderedParamKeys{
            newParams.append("\(paramKey)=\(params[paramKey]!.urlEncodedString)")
        }
        
        newParams.append("\(api_sig)=\(apiSig)")
        
        simpleWsClient.executeHTTPSPOSTCall(baseURL: API_URL, params: newParams,
            successHandler: { (info:[String:String]) in
                let status = info[status_key] ?? ""
                if(status == status_ok) {
                    lastFmSuccessHandler(info)
                } else if (status == status_failed) {
                    lastFmFailureHandler(info)
                } else {
                    lastFmFailureHandler([error_key:"unknown failure"])
                }
                
            },  failureHandler: {
                Logger.debug("http failure occured, caching scrobble for now")
                lastFmFailureHandler([error_key:httpFailure])
        })
    }
    
    //MARK: Parameter builders

    
    func getOrderedParamKeys(params:[String:String]) -> [String] {
		return params.map({ return $0.0 }).sort() {
            return $0.caseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending
        }
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