//
//  LastFmScrobblerTest.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/7/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import XCTest
import MediaPlayer
@testable import Kyooz

class LastFmScrobblerIT: XCTestCase {
    
    
    private let lastFmScrobbler = LastFmScrobbler.instance
    
    
    override func setUp() {
        super.setUp()

    }
    
    func ignoreScrobbleMediaItem() {

        let expector = expectation(description: "callback")
        
        func scrobble() {
            let audioTrack = AudioTrackDTO()
            //audioTrack.artist = "Unknown Artist"
            audioTrack.artist = nil
            audioTrack.albumTitle = "Kanye West Presents Good Music Cruel Summer"
            audioTrack.trackTitle = "Clique"
            audioTrack.playbackDuration = 1
            
            lastFmScrobbler.mediaItemToScrobble = audioTrack
            lastFmScrobbler.scrobbleMediaItem() {
                expector.fulfill()
            }
        }
        
        lastFmScrobbler.initializeSession(usernameForSession: "crazyfingrs",
                                          password: "facaliber1",
                                          completionHandler: scrobble)
        
        waitForExpectations(timeout: 20) {
            XCTAssertNil($0, "got error \($0)")
        }

    }


    
    
}



