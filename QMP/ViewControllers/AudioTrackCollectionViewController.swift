//
//  AudioTrackCollectionViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/7/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

class AudioTrackCollectionViewController: UITableViewController {

    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SpotifyDAO.instance.getAllTracks()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
