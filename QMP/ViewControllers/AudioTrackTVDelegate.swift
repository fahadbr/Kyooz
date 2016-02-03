//
//  AudioTrackTableViewDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class AudioTrackTVDelegate : ParentAudioEntityTVDelegate {
	
    private var audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
	
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        guard let tracks = sourceData.entities as? [AudioTrack] else {
            Logger.error("entities are not tracks, cannot play them")
            return
        }
        audioQueuePlayer.playNow(withTracks: tracks, startingAtIndex: indexPath.row, shouldShuffleIfOff: false)

    }
    
}
