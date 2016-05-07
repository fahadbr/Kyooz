////
////  SpotifyDAO.swift
////  Kyooz
////
////  Created by FAHAD RIAZ on 6/7/15.
////  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
////
//
//import Foundation
//
//class SpotifyDAO : MusicLibraryDAO{
//    
//    static let instance = SpotifyDAO()
//    
//    let spotifyController = SpotifyController.instance
//    
//    var tracks = [AudioTrack]()
//    var artists = [String:[AudioTrack]]()
//    
//    func getAllTracks() {
//        if !tracks.isEmpty { return }
//
//        if spotifyController.sessionIsValid {
//            SPTYourMusic.savedTracksForUserWithAccessToken(spotifyController.session.accessToken, callback: handleTrackListPage)
//        } else {
//            spotifyController.renewSession(completionBlock: { (session) -> () in
//                SPTYourMusic.savedTracksForUserWithAccessToken(session.accessToken, callback: self.handleTrackListPage)
//            })
//        }
//    }
//    
//    
//    private func handleTrackListPage(error:NSError!, data:AnyObject!) {
//        if(error != nil) {
//            Logger.debug("error occured while getting spotify saved tracks: \(error.localizedDescription)")
//            return
//        }
//        
//        Logger.debug("\(data?.description)")
//        if let listPage = data as? SPTListPage,  let items = listPage.items as? [SPTPartialTrack] {
//            for track in items {
//                addTrack(track)
//            }
//            
//            let currentPosition = UInt(listPage.range.location + listPage.range.length)
//            let listLength = listPage.totalListLength
//            Logger.debug("Current location: \(listPage.range.location), range length: \(listPage.range.length), totalListLength:\(listLength)")
//            if(currentPosition < listLength) {
//                listPage.requestNextPageWithSession(spotifyController.session, callback: handleTrackListPage)
//            } else {
//                Logger.debug("GOT ALL THE SPOTIFY TRACKS")
//                for (artist, trackList) in artists {
//                    Logger.debug("artist available: \(artist)")
//                }
//            }
//            
//        }
//        Logger.debug("track count at end of callback block: \(self.tracks.count)")
//
//    }
//    
//    private func addTrack(track:SPTPartialTrack) {
//        tracks.append(track)
//        if var artistTracks = artists[track.albumArtist] {
//            artistTracks.append(track)
//        } else {
//            var artistTracks = [AudioTrack]()
//            artistTracks.append(track)
//            artists[track.albumArtist] = artistTracks
//        }
//    }
//    
//    
//}
