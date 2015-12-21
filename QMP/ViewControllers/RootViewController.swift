//
//  RootViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/15/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class RootViewController: UIViewController, DragSource, UINavigationControllerDelegate {
    
    static let instance:RootViewController = RootViewController()
    
    static let nowPlayingViewCollapsedOffset:CGFloat = 55

    var pullableViewExpanded:Bool  {
        get {
            return nowPlayingSummaryViewController.expanded
        } set {
            nowPlayingSummaryViewController.expanded = newValue
            nowPlayingTapGestureRecognizer.enabled = !newValue
        }
    }
    
    var sourceTableView:UITableView? {
        if searchController.active {
            return searchResultsController.tableView
        }
        
        if let mediaItemViewController = libraryNavigationController.viewControllers.last as? MediaItemTableViewControllerProtocol {
            return mediaItemViewController.tableView
        }
        return nil
    }
    
    var libraryNavigationController:UINavigationController!
    var nowPlayingSummaryViewController:NowPlayingSummaryViewController!
    
    var nowPlayingTapGestureRecognizer:UITapGestureRecognizer!
    var nowPlayingPanGestureRecognizer:UIPanGestureRecognizer!
    var gestureDelegate:UIGestureRecognizerDelegate?
    private var collapsedConstraint:NSLayoutConstraint!
    private var expandedConstraint:NSLayoutConstraint!
    
    var previousSearchText:String?
    private var searchController:UISearchController!
    private var resultsTableController:UITableViewController!
    private let searchResultsController = MediaLibrarySearchTableViewController.instance
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        libraryNavigationController = UIStoryboard.libraryNavigationController()
        libraryNavigationController.viewControllers.first?.title = "Browse All Music"
        
        view.addSubview(libraryNavigationController.view)
        addChildViewController(libraryNavigationController)
        libraryNavigationController.didMoveToParentViewController(self)
        libraryNavigationController.delegate = self
        
        let libraryView = libraryNavigationController.view
        libraryView.translatesAutoresizingMaskIntoConstraints = false
        libraryView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        libraryView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -55).active = true
        libraryView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        libraryView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
        
        nowPlayingSummaryViewController = UIStoryboard.nowPlayingSummaryViewController()
        
        let nowPlayingView = nowPlayingSummaryViewController.view
        view.insertSubview(nowPlayingView, atIndex: 0)
        view.bringSubviewToFront(nowPlayingView)
        addChildViewController(nowPlayingSummaryViewController)
        nowPlayingSummaryViewController.didMoveToParentViewController(self)
        nowPlayingView.translatesAutoresizingMaskIntoConstraints = false
        collapsedConstraint = nowPlayingView.topAnchor.constraintEqualToAnchor(libraryView.bottomAnchor)
        collapsedConstraint.active = true
        expandedConstraint = nowPlayingView.topAnchor.constraintEqualToAnchor(view.topAnchor)
        
        nowPlayingView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        nowPlayingView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
        nowPlayingView.heightAnchor.constraintEqualToAnchor(view.heightAnchor).active = true

        nowPlayingPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
        nowPlayingPanGestureRecognizer.delegate = gestureDelegate
        nowPlayingSummaryViewController.view.addGestureRecognizer(self.nowPlayingPanGestureRecognizer)
        
        nowPlayingTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTapGesture:")
        nowPlayingTapGestureRecognizer.delegate = gestureDelegate
        nowPlayingSummaryViewController.view.addGestureRecognizer(self.nowPlayingTapGestureRecognizer)
        
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = searchResultsController
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.sizeToFit()
        searchController.searchBar.searchBarStyle = UISearchBarStyle.Default
        
        searchController.searchBar.delegate = searchResultsController
        searchController.searchBar.barStyle = UIBarStyle.Black
        searchController.searchBar.translucent = false
        searchResultsController.searchController = searchController
        libraryNavigationController.definesPresentationContext = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: UIApplication.sharedApplication())

    }
    
    
    override func viewDidAppear(animated: Bool) {
        //explicitly setting this here
        pullableViewExpanded = false
    }
    
    //MARK: - Navigation controller delegate
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if viewController === navigationController.viewControllers[0] && previousSearchText != nil {
            searchController.searchBar.text = previousSearchText
            activateSearch()
        }
    }
    
    //MARK: - Class Methods
    func activateSearch() {
        previousSearchText = nil
        libraryNavigationController.presentViewController(searchController, animated: true, completion: nil)
    }
    
    func setToolbarHidden(hidden:Bool) {
        libraryNavigationController.setToolbarHidden(hidden, animated: true)
    }
    
    func pushViewController(vc:UIViewController) {
        searchController.active = false
        if(pullableViewExpanded) {
            animatePullablePanel(shouldExpand: false)
        }
        libraryNavigationController.pushViewController(vc, animated: true)
    }
    
    func enableGesturesInSubViews(shouldEnable shouldEnable:Bool) {
        self.libraryNavigationController.interactivePopGestureRecognizer!.enabled = shouldEnable
        self.nowPlayingPanGestureRecognizer.enabled = shouldEnable
        self.nowPlayingTapGestureRecognizer.enabled = shouldEnable
    }
    
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let isDraggingUpward = (recognizer.velocityInView(view).y < 0)
        let currenyYPos = recognizer.view!.frame.origin.y
        
        let activeConstraint = expandedConstraint.active ? expandedConstraint : collapsedConstraint
        
        switch(recognizer.state) {
        case .Changed:
            let translationY = recognizer.translationInView(self.view).y
            let endYPos = currenyYPos + translationY
            
            if(endYPos >= view.frame.minY && endYPos <= libraryNavigationController.view.frame.maxY) {
                activeConstraint.constant += translationY

                recognizer.setTranslation(CGPointZero, inView: view)
            }
        case .Ended, .Cancelled:
            if(nowPlayingSummaryViewController != nil) {
                if(isDraggingUpward) {
                    animatePullablePanel(shouldExpand: (currenyYPos < self.view.frame.height * 0.80))
                } else {
                    animatePullablePanel(shouldExpand: (currenyYPos < self.view.frame.height * 0.10))
                }
            }
        default:
            break
        }
        
    }
    
    func getItemsToDrag(indexPath:NSIndexPath) -> [AudioTrack]? {
        if searchController.active {
            return searchResultsController.getMediaItemsForIndexPath(indexPath)
        }
        
        if let mediaItemViewController = libraryNavigationController.viewControllers.last as? MediaItemTableViewControllerProtocol {
            return mediaItemViewController.getMediaItemsForIndexPath(indexPath)
        }
        Logger.debug("Couldnt get a view controller with media items, returning nil")
        return nil
    }
    
    func handleTapGesture(recognizer: UITapGestureRecognizer) {
        if(!pullableViewExpanded) {
            animatePullablePanel(shouldExpand: true)
        }
    }
    
    func animatePullablePanel(shouldExpand shouldExpand:Bool) {
        if shouldExpand { //need to make sure one is deactivated before activating the other
            collapsedConstraint.active = false
            expandedConstraint.active = true
        } else {
            expandedConstraint.active = false
            collapsedConstraint.active = true
        }
        
        collapsedConstraint.constant = 0
        expandedConstraint.constant = 0
        
        var completionBlock:((Bool)->Void)?
        if(shouldExpand) {
            pullableViewExpanded = true
        } else {
            completionBlock = { finished in
                self.pullableViewExpanded = false
            }
        }
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: completionBlock)
    }
    
    func applicationDidEnterBackground(notification:NSNotification) {
        previousSearchText = nil
    }


}
