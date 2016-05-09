//
//  AudioEntityViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 3/3/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

class AudioEntityHeaderViewController : AudioEntityViewController, UIScrollViewDelegate {

	
	var headerHeightConstraint: NSLayoutConstraint!
	var maxHeight:CGFloat!
	var minHeight:CGFloat!
	var collapsedTargetOffset:CGFloat!
	
	var useCollapsableHeader:Bool = false
	private var headerCollapsed:Bool = false
	
    private var headerVC:HeaderViewController!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		automaticallyAdjustsScrollViewInsets = false
		view.backgroundColor = ThemeHelper.defaultTableCellColor
		
		headerVC = useCollapsableHeader ? UIStoryboard.artworkHeaderViewController() : UIStoryboard.utilHeaderViewController()
		ConstraintUtils.applyConstraintsToView(withAnchors: [.Top, .Left, .Right], subView: headerVC.view, parentView: view)
		headerHeightConstraint = headerVC.view.heightAnchor.constraintEqualToConstant(headerVC.defaultHeight)
		headerHeightConstraint.active = true
		
        addChildViewController(headerVC)
        headerVC.didMoveToParentViewController(self)
		
		minHeight = headerVC.minimumHeight
		maxHeight = headerVC.defaultHeight
		collapsedTargetOffset = maxHeight - minHeight
		tableView.contentInset.top = minHeight
        tableView.scrollIndicatorInsets.top = maxHeight
        tableView.contentOffset.y = -tableView.contentInset.top
        
        tableView.panGestureRecognizer.requireGestureRecognizerToFail(popGestureRecognizer)
        tableView.panGestureRecognizer.requireGestureRecognizerToFail(ContainerViewController.instance.centerPanelPanGestureRecognizer)

		if useCollapsableHeader {
			tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: collapsedTargetOffset))
			view.addGestureRecognizer(tableView.panGestureRecognizer)
		}
	}
	
	//MARK: - Scroll View Delegate
	final func scrollViewDidScroll(scrollView: UIScrollView) {
		if !useCollapsableHeader { return }
		let currentOffset = scrollView.contentOffset.y + scrollView.contentInset.top
		
		if  currentOffset < collapsedTargetOffset {
			headerHeightConstraint.constant = (maxHeight - currentOffset)
			scrollView.scrollIndicatorInsets.top = collapsedTargetOffset - scrollView.contentOffset.y
			headerCollapsed = false
		} else if !headerCollapsed {
			headerHeightConstraint.constant = minHeight
			scrollView.scrollIndicatorInsets.top = minHeight
			headerCollapsed = true
		}
	}
	
	
}