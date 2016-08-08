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
		let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.dismissVC))
		doneButton.tintColor = ThemeHelper.defaultTintColor
		navigationItem.rightBarButtonItem = doneButton
        let value = UserDefaults.standard.integer(forKey: UserDefaultKeys.AudioQueuePlayer)
        enableAppleMusicSwitch.isOn = value == AudioQueuePlayerType.appleDRM.rawValue
        
        reduceAnimationSwitch.isOn = UserDefaults.standard.bool(forKey: UserDefaultKeys.ReduceAnimations)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        let value = enableAppleMusicSwitch.isOn ? AudioQueuePlayerType.appleDRM.rawValue : AudioQueuePlayerType.default.rawValue
        UserDefaults.standard.set(value, forKey: UserDefaultKeys.AudioQueuePlayer)
		
		KyoozUtils.showPopupError(withTitle: "Requires Restart", withMessage: "Enabling/Disabling Apple Music won't take effect until Kyooz is restarted.  Please close and then reopen the app", presentationVC: self)
    }
    
    @IBAction func reduceAnimationSwitchChanged(_ sender:UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: UserDefaultKeys.ReduceAnimations)
        RootViewController.instance.setNavigationDelegate()
    }
	
	func dismissVC() {
		self.dismiss(animated: true, completion: nil)
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
        guard let cell = tableView.cellForRow(at: indexPath) else {
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
        
        present(mfvc, animated: true, completion: nil)
        
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
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: NSError?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
