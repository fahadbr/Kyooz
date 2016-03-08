//
//  UtilHeaderViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/16/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class UtilHeaderViewController: HeaderViewController {
    
    @IBOutlet var libraryGroupingButton: UIButton!
    
    var subGroups:[LibraryGrouping]? {
        didSet {
            if let group = subGroups?.first {
                libraryGroupingButton.hidden = false
                setActiveGroup(group)
            }
        }
    }
    private let gradiantLayer:CAGradientLayer = {
        let gradiant = CAGradientLayer()
        gradiant.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradiant.endPoint = CGPoint(x: 0.5, y: 0)
        gradiant.colors = [ThemeHelper.darkAccentColor.CGColor, ThemeHelper.defaultTableCellColor.CGColor]
        return gradiant
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.layer.shadowOpacity = 0.8
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
		
//		view.backgroundColor = ThemeHelper.darkAccentColor
        view.layer.insertSublayer(gradiantLayer, atIndex: 0)
		
		libraryGroupingButton.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
        libraryGroupingButton.hidden = subGroups == nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradiantLayer.frame = view.bounds
    }
	
    override func didMoveToParentViewController(parent: UIViewController?) {
        super.didMoveToParentViewController(parent)
        guard let vc = parent as? AudioEntityHeaderViewController else { return }
        if vc.sourceData is GroupMutableAudioEntitySourceData {
            subGroups = vc.subGroups
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showSubGroupings(sender: AnyObject) {
        guard let groups = subGroups else { return }
        
        let ac = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
        for group in groups {
            ac.addAction(UIAlertAction(title: group.name, style: .Default, handler: { _ in
                self.setActiveGroup(group)
                (self.parentViewController as? AudioEntityHeaderViewController)?.groupingTypeDidChange(group)
            }))
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    private func setActiveGroup(group:LibraryGrouping) {
        libraryGroupingButton.setTitle("  \(group.name) ⇣", forState: .Normal)
//		libraryGroupingButton.setTitle(" \(group.name) ", forState: .Normal)
    }
}
