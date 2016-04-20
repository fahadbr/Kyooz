//
//  UIViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/16/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

class LastfmLoginViewController: CustomPopableViewController, UITextFieldDelegate {
   
    
    
    @IBOutlet var logoutButton: UIButton!
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var submitButton: UIButton!
    @IBOutlet var loginStackView: UIStackView!
    
    
    @IBOutlet var loggedInAsLabel: UILabel!
    @IBOutlet var errorLabel: UILabel!

    
    let lastFmScrobbler = LastFmScrobbler.instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
        view.backgroundColor = ThemeHelper.defaultTableCellColor
		errorLabel.textColor = UIColor.redColor()
		updateViewBasedOnSession()
    }
    
    @IBAction func doLogIn(sender: AnyObject) {
        lastFmScrobbler.initializeSession(usernameForSession: usernameField.text!, password: passwordField.text!) { [weak self] in
            KyoozUtils.doInMainQueue() {
                if let view = self?.view {
                    UIView.transitionWithView(view, duration: 0.4, options: .TransitionCrossDissolve, animations: { 
                        self?.updateViewBasedOnSession()
                        }, completion: nil)
                }
            }
        }
    }
    
    @IBAction func doLogOut(sender: AnyObject) {
        usernameField.text = ""
        passwordField.text = ""
        lastFmScrobbler.removeSession()
        UIView.transitionWithView(view, duration: 0.4, options: .TransitionCrossDissolve, animations: { [weak self] in
            self?.updateViewBasedOnSession()
            }, completion: nil)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if(textField == usernameField) {
            passwordField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            doLogIn(textField)
        }
        return true
    }
    
    private func updateViewBasedOnSession() {
		let internetAvailable = KyoozUtils.internetConnectionAvailable
		let validSessionObtained = lastFmScrobbler.validSessionObtained
		
		usernameField.enabled = internetAvailable
		passwordField.enabled = internetAvailable
		logoutButton.enabled = internetAvailable
		submitButton.enabled = internetAvailable
		
		if usernameField.text == nil || usernameField.text!.isEmpty{
			usernameField.text = lastFmScrobbler.username_value
		}
		let message = lastFmScrobbler.currentStateDetails
		errorLabel.text = message
		errorLabel.hidden = message == nil
		
        loginStackView.hidden = validSessionObtained
        loggedInAsLabel.hidden = !validSessionObtained
        logoutButton.hidden = !validSessionObtained
        
        if lastFmScrobbler.validSessionObtained {
            loggedInAsLabel.text = "Logged in as \(lastFmScrobbler.username_value ?? "Unknown User")".uppercaseString
		}
    }
    
}
