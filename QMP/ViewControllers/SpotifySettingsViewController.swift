//
//  SpotifySettingsViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/5/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

class SpotifySettingsViewController: UIViewController {
    
    
    @IBOutlet weak var sessionDetailsLabel: UILabel!
    @IBOutlet weak var logInButton: UIButton!
    
    @IBOutlet weak var logOutButton: UIButton!
    let spotifyController = SpotifyController.instance
    
    @IBAction func doLogIn(sender: UIButton) {
        spotifyController.showLogInPage()
    }
    
    @IBAction func doLogOut(sender: UIButton) {
        spotifyController.clearSession()
        reloadView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadView",
            name: UIApplicationDidBecomeActiveNotification, object: nil)
        reloadView()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        reloadView()
    }
    
    func reloadView() {
        if spotifyController.sessionIsValid {
            let session = spotifyController.session
            let username = session.canonicalUsername
            sessionDetailsLabel.text = "Logged in as \(username)"
            logInButton.hidden = true
            logOutButton.hidden = false
        } else {
            sessionDetailsLabel.text  = "Not Logged In"
            logInButton.hidden = false
            logOutButton.hidden = true
        }
    }
    
}