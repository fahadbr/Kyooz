//
//  UtilHeaderViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/16/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class UtilHeaderViewController: HeaderViewController {
    

	
	private var path:UIBezierPath!
	private var accentLayer:CAShapeLayer = CAShapeLayer()
	
    override func viewDidLoad() {
        		
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
		path = UIBezierPath()
		path.moveToPoint(CGPoint(x: view.bounds.origin.x, y: view.bounds.height))
		path.addLineToPoint(CGPoint(x: view.bounds.width, y: view.bounds.height))
		accentLayer.path = path.CGPath
    }
	
    override func didMoveToParentViewController(parent: UIViewController?) {
        super.didMoveToParentViewController(parent)
        guard let vc = parent as? AudioEntityLibraryViewController else { return }
        if vc.sourceData is GroupMutableAudioEntitySourceData {
            subGroups = vc.subGroups
        }
        setActiveGroup(vc.sourceData.libraryGrouping)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
}
