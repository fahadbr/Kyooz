//
//  UtilHeaderViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/16/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

let fixedHeight:CGFloat = 40

final class UtilHeaderViewController: UIViewController, HeaderViewControllerProtocol {

    var height:CGFloat {
        return fixedHeight
    }
    
    var minimumHeight:CGFloat {
        return fixedHeight
    }
    
    @IBOutlet var shuffleButton: ShuffleButtonView!
    @IBOutlet var libraryGroupingButton: UIButton!
    @IBOutlet var selectModeButton: ListButtonView!
    
    var subGroups:[LibraryGrouping]? {
        didSet {
            if let group = subGroups?.first {
                libraryGroupingButton.hidden = false
                setActiveGroup(group)
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.layer.shadowOpacity = 0.8
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        libraryGroupingButton.hidden = subGroups == nil
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
                (self.parentViewController as? MediaEntityTableViewController)?.groupingTypeDidChange(group)
            }))
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    private func setActiveGroup(group:LibraryGrouping) {
        libraryGroupingButton.setTitle("\(group.name) ⇣", forState: .Normal)
//		libraryGroupingButton.setTitle(" \(group.name) ", forState: .Normal)
    }
}
