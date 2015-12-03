//
//  RootViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/15/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class RootViewController: UIViewController, DragSource, UINavigationControllerDelegate {
    
    static let instance:RootViewController = RootViewController()
    
    static let nowPlayingViewCollapsedOffset:CGFloat = 55

    var nowPlayingViewOrigin:CGPoint!
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
        libraryNavigationController.navigationBar
        
        view.addSubview(libraryNavigationController.view)
        addChildViewController(libraryNavigationController)
        libraryNavigationController.didMoveToParentViewController(self)
        libraryNavigationController.delegate = self
        
        nowPlayingSummaryViewController = UIStoryboard.nowPlayingSummaryViewController()
        
        view.insertSubview(nowPlayingSummaryViewController.view, atIndex: 0)
        addChildViewController(nowPlayingSummaryViewController)
        nowPlayingSummaryViewController.didMoveToParentViewController(self)
        
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
    
    override func viewDidLayoutSubviews() {
        let originalFrame = view.bounds
        let newOrigin = originalFrame.origin
        let newSize = CGSize(width: CGRectGetWidth(originalFrame), height: originalFrame.height - RootViewController.nowPlayingViewCollapsedOffset)
        libraryNavigationController.view.frame = CGRect(origin: newOrigin, size: newSize)
        
        nowPlayingViewOrigin = CGPoint(x: 0, y: self.view.bounds.height - RootViewController.nowPlayingViewCollapsedOffset)
        nowPlayingSummaryViewController.view.frame = view.bounds
        
//        if(nowPlayingSummaryViewController.view.frame.origin.y != nowPlayingViewOrigin.y) {
            nowPlayingSummaryViewController.view.frame.origin.y = view.bounds.height
            view.bringSubviewToFront(nowPlayingSummaryViewController.view)
            pullableViewExpanded = false
            animatePullablePanel(shouldExpand: false)
//        }
    }
    
    
    override func viewDidAppear(animated: Bool) {
        //explicitly setting this here
        pullableViewExpanded = false
    }
    
    //MARK: - Navigation controller delegate
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if viewController is LibraryGroupingTableViewController && previousSearchText != nil {
            searchController.searchBar.text = previousSearchText
            activateSearch()
        }
    }
    
    //MARK: - Class Methods
    func activateSearch() {
        previousSearchText = nil
        libraryNavigationController.presentViewController(searchController, animated: true, completion: nil)
    }
    
    func enableGesturesInSubViews(shouldEnable shouldEnable:Bool) {
        self.libraryNavigationController.interactivePopGestureRecognizer!.enabled = shouldEnable
        self.nowPlayingPanGestureRecognizer.enabled = shouldEnable
        self.nowPlayingTapGestureRecognizer.enabled = shouldEnable
    }
    
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let isDraggingUpward = (recognizer.velocityInView(view).y < 0)
        let currenyYPos = recognizer.view!.frame.origin.y
        
        switch(recognizer.state) {
        case .Began:
            Logger.debug("NPSVC Pan Gesture Began")
        case .Changed:
            let translationY = recognizer.translationInView(self.view).y
            let endYPos = currenyYPos + translationY
            
            if(endYPos >= 0 && endYPos <= self.nowPlayingViewOrigin.y) {
                recognizer.view!.center.y = recognizer.view!.center.y + translationY
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
    
    func presentSettingsViewController() {
        if(pullableViewExpanded) {
            animatePullablePanel(shouldExpand: false)
        }
        libraryNavigationController.pushViewController(UIStoryboard.settingsViewController(), animated: true)
    }
    
    func animatePullablePanel(shouldExpand shouldExpand:Bool) {
        if(shouldExpand) {
            pullableViewExpanded = true
            
            animatePullablePanelYPosition(targetPosition: 0)
            
        } else {
            animatePullablePanelYPosition(targetPosition: nowPlayingViewOrigin.y) { finished in
                self.pullableViewExpanded = false
                
            }
        }
    }
    
    
    func animatePullablePanelYPosition(targetPosition targetPosition:CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.5,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: .CurveEaseInOut,
            animations: {self.nowPlayingSummaryViewController.view.frame.origin.y = targetPosition},
            completion: completion)
        
    }
    
    func applicationDidEnterBackground(notification:NSNotification) {
        previousSearchText = nil
    }


}
