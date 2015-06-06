//
//  QueableMediaItemTableViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/9/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class MediaItemTableViewController: UITableViewController  {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    func getMediaItemsForIndexPath(indexPath:NSIndexPath) -> [AudioTrack] {
        fatalError("This method needs to be implemented by a subclass")
    }
    

    

}
