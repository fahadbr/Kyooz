//
//  AudioTrackTableViewDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class AudioTrackDSD : AudioEntityDSD {
	
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

final class KyoozPlaylistDSD : AudioTrackDSD {
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle != .Delete { return }
        
        let success = performPlaylistUpdate { (var tracks) throws -> [AudioTrack] in
            guard indexPath.row < tracks.count else {
                throw KyoozError(errorDescription:"Cannot delete track \(indexPath.row + 1) because there are only \(tracks.count) tracks in the playlist")
            }
            
            tracks.removeAtIndex(indexPath.row)
            return tracks
        }
        
        if success {
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        performPlaylistUpdate { (var tracks) throws -> [AudioTrack] in
            guard sourceIndexPath.row < tracks.count && destinationIndexPath.row < tracks.count else {
                throw KyoozError(errorDescription: "Source or Destination Position is not within the Playlist count")
            }
            
            let temp = tracks.removeAtIndex(sourceIndexPath.row)
            tracks.insert(temp, atIndex: destinationIndexPath.row)
            
            return tracks
        }
    }
    
    private func performPlaylistUpdate(tracksUpdatingBlock:(([AudioTrack]) throws -> [AudioTrack])) -> Bool {
        guard let playlist = (sourceData as? KyoozPlaylistSourceData)?.playlist else {
            return false
        }
        
        do {
            let updatedTracks = try tracksUpdatingBlock(playlist.tracks)
            try KyoozPlaylistManager.instance.createOrUpdatePlaylist(playlist, withTracks: updatedTracks)
        } catch let error {
            KyoozUtils.showPopupError(withTitle: "Could not make changes to playlist \(playlist.name)", withThrownError: error, presentationVC: nil)
            return false
        }
        return true
    }
    
}
