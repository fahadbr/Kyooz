////
////  SpotifyController.swift
////  Kyooz
////
////  Created by FAHAD RIAZ on 6/6/15.
////  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
////
//
//import Foundation
//
//class SpotifyController {
//    
//    static let instance:SpotifyController = SpotifyController()
//    
//    private static let clientId = "a279c29ba77242668a65420bbb025828"
//    private static let clientSecret = "337b9a0f291b4a09a49254e49c28e21c"
//    private static let callbackURL = NSURL(string: "kyooz-spotify-callback://")
//    private static let sessionUserDefaultsKey = "SPOTIFY_SESSION_KEY"
//    private static let scopes = [SPTAuthStreamingScope, SPTAuthUserLibraryReadScope, SPTAuthUserLibraryModifyScope]
//    
//    let authenticator = SPTAuth.defaultInstance()
//    
//    var sessionIsValid:Bool {
//        if let session = self.session {
//            return session.isValid()
//        }
//        return false
//    }
//    
//    var session:SPTSession! {
//        return authenticator.session
//    }
//    
//    init() {
//        authenticator.clientID = SpotifyController.clientId
//        authenticator.redirectURL = SpotifyController.callbackURL
//        authenticator.requestedScopes = SpotifyController.scopes
//        authenticator.sessionUserDefaultsKey = SpotifyController.sessionUserDefaultsKey
//    }
//    
//    func clearSession() {
//        authenticator.session = nil
//    }
//    
//    func renewSession(#completionBlock:(session:SPTSession)->()) {
//        authenticator.renewSession(session, callback: { (error:NSError!, renewedSession:SPTSession!) -> Void in
//            if error != nil {
//                Logger.debug("error occured with renewing spotify session: \(error.localizedDescription)")
//                return
//            }
//            self.authenticator.session = renewedSession
//            Logger.debug("successfully renewed session")
//            completionBlock(session: renewedSession)
//        })
//        
//    }
//    
//    func showLogInPage() {
//        
//        if let loginURL = authenticator.loginURL {
//            UIApplication.sharedApplication().openURL(loginURL)
//        } else {
//            Logger.debug("No login URL returned from spotify authenticator")
//        }
//    }
//    
//    func handleAuthenticationCallback(application:UIApplication, openURL url:NSURL, sourceApplication:String?, annotation:AnyObject?) -> Bool {
//        if(authenticator.canHandleURL(url)) {
//            authenticator.handleAuthCallbackWithTriggeredAuthURL(url, callback: { (error:NSError!, session:SPTSession!) -> Void in
//                if let err = error {
//                    Logger.debug("Spotify Authentication Error: \(error.localizedDescription)")
//                    return
//                }
//                Logger.debug("Successfully logged into Spotify!!")
//                self.authenticator.session = session
//            })
//            return true
//        }
//        
//        return false
//    }
//    
//}