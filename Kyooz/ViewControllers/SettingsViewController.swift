//
//  SettingsViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/18/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit


final class SettingsViewController: UITableViewController {

    @IBOutlet var enableAppleMusicSwitch: UISwitch!
    @IBOutlet var reduceAnimationSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
		let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(self.dismiss))
		doneButton.tintColor = ThemeHelper.defaultTintColor
		navigationItem.rightBarButtonItem = doneButton
        let value = NSUserDefaults.standardUserDefaults().integerForKey(UserDefaultKeys.AudioQueuePlayer)
        enableAppleMusicSwitch.on = value == AudioQueuePlayerType.AppleDRM.rawValue
        
        reduceAnimationSwitch.on = NSUserDefaults.standardUserDefaults().boolForKey(UserDefaultKeys.ReduceAnimations)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchValueChanged(sender: UISwitch) {
        let value = enableAppleMusicSwitch.on ? AudioQueuePlayerType.AppleDRM.rawValue : AudioQueuePlayerType.Default.rawValue
        NSUserDefaults.standardUserDefaults().setInteger(value, forKey: UserDefaultKeys.AudioQueuePlayer)
		
		KyoozUtils.showPopupError(withTitle: "Requires Restart", withMessage: "Enabling/Disabling Apple Music won't take effect until Kyooz is restarted.  Please close and then reopen the app", presentationVC: self)
    }
    
    @IBAction func reduceAnimationSwitchChanged(sender:UISwitch) {
        NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: UserDefaultKeys.ReduceAnimations)
        RootViewController.instance.setNavigationDelegate()
    }
	
	func dismiss() {
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if let cell = tableView.cellForRowAtIndexPath(indexPath) where cell.tag == 1 {
            KyoozUtils.confirmAction("Are you sure you want to reset all tutorials?", presentingVC: self) {
                TutorialManager.instance.resetAllTutorials()
            }
        }
	}

}
