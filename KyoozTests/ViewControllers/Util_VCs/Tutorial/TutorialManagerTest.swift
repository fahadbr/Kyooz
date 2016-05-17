//
//  TutorialManagerTest.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/15/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import XCTest
@testable import Kyooz

class TutorialManagerTest: XCTestCase {
    
    private var mockUserDefaults:MockUserDefaults!
    private var presentationController:MockViewController!
    private var mockVCFactory:MockVCFactory!
    
    private var tutorialManager:TutorialManager!
    
    
    override func setUp() {
        super.setUp()
        tutorialManager = TutorialManager()
        
        mockUserDefaults = MockUserDefaults()
        presentationController = MockViewController()
        mockVCFactory = MockVCFactory()
        
        tutorialManager.userDefaults = mockUserDefaults
        tutorialManager.presentationController = presentationController
        tutorialManager.tutorialViewControllerFactory = mockVCFactory

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPresentTutorialIfUnfulfilledGreenPath() {
        let tutorial:Tutorial = .GestureActivatedSearch
        XCTAssertTrue(tutorialManager.presentTutorialIfUnfulfilled(tutorial))
        ensureTutorialIsPresented(tutorial)
    }
    
    func testPresentTutorialAlreadyFulfulled() {
        let tutorial:Tutorial = .GestureActivatedSearch
        mockUserDefaults.setBool(true, forKey: TutorialManager.keyForTutorial(tutorial))
        XCTAssertFalse(tutorialManager.presentTutorialIfUnfulfilled(tutorial))
        XCTAssertNil(presentationController.childVc)
        XCTAssertEqual(0, presentationController.invocations)
    }
    
    func testPresentTutorialWhileOtherIsPresented() {
        let tutorial:Tutorial = .GestureActivatedSearch
		
		tutorialManager.presentedTutorial = createMockVCForTutorial(tutorial)
        let originalTutorialVC = mockVCFactory.tutorialVC
		
        let overrideTutorial = Tutorial.DragAndDrop
		
		XCTAssertTrue(tutorialManager.presentTutorialIfUnfulfilled(overrideTutorial))
        ensureTutorialIsPresented(overrideTutorial)
        XCTAssertEqual(overrideTutorial, mockVCFactory.tutorialVC.tutorialDTO.tutorial)
        XCTAssertEqual(1, originalTutorialVC.transitionOutInvocations.count)
        XCTAssertEqual(TutorialAction.DismissUnfulfilled, originalTutorialVC.transitionOutInvocations[0])
    }
    
    func testPresentTutorialThatsAlreadyPresented() {
        let tutorial:Tutorial = .GestureActivatedSearch
        XCTAssertTrue(tutorialManager.presentTutorialIfUnfulfilled(tutorial))
        ensureTutorialIsPresented(tutorial)
        
        XCTAssertTrue(tutorialManager.presentTutorialIfUnfulfilled(tutorial))
        ensureTutorialIsPresented(tutorial)
    }
    
    func testPresentFulfilledTutorialWhileOtherIsPresented() {
        let tutorial:Tutorial = .GestureActivatedSearch
        let tutorialVC = createMockVCForTutorial(tutorial)
		tutorialManager.presentedTutorial = tutorialVC
        
        let secondTutorial:Tutorial = .GestureActivatedSearch
        mockUserDefaults.setBool(true, forKey: TutorialManager.keyForTutorial(secondTutorial))
        
        XCTAssertFalse(tutorialManager.presentTutorialIfUnfulfilled(secondTutorial))
    }
    
    func testPresentFirstOfUnfulfilledTutorials() {
        let tutorials = tutorialManager.tutorialDataMap.map({$0.0})
        tutorialManager.presentUnfulfilledTutorials(tutorials)
        ensureTutorialIsPresented(tutorials[0])
    }
    
    func testPresentLastOfUnfulfilledTutorials() {
        let tutorial = Tutorial.DragAndDrop
        [Tutorial.GestureActivatedSearch, Tutorial.GestureToViewQueue].forEach {
            mockUserDefaults.setBool(true, forKey: TutorialManager.keyForTutorial($0))
        }
        
        let tutorials:[Tutorial] = [.GestureActivatedSearch, .GestureToViewQueue, .DragAndDrop]
        tutorialManager.presentUnfulfilledTutorials(tutorials)
        ensureTutorialIsPresented(tutorial)
    }
    
    func testResetAllTutorials() {
        tutorialManager.tutorialDataMap.forEach {
            mockUserDefaults.setBool(true, forKey: TutorialManager.keyForTutorial($0.0))
        }
        tutorialManager.resetAllTutorials()
        tutorialManager.tutorialDataMap.forEach {
            XCTAssertFalse(mockUserDefaults.boolForKey(TutorialManager.keyForTutorial($0.0)))
        }
    }
    
    func testDismissTutorialDismissFulfilled() {
		dismissTutorial(.DragAndDrop, withAction: .DismissFulfilled)
    }
	
	func testDismissTutorialDismissUnfulfilled() {
		dismissTutorial(.DragAndDrop, withAction: .DismissUnfulfilled)
	}
	
	func testDismissTutorialFulfill() {
		dismissTutorial(.DragAndDrop, withAction: .Fulfill)
	}
	
	func testDismissTutorialNotPresented() {
		tutorialManager.presentedTutorial = createMockVCForTutorial(.DragAndDrop)
		let actions:[TutorialAction] = [.DismissUnfulfilled, .DismissFulfilled, .Fulfill]
		actions.forEach() {
			XCTAssertFalse(tutorialManager.dismissTutorial(.DragToRearrange, action: $0))
			validateTutorialDismissed(.DragToRearrange, withAction: $0, dismissExpected: false)
		}
	}
	
	func testDimissTutorials() {
		let tutorial = Tutorial.DragAndDrop
		let action = TutorialAction.DismissFulfilled
		tutorialManager.presentedTutorial = createMockVCForTutorial(tutorial)
		
		let tutorials:[Tutorial] = [.GestureToViewQueue, .GestureToViewQueue, tutorial]
		tutorialManager.dimissTutorials(tutorials, action: action)
		
		tutorials.forEach() {
			validateTutorialDismissed($0, withAction: action, dismissExpected: $0 == tutorial)
		}
	}
	
    private func ensureTutorialIsPresented(tutorial:Tutorial) {
        XCTAssertNotNil(presentationController.childVc)
        XCTAssertEqual(1, presentationController.invocations)
		XCTAssertNotNil(tutorialManager.presentedTutorial)
		XCTAssertEqual(presentationController.childVc, tutorialManager.presentedTutorial)
        XCTAssertEqual(tutorial, tutorialManager.presentedTutorial!.tutorialDTO.tutorial)
        XCTAssertTrue(mockVCFactory.tutorialVC?.transitionOutInvocations.isEmpty ?? true)
    }
	
	private func dismissTutorial(tutorial:Tutorial, withAction action:TutorialAction) {
		tutorialManager.presentedTutorial = createMockVCForTutorial(tutorial)
		
		XCTAssertTrue(tutorialManager.dismissTutorial(tutorial, action: action))
		validateTutorialDismissed(tutorial, withAction: action, dismissExpected: true)
	}
	
	private func validateTutorialDismissed(tutorial:Tutorial, withAction action:TutorialAction, dismissExpected:Bool) {
		XCTAssertEqual(dismissExpected && action != .DismissUnfulfilled, mockUserDefaults.boolForKey(TutorialManager.keyForTutorial(tutorial)))
		if dismissExpected {
			XCTAssertEqual(1, mockVCFactory.tutorialVC.transitionOutInvocations.count)
			XCTAssertEqual(action, mockVCFactory.tutorialVC.transitionOutInvocations[0])
		}
	}

	
    private func createMockVCForTutorial(tutorial:Tutorial) -> TutorialViewController {
        let tutorialDTO = TutorialDTO(tutorial: tutorial, instructionText: "", nextTutorial: nil)
        return mockVCFactory.viewControllerForTutorial(tutorialDTO)
    }
    
    class MockUserDefaults : NSUserDefaults {
        var values = [String:Bool]()
        override func setBool(value: Bool, forKey defaultName: String) {
            values[defaultName] = value
        }
        override func boolForKey(defaultName: String) -> Bool {
            return values[defaultName] ?? false
        }
    }
    
    class MockViewController : UIViewController {
        var childVc:UIViewController?
        var invocations = 0
        override func addChildViewController(childController: UIViewController) {
            super.addChildViewController(childController)
            childVc = childController
            invocations += 1
        }
    }
    
    class MockVCFactory : TutorialViewControllerFactory {
        var tutorialVC:MockTutorialViewController!
        override func viewControllerForTutorial(dto: TutorialDTO) -> TutorialViewController {
            tutorialVC = MockTutorialViewController(tutorialDTO: dto)
            return tutorialVC!
        }
    }
    
    class MockTutorialViewController : TutorialViewController {
        var transitionOutInvocations = [TutorialAction]()
        override func viewDidLoad() {}
        override func viewDidAppear(animated:Bool) {}
        override func viewDidDisappear(animated:Bool) {}
        override func transitionOut(action: TutorialAction) {
            transitionOutInvocations.append(action)
        }
    }
    
}
