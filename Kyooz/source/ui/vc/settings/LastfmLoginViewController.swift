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
		errorLabel.textColor = UIColor.red
		updateViewBasedOnSession()
    }
    
    @IBAction func doLogIn(_ sender: AnyObject) {
        lastFmScrobbler.initializeSession(usernameForSession: usernameField.text!, password: passwordField.text!) { [weak self] in
            KyoozUtils.doInMainQueue() {
                if let view = self?.view {
                    UIView.transition(with: view, duration: 0.4, options: .transitionCrossDissolve, animations: { 
                        self?.updateViewBasedOnSession()
                        }, completion: nil)
                }
            }
        }
    }
    
    @IBAction func doLogOut(_ sender: AnyObject) {
        usernameField.text = ""
        passwordField.text = ""
        lastFmScrobbler.removeSession()
        UIView.transition(with: view, duration: 0.4, options: .transitionCrossDissolve, animations: { [weak self] in
            self?.updateViewBasedOnSession()
            }, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
		
		usernameField.isEnabled = internetAvailable
		passwordField.isEnabled = internetAvailable
		logoutButton.isEnabled = internetAvailable
		submitButton.isEnabled = internetAvailable
		
		if usernameField.text == nil || usernameField.text!.isEmpty{
			usernameField.text = lastFmScrobbler.username_value
		}
		let message = lastFmScrobbler.currentStateDetails
		errorLabel.text = message
		errorLabel.isHidden = message == nil
		
        loginStackView.isHidden = validSessionObtained
        loggedInAsLabel.isHidden = !validSessionObtained
        logoutButton.isHidden = !validSessionObtained
        
        if lastFmScrobbler.validSessionObtained {
            usernameField.resignFirstResponder()
            passwordField.resignFirstResponder()
            loggedInAsLabel.text = "Logged in as \(lastFmScrobbler.username_value ?? "Unknown User")".uppercased()
		}
    }
    
}
