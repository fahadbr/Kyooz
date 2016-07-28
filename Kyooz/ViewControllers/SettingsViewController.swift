//
//  SettingsViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/18/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MessageUI

final class SettingsViewController: UITableViewController {

    @IBOutlet var enableAppleMusicSwitch: UISwitch!
    @IBOutlet var reduceAnimationSwitch: UISwitch!
    
    private static let emailAddress = "kyoozapp@gmail.com"
    
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
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
			return
		}
        do {
            switch cell.tag {
            case 1:
                KyoozUtils.confirmAction("Are you sure you want to reset all tutorials?", presentingVC: navigationController ?? self) {
                    TutorialManager.instance.resetAllTutorials()
                }
            case 2:
                try showMailComposeVC()
            case 3:
                try showPrivacyPolicy()
            case 4:
                try showAcknowledgements()
            case 5:
                try showWhatsNew()
            default:
                break
            }
        } catch let error {
            KyoozUtils.showPopupError(withTitle: "Could not complete action", withThrownError: error, presentationVC: self)
        }

	}
    
    private func showMailComposeVC() throws {
        guard MFMailComposeViewController.canSendMail() else {
            throw KyoozError(errorDescription: "The current device is not set up for sending mail")
        }
        let mfvc = MFMailComposeViewController()
        mfvc.mailComposeDelegate = self
        mfvc.setToRecipients([self.dynamicType.emailAddress])
        mfvc.setSubject("Kyooz Feedback")
        
        presentViewController(mfvc, animated: true, completion: nil)
        
    }
	
	private func showPrivacyPolicy() throws {
		let textVC = try TextViewController(fileName: "PrivacyPolicy", documentType: .html)
        navigationController?.pushViewController(textVC, animated: true)
	}
    
    private func showAcknowledgements() throws {
		let textVC = try TextViewController(fileName: "Acknowledgments", documentType: .html)
        navigationController?.pushViewController(textVC, animated: true)
    }
    
    private func showWhatsNew() throws {
        let vc = try whatsNewViewController()
        KyoozUtils.showMenuViewController(vc, presentingVC: navigationController!)
    }

}

extension SettingsViewController : MFMailComposeViewControllerDelegate {
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}