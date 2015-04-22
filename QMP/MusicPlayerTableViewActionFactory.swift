//
//  MusicPlayerTableViewActions.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 1/11/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class MusicPlayerTableViewActionFactory: NSObject {
    
    let musicPlayer = MusicPlayerContainer.queueBasedMusicPlayer
    
    class var instance : MusicPlayerTableViewActionFactory {
        struct Static {
            static let instance:MusicPlayerTableViewActionFactory = MusicPlayerTableViewActionFactory()
        }
        return Static.instance
    }
    
    func createEnqueueAction(itemsToEnqueue:[MPMediaItem], tableViewDelegate:UITableViewDelegate, tableView:UITableView, indexPath: NSIndexPath) -> UITableViewRowAction {
        return UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Enqueue",
            handler: {action, index in
                self.musicPlayer.enqueue(itemsToEnqueue)
                tableViewDelegate.tableView?(tableView, didEndEditingRowAtIndexPath: indexPath)
            })
    }
}
