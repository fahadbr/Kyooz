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
private let password_key = "password"
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

//OLD QMP KEYs
//private let api_key_value = "ed98119153a2fe3b04e57c3b3112f090"
//private let api_secret = "a0444ceba4d9f49eedc519699cec2624"

private let api_key_value = "3e796dbbe5b7c75b7a59dba77cde203f"
private let api_secret = "aeb87f6dd24a6c8fa5024768435d235e"


final class LastFmScrobbler {
    
    static let instance:LastFmScrobbler = LastFmScrobbler().initialize()
    static let LastSessionValidationTimeKey = "LastFmLastSessionValidationTimeKey"
    
    //MARK: - Dependencies
    
    lazy var tempDataDAO:TempDataDAO = TempDataDAO.instance
    lazy var userDefaults:UserDefaults = UserDefaults.standard
	lazy var shortNotificationManager = ShortNotificationManager.instance
    lazy var simpleWsClient:SimpleWSClient = SimpleWSClient.instance
	lazy var internetConnectionAvailable: ()->Bool = { KyoozUtils.internetConnectionAvailable }
    
    //MARK: - initializers
    func initialize() -> LastFmScrobbler {
        lastSessionValidationTime = tempDataDAO.getPersistentNumber(key: LastFmScrobbler.LastSessionValidationTimeKey)?.doubleValue ?? 0
        username_value = userDefaults.string(forKey: UserDefaultKeys.LastFmUsernameKey)
        session = userDefaults.string(forKey: UserDefaultKeys.LastFmSessionKey)
        return self
    }

    //MARK: - Properties
    
    private (set) var username_value:String? {
        didSet {
			userDefaults.set(username_value, forKey: UserDefaultKeys.LastFmUsernameKey)
		}
	}
	
    private (set) var session:String? {
        didSet {
			userDefaults.set(session, forKey: UserDefaultKeys.LastFmSessionKey)
		}
	}
	
    private (set) var lastSessionValidationTime:CFAbsoluteTime = 0 {
        didSet {
            tempDataDAO.addPersistentValue(key: LastFmScrobbler.LastSessionValidationTimeKey, value: NSNumber(value: lastSessionValidationTime))
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
	
    
    func initializeScrobbler(_ completionHandler:(()->())? = nil) {
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
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async(execute: initializeScrobblerSync)
	}
	

	
    func initializeSession(usernameForSession:String, password:String, completionHandler:@escaping () -> Void) {
        Logger.debug("attempting to log in as \(usernameForSession)")
        let params:[String:String] = [
            api_key:api_key_value,
            password_key: password,
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
    
    func scrobbleMediaItem(_ callback: (()->())? = nil) {
        guard validSessionObtained, let mediaItem = mediaItemToScrobble, let session = self.session else {
            return
        }
        mediaItemToScrobble = nil
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async { [unowned self]() -> Void in
            let timeStampToScrobble = Date().timeIntervalSince1970
            
            var params = [String : String]()
            params[track] = mediaItem.trackTitle
            params[artist] = mediaItem.artist ?? "Artist Unknown"
            params[album] = mediaItem.albumTitle
            params[duration] = "\(Int(mediaItem.playbackDuration))"
            params[timestamp] = "\(Int(timeStampToScrobble))"
            params[method] = method_scrobble
            params[api_key] = api_key_value
            params[sk] = session
            
            if(mediaItem.albumArtist != mediaItem.artist) {
                params[albumArtist] = mediaItem.albumArtist
            }
            
            self.buildApiSigAndCallWS(params, successHandler: { [weak self](info:[String:String]) in
				let message = "Successfully scrobbled track \(mediaItem.trackTitle) to last.fm"
                Logger.debug("\(message) info: \(info)")
				self?.shortNotificationManager.presentShortNotification(withMessage:message)
                callback?()
            },  failureHandler: { [unowned self](info:[String:String]) -> () in
                Logger.debug("scrobble failed for mediaItem: \(mediaItem.trackTitle) with error: \(info[error_key])")
                if(info[error_key] != nil && info[error_key]! == httpFailure) {
                    self.addToScrobbleCache(mediaItem, timeStampToScrobble: timeStampToScrobble)
                }
                callback?()
            })
        }
    }
    
	func submitCachedScrobbles(_ completionHandler:(()->())? = nil)  {
        guard !scrobbleCache.isEmpty && validSessionObtained else {
            completionHandler?()
            return
        }
        
        func submitBatchOfScrobbles(_ scrobbleBatch:ArraySlice<([String:String])>, completionHandler:((Bool)->())? = nil) {
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
			
            buildApiSigAndCallWS(params, successHandler: { [weak self](info:[String : String]) -> Void in
					let message = "Successfully scrobbled \(scrobbleBatch.count) tracks to last.fm"
                    Logger.debug(message)
					self?.shortNotificationManager.presentShortNotification(withMessage:message)
                    completionHandler?(true)
                }, failureHandler: { (info:[String : String]) -> () in
                    Logger.error("failed to scrobble \(scrobbleBatch.count) mediaItems because of the following error: \(info[error_key])")
                    let removeSlice = (info[error_key] != nil && info[error_key]! != httpFailure)
                    completionHandler?(removeSlice)
                })
        }
        
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async(execute: { [scrobbleCache = self.scrobbleCache]() -> Void in
            Logger.debug("submitting the scrobble cache")
            let dispatchGroup = DispatchGroup() // use the dispatch group to know when the asynch tasks are finished
            let maxValue = scrobbleCache.count
            
            var startIndex = 0
            var splitCache = [Int:ArraySlice<[String:String]>]() //using a separate structure to be able to remove portions of the scrobble cache when each sub batch finishes
            while startIndex < maxValue {
                let endIndex = min(startIndex + self.BATCH_SIZE, maxValue)
                let slice = scrobbleCache[startIndex ..< endIndex]
                splitCache[startIndex] = slice
                
                dispatchGroup.enter()
                let key = startIndex
                submitBatchOfScrobbles(slice) { (shouldRemove:Bool) -> Void in
                    if shouldRemove {
                        splitCache.removeValue(forKey: key)
                    }
                    dispatchGroup.leave()
                }
                startIndex = endIndex
            }
            
            dispatchGroup.notify(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.background)) {
                Logger.debug("completed all async tasks for submitting scrobbles")
                self.scrobbleCache = splitCache.flatMap() { return $1 } //assign back to the main scrobbleCache if any batches failed and did not remove their portion of the caches
                completionHandler?()
                self.tempDataDAO.persistLastFmScrobbleCache()
            }
        })
    }
    

    
    func addToScrobbleCache(_ mediaItemToScrobble: AudioTrack, timeStampToScrobble:TimeInterval) {
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
        //this is different (using albumArtist) from the single api call above intentionally
        scrobbleDict[artist + i] = mediaItemToScrobble.albumArtist ?? "Artist Unknown"
        scrobbleDict[album + i] = mediaItemToScrobble.albumTitle
        scrobbleDict[duration + i] = "\(Int(mediaItemToScrobble.playbackDuration))"
        scrobbleDict[timestamp + i] = "\(Int(timeStampToScrobble))"
        scrobbleCache.append(scrobbleDict)
    }
    

    private func buildApiSigAndCallWS(_ params:[String:String],
                                      successHandler lastFmSuccessHandler:@escaping ([String:String]) -> Void,
                                      failureHandler lastFmFailureHandler: @escaping ([String:String]) -> ()) {
		guard internetConnectionAvailable() else {
			Logger.debug("no internet connection available")
			lastFmFailureHandler([error_key:httpFailure])
			return
		}
        
        let orderedParamKeys = getOrderedParamKeys(params)
        let apiSig = buildApiSig(params, orderedParamKeys: orderedParamKeys)
        
        var newParams = orderedParamKeys.map {
            "\($0)=\(params[$0]!.urlEncodedString)"
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

    
    func getOrderedParamKeys(_ params:[String:String]) -> [String] {
		return params.map({ return $0.0 }).sorted() {
            return $0.caseInsensitiveCompare($1) == ComparisonResult.orderedAscending
        }
    }
    
    
    private func buildApiSig(_ params:[String:String], orderedParamKeys:[String]) -> String {
        let apiSig = NSMutableString()
        for paramKey in orderedParamKeys {
            apiSig.append("\(paramKey)\(params[paramKey]!)")
        }
        apiSig.append(api_secret)
        return (apiSig as String).md5
    }
    
}
