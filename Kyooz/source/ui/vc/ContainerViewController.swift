//
//  ContainerViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 3/15/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class ContainerViewController : UIViewController , GestureHandlerDelegate, UIGestureRecognizerDelegate {
    
    static let instance:ContainerViewController = ContainerViewController()
    
    enum Position : Int { case left, center, right }
    
    private let sideVCOffset:CGFloat = 60
	private var invertedCenterVCOffset:CGFloat { return view.bounds.width - sideVCOffset }
	private var kvoContext:UInt8 = 123
    
    private (set) var longPressGestureRecognizer:UILongPressGestureRecognizer!
    private (set) var dragAndDropHandler:LongPressDragAndDropGestureHandler!
    
    private (set) var tapGestureRecognizer:UITapGestureRecognizer!
    private (set) var centerPanelPanGestureRecognizer:UIPanGestureRecognizer!
    
    private (set) lazy var rootViewController:RootViewController = RootViewController.instance
    
    fileprivate let playQueueNavigationController = UINavigationController()
    private let playQueueViewController = PlayQueueViewController.instance
    private let searchViewController = AudioEntitySearchViewController.instance
    fileprivate let searchNavigationController = UINavigationController()
    private let kyoozNavigationViewController = KyoozNavigationViewController()
    
    var centerPanelPosition:Position = .center {
        didSet {
            searchViewController.isExpanded = centerPanelPosition == .right
            let sidePanelVisible = centerPanelPosition != .center
            tapGestureRecognizer.isEnabled = sidePanelVisible
            rootViewController.enableGesturesInSubViews(shouldEnable: !sidePanelVisible)
            playQueueViewController.isExpanded = centerPanelPosition == .left
			showTutorials()
        }
    }
    
    private let _undoManager:UndoManager = {
        let undoManager = UndoManager()
        undoManager.levelsOfUndo = 2
        return undoManager
    }()
    
    override var undoManager:UndoManager! {
        return _undoManager
    }
    
    private var centerViewRightConstraint:NSLayoutConstraint!
    
    deinit {
        unregisterForNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerForNotifications()
        
        let rootView = rootViewController.view
        addChildViewController(rootViewController)
        rootViewController.didMove(toParentViewController: self)
        rootView?.layer.shadowOffset = CGSize(width: 0, height: 0)
        rootView?.layer.shadowRadius = 6
        rootView?.addObserver(self, forKeyPath: "center", options: NSKeyValueObservingOptions.new, context: &kvoContext)
		
		centerViewRightConstraint = view.add(subView: rootView!,
		                                     with: [.top, .bottom, .width, .right])[.right]!
		
        centerPanelPanGestureRecognizer = UIPanGestureRecognizer(target: self,
                                                                 action: #selector(self.handlePanGesture(_:)))
        centerPanelPanGestureRecognizer.delegate = self
        rootViewController.view.addGestureRecognizer(centerPanelPanGestureRecognizer)

		if let popGR = rootViewController.libraryNavigationController.interactivePopGestureRecognizer {
            centerPanelPanGestureRecognizer.require(toFail: popGR)
        }

        //keep a reference of this gesture recogizer to enable/disable it
        tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                      action: #selector(self.handleTouchGesture(_:)))
        tapGestureRecognizer.isEnabled = false
        rootViewController.view.addGestureRecognizer(tapGestureRecognizer)

        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self,
                                                                  action: #selector(self.handleLongPressGesture(_:)))
        longPressGestureRecognizer.delegate = self
        view.addGestureRecognizer(longPressGestureRecognizer)
		
		//NOW PLAYING VC
        
		
		playQueueNavigationController.setViewControllers([playQueueViewController], animated: false)
		playQueueNavigationController.navigationBar.clearBackgroundImage()
		
		let npView = playQueueView
		addChildViewController(playQueueNavigationController)
		playQueueNavigationController.didMove(toParentViewController: self)
		
		view.add(subView: npView,
		         with: [.top, .bottom, .right, .width])[.width]!.constant = -sideVCOffset
		
		view.sendSubview(toBack: npView)
		npView.layer.rasterizationScale = UIScreen.main.scale
        
        
        searchNavigationController.setViewControllers([searchViewController], animated: false)
        searchNavigationController.navigationBar.clearBackgroundImage()
        
        let searchControllerView = self.searchControllerView
        searchControllerView.layer.rasterizationScale = UIScreen.main.scale
		
		view.add(subView: searchControllerView,
		         with: [.top, .bottom, .left, .width])[.width]!.constant = -sideVCOffset
		
		addChildViewController(searchNavigationController)
        view.sendSubview(toBack: searchControllerView)
        searchNavigationController.didMove(toParentViewController: self)
        
        KyoozUtils.doInMainQueueAfterDelay(2, block: showWhatsNew)
    }
	
    func dismissTutorials(_ targetPosition:Position) {
        switch targetPosition {
        case .right:
            if !TutorialManager.instance.dismissTutorial(.gestureActivatedSearch, action: .fulfill) {
                TutorialManager.instance.dimissTutorials([.gestureToViewQueue], action: .dismissUnfulfilled)
            }
        case .left:
            if !TutorialManager.instance.dismissTutorial(.gestureToViewQueue, action: .fulfill) {
                TutorialManager.instance.dimissTutorials([.gestureActivatedSearch, .dragAndDrop], action: .dismissUnfulfilled)
            }
		case .center:
			break
        }
	}
	
	func showTutorials() {
//        if centerPanelPosition == .center && !rootViewController.pullableViewExpanded {
//            TutorialManager.instance.presentUnfulfilledTutorials([
//                .gestureActivatedSearch,
//                .gestureToViewQueue,
//                .dragAndDrop
//            ])
//
//        }
	}
    
    func showWhatsNew() {
        guard !KyoozUtils.screenshotUITesting else { return }
        
        do {
            let version = KyoozUtils.appVersion ?? "1.0"
            let whatsNewVersion = UserDefaults.standard.string(forKey: UserDefaultKeys.WhatsNewVersionShown)
            
            guard whatsNewVersion == nil || whatsNewVersion! != version else {
                return
            }
            
			let vc = try whatsNewViewController {
				KyoozUtils.doInMainQueueAfterDelay(2, block: self.showTutorials)
			}
			
            KyoozUtils.showMenuViewController(vc, presentingVC: self)
            
            UserDefaults.standard.set(version, forKey: UserDefaultKeys.WhatsNewVersionShown)
        } catch let error {
            Logger.error("Couldn't show the whats new controller: \(error.description)")
        }
    }
	
    override var canBecomeFirstResponder: Bool {
        return true
    }
	
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        KyoozUtils.doInMainQueueAfterDelay(3) {
			guard !self.childViewControllers.contains(where: { $0 is KyoozOptionsViewController }) else {
				return
			}
			self.showTutorials()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    
    func toggleSidePanel() {
        let newPosition:Position = centerPanelPosition == .center ? .left : .center
        animateCenterPanel(toPosition: newPosition)
    }
    
    override var childViewControllerForStatusBarHidden: UIViewController? {
        return rootViewController
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    func pushViewController(_ vc:UIViewController) {
        if centerPanelPosition != .center {
            animateCenterPanel(toPosition: .center)
        }
        rootViewController.pushViewController(vc)
    }
    
    func pushNewMediaEntityControllerWithProperties(_ sourceData:AudioEntitySourceData, parentGroup:LibraryGrouping, entity:AudioEntity) {
        
        if let item = entity as? MPMediaItem {
            guard IPodLibraryDAO.queryMediaItemFromId(NSNumber(value: item.persistentID)) != nil else {
                let name = parentGroup.name.capitalized.withoutLast()
                KyoozUtils.showPopupError(withTitle: "Track Not Found In Library",
                    withMessage: "Kyooz can't show details about this track's \(name) because it's not in your music library.",
                    presentationVC: self)
                return
            }
        }
		
		guard !sourceData.entities.isEmpty else {
			KyoozUtils.showPopupError(withTitle: "No music was found in the selected item",
			                          withMessage: nil,
			                          presentationVC: self)
			return
		}
        
		let vc = AudioEntityLibraryViewController()
        vc.sourceData = sourceData
        
        if parentGroup.usesArtwork {
			vc.useCollapsableHeader = true
        } else {
            vc.title = entity.titleForGrouping(parentGroup)?.uppercased()
        }
		
        pushViewController(vc)
    }
    
    func presentKyoozNavigationController() {
        let nc = kyoozNavigationViewController
        _ = ConstraintUtils.applyStandardConstraintsToView(subView: nc.view, parentView: view)
        addChildViewController(nc)
        nc.didMove(toParentViewController: self)
        longPressGestureRecognizer.isEnabled = false
    }
    
    //MARK: NOTIFICATION REGISTRATIONS
    
    private func registerForNotifications() {
        
    }
    
    private func unregisterForNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    // MARK: Gesture recognizer
    
    @objc func handleTouchGesture(_ recognizer:UITapGestureRecognizer) {
        if recognizer.state == .ended {
            toggleSidePanel()
        }
    }
    
    private func animateCenterPanel(toPosition targetPosition:Position) {
        if centerPanelPosition == .left && targetPosition == .center {
            animateCenterPanelXPosition(toPosition: targetPosition) { finished in
                self.centerPanelPosition = targetPosition
            }
        } else {
            centerPanelPosition = targetPosition
            animateCenterPanelXPosition(toPosition: targetPosition)
        }
    }
	
    
    private func animateCenterPanelXPosition(toPosition targetPosition:Position, completion: ((Bool) -> Void)! = nil) {
        switch targetPosition {
        case .center:
            centerViewRightConstraint.constant = 0
        case .left:
            centerViewRightConstraint.constant = -invertedCenterVCOffset
        case .right:
            centerViewRightConstraint.constant = invertedCenterVCOffset
        }
        
        UIView.animate(withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0,
            options: UIViewAnimationOptions(),
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: completion)
    }

    
    private func applyTranslationToViews(_ recognizer:UIPanGestureRecognizer) {
		let newConstant = centerViewRightConstraint.constant + recognizer.translation(in: view).x
		centerViewRightConstraint.constant = KyoozUtils.cap(newConstant, min: -invertedCenterVCOffset, max: invertedCenterVCOffset)
        recognizer.setTranslation(CGPoint.zero, in: view)
    }
    
    
    @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {

        switch(recognizer.state) {
        case .changed:
            applyTranslationToViews(recognizer)
        case .ended, .cancelled:
            let targetPosition:Position
            let centerPanelXPos = rootViewController.view.frame.origin.x
            
            let movingRight = recognizer.velocity(in: recognizer.view).x > 0
            
            
            if centerPanelXPos < 0 {
                let markerX = movingRight ? (invertedCenterVCOffset * -0.80) : (invertedCenterVCOffset * -0.20)
                targetPosition = centerPanelXPos < markerX ? .left : .center
            } else if centerPanelXPos > 0 {
                let markerX = movingRight ? (invertedCenterVCOffset * 0.20) : (invertedCenterVCOffset * 0.80)
                targetPosition = centerPanelXPos > markerX ? .right : .center
            } else {
                targetPosition = .center
            }
            dismissTutorials(targetPosition)
            animateCenterPanel(toPosition: targetPosition)
        default:
            break
        }
        
    }
    
    @objc func handleLongPressGesture(_ recognizer:UILongPressGestureRecognizer) {
        switch(recognizer.state) {
        case .began:
            //initialize the drag and drop handler and all the resources necessary for the drag and drop handler
            if(!playQueueViewController.laidOutSubviews) {
                DispatchQueue.main.async { self.handleLongPressGesture(recognizer) }
                return
            }
            if(dragAndDropHandler == nil) {
                let dragSource:DragSource = centerPanelPosition == .right ? searchViewController : rootViewController
                dragAndDropHandler = LongPressDragAndDropGestureHandler(dragSource: dragSource, dropDestination: playQueueViewController)
                dragAndDropHandler.delegate = self
            }
        default:
            break
        }
        dragAndDropHandler?.handleGesture(recognizer)
    }
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath != nil && keyPath! == "center" {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
			let fraction = Float(abs(centerViewRightConstraint.constant)/invertedCenterVCOffset)
			rootViewController.view.layer.shadowOpacity = fraction
            CATransaction.commit()
            
            if centerViewRightConstraint.constant > 0 {
                playQueueView.isHidden = true
                searchControllerView.isHidden = false
            } else if centerViewRightConstraint.constant < 0 {
                playQueueView.isHidden = false
                searchControllerView.isHidden = true
            }
		}
	}

    
    //MARK: INSERT MODE DELEGATION METHODS

    func gestureDidBegin(_ sender: UIGestureRecognizer) {
        if(sender == longPressGestureRecognizer) {
			_ = TutorialManager.instance.dismissTutorial(.dragAndDrop, action: .fulfill)
            playQueueViewController.insertMode = true
            animateCenterPanel(toPosition: .left)
        }
    }
    
    func gestureDidEnd(_ sender: UIGestureRecognizer) {
        _ = TutorialManager.instance.dismissTutorial(Tutorial.insertOrCancel, action: .fulfill)
        playQueueViewController.insertMode = false
        KyoozUtils.doInMainQueueAfterDelay(0.3) { [unowned self]() in
            self.animateCenterPanel(toPosition: .center)
            self.dragAndDropHandler = nil
        }
    }
    
    //MARK: - Gesture recognizer delegates
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === longPressGestureRecognizer {
            return (!rootViewController.pullableViewExpanded || centerPanelPosition == .right)
        } else if gestureRecognizer === centerPanelPanGestureRecognizer {
            let translation = centerPanelPanGestureRecognizer.translation(in: centerPanelPanGestureRecognizer.view)
            return abs(translation.x) > abs(translation.y)
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
   
}

//MARK: - convenience variables
extension ContainerViewController {
    var playQueueView : UIView {
        return playQueueNavigationController.view
    }
    
    var searchControllerView : UIView {
        return searchNavigationController.view
    }
    
    
    
}
