//
//  AudioTrackTableViewDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class AudioTrackDSD : AudioEntityDSD {
	
    var playAllTracksOnSelection = true
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard !tableView.editing else { return }
		
        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        guard let tracks = sourceData.entities as? [AudioTrack] else {
            Logger.error("entities are not tracks, cannot play them")
            return
        }
        
        if playAllTracksOnSelection {
            audioQueuePlayer.playNow(withTracks: tracks, startingAtIndex: sourceData.flattenedIndex(indexPath), shouldShuffleIfOff: false)
        } else {
            audioQueuePlayer.playNow(withTracks: [tracks[sourceData.flattenedIndex(indexPath)]], startingAtIndex: 0, shouldShuffleIfOff: false)
        }

    }
    
}

class EditableAudioTrackDSD : AudioTrackDSD {
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle != .Delete { return }
        
        let success = executeSourceDataUpdate {
            guard let mutableSourceData = self.sourceData as? MutableAudioEntitySourceData else {
                throw KyoozError(errorDescription:"Source Data is not Mutable")
            }
            try mutableSourceData.deleteEntitiesAtIndexPaths([indexPath])
        }
        
        if success {
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        executeSourceDataUpdate {
            guard let mutableSourceData = self.sourceData as? MutableAudioEntitySourceData else {
                throw KyoozError(errorDescription:"Source Data is not Mutable")
            }
            try mutableSourceData.moveEntity(fromIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
        }
    }
    
    private func executeSourceDataUpdate(tracksUpdatingBlock:(() throws -> Void)) -> Bool {
        do {
            try tracksUpdatingBlock()
        } catch let error {
            KyoozUtils.showPopupError(withTitle: "Could not make changes to playlist: \((sourceData as? KyoozPlaylistSourceData)?.playlist.name ?? "Unknown Playlist")", withThrownError: error, presentationVC: nil)
            return false
        }
        return true
    }
    
}

final class NowPlayingQueueDSD : EditableAudioTrackDSD {
    
    init(reuseIdentifier:String, audioCellDelegate:AudioTableCellDelegate?) {
        super.init(sourceData: AudioQueuePlayerSourceData(), reuseIdentifier: reuseIdentifier, audioCellDelegate: audioCellDelegate)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard !tableView.editing else { return }
        
        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        audioQueuePlayer.playItemWithIndexInCurrentQueue(index: indexPath.row)
    }
    
    override func entityIsNowPlaying(entity: AudioEntity, libraryGrouping: LibraryGrouping, indexPath: NSIndexPath) -> Bool {
        return audioQueuePlayer.indexOfNowPlayingItem == indexPath.row
    }
}
