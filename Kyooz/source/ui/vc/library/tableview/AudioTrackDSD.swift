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
    
    @objc func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
		guard !tableView.isEditing else { return }
		
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
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
    
    func tableView(_ tableView: UITableView, canEditRowAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAtIndexPath indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath) {
        if editingStyle != .delete { return }
        
        let success = executeSourceDataUpdate {
            guard let mutableSourceData = self.sourceData as? MutableAudioEntitySourceData else {
                throw KyoozError(errorDescription:"Source Data is not Mutable")
            }
            try mutableSourceData.deleteEntitiesAtIndexPaths([indexPath])
        }
        
        if success {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAtIndexPath sourceIndexPath: IndexPath, toIndexPath destinationIndexPath: IndexPath) {
        _ = executeSourceDataUpdate {
            guard let mutableSourceData = self.sourceData as? MutableAudioEntitySourceData else {
                throw KyoozError(errorDescription:"Source Data is not Mutable")
            }
            try mutableSourceData.moveEntity(fromIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
        }
    }
    
    private func executeSourceDataUpdate(_ tracksUpdatingBlock:(() throws -> Void)) -> Bool {
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        guard !tableView.isEditing else { return }
        
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        audioQueuePlayer.playTrack(at: (indexPath as NSIndexPath).row)
    }
    
    override func entityIsNowPlaying(_ entity: AudioEntity, libraryGrouping: LibraryGrouping, indexPath: IndexPath) -> Bool {
        return audioQueuePlayer.indexOfNowPlayingItem == (indexPath as NSIndexPath).row
    }
}
