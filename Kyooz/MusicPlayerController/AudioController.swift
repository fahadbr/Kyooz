//
//  AudioController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/23/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

protocol AudioController : class {
    
    var currentPlaybackTime:Double { get set }
    var audioTrackIsLoaded:Bool { get }
    var delegate:AudioControllerDelegate! { get set }
    var canScrobble:Bool { get }
    
    func play() -> Bool
    
    func pause() -> Bool
    
    func loadItem(_ url:URL) throws

}

protocol AudioControllerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player:AudioController, successfully flag:Bool)
    
    func audioPlayerDidRequestNextItemToBuffer(_ player:AudioController) -> URL?
    
    func audioPlayerDidAdvanceToNextItem(_ player:AudioController)
    
}

//Copy and paste for AudioController protocol conformance template
//
//var currentPlaybackTime:Double = 0
//var audioTrackIsLoaded:Bool = false
//var delegate:AudioControllerDelegate?
//
//func play() -> Bool { return false }
//
//func pause() -> Bool { return false }
//
//func loadItem(url:NSURL) -> Bool { return false }
