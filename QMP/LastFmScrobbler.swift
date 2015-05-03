//
//  LasFmScrobbler.swift
//  QMP
//
//  Created by FAHAD RIAZ on 4/30/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

class LastFmScrobbler:NSObject {
    
    static let instance:LastFmScrobbler = LastFmScrobbler()
    
    let apiKey = "ed98119153a2fe3b04e57c3b3112f090"
    let secret = "a0444ceba4d9f49eedc519699cec2624"
    
    let SESSION_KEY = "SESSION_KEY"
    let USERNAME_KEY = "USERNAME_KEY"
    
    var username = "crazyfingrs"
    var password = "facaliber1"
    var session:String?

    var notLoggedIn:Bool = true
    
    func initializeLastFm() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), { () -> Void in
            LastFm.sharedInstance().apiKey = self.apiKey
            LastFm.sharedInstance().apiSecret = self.secret
            LastFm.sharedInstance().session = NSUserDefaults.standardUserDefaults().stringForKey(self.SESSION_KEY)
            LastFm.sharedInstance().username = NSUserDefaults.standardUserDefaults().stringForKey(self.USERNAME_KEY)
            
            LastFm.sharedInstance().getSessionInfoWithSuccessHandler({ (info:[NSObject : AnyObject]!) -> Void in
                println("logging into lastfm was a success")
                self.notLoggedIn = false
                }, failureHandler: { (error:NSError!) -> Void in
                    self.getSession()
            })
        })
    

    }
    
    func scrobbleMediaItem(mediaItem:MPMediaItem) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) { [unowned self]() in
            LastFm.sharedInstance().sendScrobbledTrack(mediaItem.title,
                byArtist: mediaItem.albumArtist,
                onAlbum: mediaItem.albumTitle,
                withDuration: mediaItem.playbackDuration,
                atTimestamp: NSDate().timeIntervalSince1970, successHandler: { (result:[NSObject : AnyObject]!) -> Void in
                    println("scrobble was successful for mediaItem: \(mediaItem.title)")
                }) { (error:NSError!) -> Void in
                    println("scrobble failed for mediaItem: \(mediaItem.title) with error: \(error.localizedDescription)")
            }
        }
    }
    
    func getSession() {
        LastFm.sharedInstance().getSessionForUser(username, password: password, successHandler: { (info:[NSObject : AnyObject]!) -> Void in
                NSUserDefaults.standardUserDefaults().setObject(info["key"], forKey: self.SESSION_KEY)
                NSUserDefaults.standardUserDefaults().setObject(info["name"], forKey: self.USERNAME_KEY)
                LastFm.sharedInstance().session = info["key"] as! String?
                LastFm.sharedInstance().username = info["name"] as! String?
                self.notLoggedIn = false
                println("was able to log in to lastfm with a new session")
            }) { (error:NSError!) -> Void in
                println("there was an error getting a lastfm session: " + error.localizedDescription)
            }
    }
    
}