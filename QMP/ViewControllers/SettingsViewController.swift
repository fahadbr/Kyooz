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
    
    override func viewDidLoad() {
        super.viewDidLoad()
		let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(self.dismiss))
		doneButton.tintColor = ThemeHelper.defaultTintColor
		navigationItem.rightBarButtonItem = doneButton
        let value = NSUserDefaults.standardUserDefaults().integerForKey(UserDefaultKeys.AudioQueuePlayer)
        enableAppleMusicSwitch.on = value == AudioQueuePlayerType.AppleDRM.rawValue
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchValueChanged(sender: UISwitch) {
        let value = enableAppleMusicSwitch.on ? AudioQueuePlayerType.AppleDRM.rawValue : AudioQueuePlayerType.Default.rawValue
        NSUserDefaults.standardUserDefaults().setInteger(value, forKey: UserDefaultKeys.AudioQueuePlayer)
        
        let ac = UIAlertController(title: "Requires Restart", message: "Enabling/Disabling Apple Music won't take effect until Kyooz is restarted.  Please close and then reopen the app", preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: nil))
        presentViewController(ac, animated: true, completion: nil)
    }
	
	func dismiss() {
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
//		super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
	}

}
