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
        ensureTutorialPresented(tutorial, invocationNumber: 1)
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
        XCTAssertTrue(tutorialManager.presentTutorialIfUnfulfilled(tutorial))
        ensureTutorialPresented(tutorial, invocationNumber: 1)
        let originalTutorialVC = mockVCFactory.tutorialVC
        
        let overrideTutorial = Tutorial.DragAndDrop
        XCTAssertTrue(tutorialManager.presentTutorialIfUnfulfilled(overrideTutorial))
        ensureTutorialPresented(overrideTutorial, invocationNumber: 2)
        XCTAssertEqual(overrideTutorial, mockVCFactory.tutorialVC.tutorialDTO.tutorial)
        XCTAssertEqual(1, originalTutorialVC.transitionOutInvocations.count)
        XCTAssertEqual(TutorialAction.DismissUnfulfilled, originalTutorialVC.transitionOutInvocations[0])
    }
    
    func testPresentTutorialThatsAlreadyPresented() {
        let tutorial:Tutorial = .GestureActivatedSearch
        XCTAssertTrue(tutorialManager.presentTutorialIfUnfulfilled(tutorial))
        ensureTutorialPresented(tutorial, invocationNumber: 1)
        
        XCTAssertTrue(tutorialManager.presentTutorialIfUnfulfilled(tutorial))
        ensureTutorialPresented(tutorial, invocationNumber: 1)
    }
    
    func testPresentFulfilledTutorialWhileOtherIsPresented() {
        let tutorial:Tutorial = .GestureActivatedSearch
        XCTAssertTrue(tutorialManager.presentTutorialIfUnfulfilled(tutorial))
        ensureTutorialPresented(tutorial, invocationNumber: 1)
        
        let secondTutorial:Tutorial = .GestureActivatedSearch
        mockUserDefaults.setBool(true, forKey: TutorialManager.keyForTutorial(secondTutorial))
        
        XCTAssertFalse(tutorialManager.presentTutorialIfUnfulfilled(secondTutorial))
        ensureTutorialPresented(tutorial, invocationNumber: 1)
    }
    
    func testPresentUnfulfilledTutorials() {
        let tutorials = tutorialManager.tutorialDataMap.map({$0.0})
        tutorialManager.presentUnfulfilledTutorials(tutorials)
        ensureTutorialPresented(tutorials[0], invocationNumber: 1)
    }
    
    func testPresentFulfilledTutorialsWhenTutorialAlreadyPresented() {
        let tutorial = Tutorial.DragAndDrop
        XCTAssertTrue(tutorialManager.presentTutorialIfUnfulfilled(tutorial))
        ensureTutorialPresented(tutorial, invocationNumber: 1)
        
        [Tutorial.GestureActivatedSearch, Tutorial.GestureToViewQueue].forEach {
            mockUserDefaults.setBool(true, forKey: TutorialManager.keyForTutorial($0))
        }
        
        let tutorials:[Tutorial] = [.GestureActivatedSearch, .GestureToViewQueue, .DragAndDrop]
        tutorialManager.presentUnfulfilledTutorials(tutorials)
        ensureTutorialPresented(tutorial, invocationNumber: 1)
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
    
    func testDismissTutorialGreenPath() {
        
    }
    
    private func ensureTutorialPresented(tutorial:Tutorial, invocationNumber:Int) {
        XCTAssertNotNil(presentationController.childVc)
        XCTAssertEqual(invocationNumber, presentationController.invocations)
        XCTAssertEqual(tutorial, mockVCFactory.tutorialVC.tutorialDTO.tutorial)
        XCTAssertTrue(mockVCFactory.tutorialVC.transitionOutInvocations.isEmpty)
    }
    
    private func createMockVCForTutorial(tutorial:Tutorial) -> MockTutorialViewController {
        let tutorialDTO = TutorialDTO(tutorial: tutorial, instructionText: "", nextTutorial: nil)
        return MockTutorialViewController(tutorialDTO: tutorialDTO)
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
