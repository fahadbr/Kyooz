//
//  MediaEntityViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/19/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

class MediaEntityViewController: AbstractViewController, MediaItemTableViewControllerProtocol, UIScrollViewDelegate, UIGestureRecognizerDelegate  {


    var mediaEntityTVC:AbstractMediaEntityTableViewController!

    
    private var headerTopAnchorConstraint:NSLayoutConstraint!
    private var headerView:UIView!
    private var previousOffset:CGFloat = 0.0
    private var headerCollapsed:Bool = false
    private var headerTranslationTransform:CATransform3D!
    private var scrollView:UIScrollView!
    
    private let identityTransform:CATransform3D = {
        var identity = CATransform3DIdentity
        identity.m34 = -1.0/1000
        return identity
    }()
    
    //MARK: - MediaItemTableViewControllerProtocol methods
    var tableView:UITableView! {
        return mediaEntityTVC.tableView
    }
    
    func getMediaItemsForIndexPath(indexPath:NSIndexPath) -> [AudioTrack] {
        return mediaEntityTVC.getMediaItemsForIndexPath(indexPath)
    }
    
    
    
    //MARK: - View life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        view.backgroundColor = ThemeHelper.defaultTableCellColor
        if mediaEntityTVC == nil {
            mediaEntityTVC = MediaEntityTableViewController()
        }
        
        
        automaticallyAdjustsScrollViewInsets = false
        let mView = mediaEntityTVC.view
        view.addSubview(mView)
        addChildViewController(mediaEntityTVC)
        mediaEntityTVC.didMoveToParentViewController(self)
        mediaEntityTVC.parentMediaEntityController = self
        
        mView.translatesAutoresizingMaskIntoConstraints = false
        mView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        mView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
        mView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        
        if let headerView = mediaEntityTVC.getViewForHeader() {
            view.addSubview(headerView)
            headerView.translatesAutoresizingMaskIntoConstraints = false
            headerView.heightAnchor.constraintEqualToConstant(mediaEntityTVC.headerHeight).active = true
//            headerTopAnchorConstraint = headerView.topAnchor.constraintEqualToAnchor(view.topAnchor)
            headerTopAnchorConstraint = headerView.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor)
            headerTopAnchorConstraint.active = true
            headerView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
            headerView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
            headerView.bottomAnchor.constraintEqualToAnchor(mView.topAnchor).active = true
            
            headerView.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
            headerTranslationTransform = CATransform3DMakeTranslation(0, mediaEntityTVC.headerHeight/2, 0)
            headerView.layer.transform = headerTranslationTransform
            self.headerView = headerView
            configureOverlayScrollViewForHeader()
        } else {
            mView.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor).active = true
        }
    }
    
    private func configureOverlayScrollViewForHeader() {
        scrollView = OverlayScrollView()
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor).active = true
        scrollView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        scrollView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        scrollView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        view.addGestureRecognizer(scrollView.panGestureRecognizer)
        calculateContentSize()
    }
    
    func calculateContentSize() {
        if scrollView == nil { return }
        
        let tableView = mediaEntityTVC.tableView
        let heightForSections = tableView.estimatedSectionHeaderHeight * CGFloat(tableView.numberOfSections > 1 ? tableView.numberOfSections : 0)
        var heightForCells:CGFloat = 0
        for i in 0..<tableView.numberOfSections {
            heightForCells += (tableView.estimatedRowHeight * CGFloat(tableView.numberOfRowsInSection(i)))
        }
        let estimatedHeight = heightForSections + heightForCells
        let totalHeight = estimatedHeight + mediaEntityTVC.headerHeight

        scrollView.contentSize = CGSize(width: view.frame.width, height: totalHeight)
        
        let shouldUseOverlay = totalHeight >= view.frame.height
        scrollView.userInteractionEnabled = shouldUseOverlay
        scrollView.scrollsToTop = shouldUseOverlay
        tableView.scrollEnabled = !shouldUseOverlay
        tableView.scrollsToTop = !shouldUseOverlay
        
        Logger.debug("calculated content size: \(scrollView.contentSize)")
    }
    
    
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if headerView == nil { return }
        let currentOffset = scrollView.contentOffset.y
        
        
        if currentOffset > 0 && currentOffset < mediaEntityTVC.headerHeight {
            applyTransformToHeaderUsingOffset(currentOffset)
        } else if currentOffset <= 0 {
            if headerCollapsed {
                applyTransformToHeaderUsingOffset(0)
            }
            mediaEntityTVC.tableView.contentOffset.y = currentOffset
        } else {
            if !headerCollapsed {
                applyTransformToHeaderUsingOffset(mediaEntityTVC.headerHeight)
            }
            mediaEntityTVC.tableView.contentOffset.y = currentOffset - mediaEntityTVC.headerHeight
        }
        
    }
    
    
    private func applyTransformToHeaderUsingOffset(offset:CGFloat) {
        headerTopAnchorConstraint.constant = -offset
        let fraction = offset/mediaEntityTVC.headerHeight
        
        let angle = fraction * CGFloat(M_PI_2)
        
        let rotateTransform = CATransform3DRotate(identityTransform, angle, 1.0, 0.0, 0.0)
        headerView.layer.transform = CATransform3DConcat(rotateTransform, headerTranslationTransform)
        headerView.alpha = 1 - fraction
        
        if fraction == 1 {
            headerCollapsed = true
        } else if fraction == 0 {
            headerCollapsed = false
        }
    }
    
    
    func synchronizeOffsetWithScrollview(scrollView:UIScrollView) {
        if self.scrollView == nil { return }
        let currentOffset = scrollView.contentOffset.y
        if scrollView === mediaEntityTVC.tableView && currentOffset >= 0 {
            var expectedOffset = currentOffset
            if currentOffset > 0 {
                expectedOffset += mediaEntityTVC.headerHeight
            } else {
                expectedOffset += -headerTopAnchorConstraint.constant
            }
            let diff = fabs(expectedOffset - self.scrollView.contentOffset.y)
            if diff > 0 {
                self.scrollView.setContentOffset(CGPoint(x: 0, y: expectedOffset), animated: false)
            }
            return
        }
    }
}

final class OverlayScrollView : UIScrollView {
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, withEvent: event)
        
        if hitView == self {
            return nil
        }
        
        return hitView
        
    }
    
}