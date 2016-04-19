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
    
    var loggedInFailed:Bool = false {
        didSet {
            errorLabel.hidden = !loggedInFailed
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViewBasedOnSession()
        view.backgroundColor = ThemeHelper.defaultTableCellColor
        errorLabel.hidden = true
		errorLabel.textColor = UIColor.redColor()
    }
    
    @IBAction func doLogIn(sender: AnyObject) {
        lastFmScrobbler.initializeSession(usernameForSession: usernameField.text!, password: passwordField.text!) { [weak self](response:String, logInSuccessful:Bool) in
            KyoozUtils.doInMainQueue() {
                if let view = self?.view {
                    UIView.transitionWithView(view, duration: 0.4, options: .TransitionCrossDissolve, animations: { 
                        self?.updateViewBasedOnSession()
                        }, completion: nil)
                }
                self?.loggedInFailed = !logInSuccessful
                if(!logInSuccessful) {
                    self?.errorLabel.text = response
                } else {
                    //dismiss the keyboard
                    self?.usernameField.resignFirstResponder()
                    self?.passwordField.resignFirstResponder()
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
        loginStackView.hidden = lastFmScrobbler.validSessionObtained
        loggedInAsLabel.hidden = !lastFmScrobbler.validSessionObtained
        logoutButton.hidden = !lastFmScrobbler.validSessionObtained
        
        if(lastFmScrobbler.validSessionObtained) {
            loggedInAsLabel.text = "Logged in as \(lastFmScrobbler.username_value ?? "Unknown User")".uppercaseString
        }
    }
    
}
