//
//  AudioTrackTableViewDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class AudioTrackDSD : AudioEntityDSD {
	
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        guard let tracks = sourceData.entities as? [AudioTrack] else {
            Logger.error("entities are not tracks, cannot play them")
            return
        }
        audioQueuePlayer.playNow(withTracks: tracks, startingAtIndex: sourceData.flattenedIndex(indexPath), shouldShuffleIfOff: false)

    }
    
}
