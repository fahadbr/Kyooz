//
//  WhatsNewOptionsDelegate.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/30/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

private let appString = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1115959967&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"

func whatsNewViewController(_ completion: (()->Void)? = nil) throws -> KyoozOptionsViewController {
    
	let op = BasicKyoozOptionsProvider(options:
        KyoozMenuAction(title: "Rate us in the AppStore", highlighted: true) {
            
            guard let url = URL(string: appString) else {
                KyoozUtils.showPopupError(withTitle: "Unable to open AppStore page for Kyooz",
                    withMessage: nil,
                    presentationVC: nil)
                return
            }
            
            UIApplication.shared.openURL(url)
			completion?()
			return
            
		},KyoozMenuAction(title: "No thanks", action: completion)
	)
	
	
	return KyoozOptionsViewController(optionsProviders: [op],
	                                  delegate: try WhatsNewOptionsDelegate())
}

class WhatsNewOptionsDelegate : KyoozOptionsViewControllerDelegate {
    
    private typealias This = WhatsNewOptionsDelegate
    
    
    private static var sizeConstraint: SizeConstraint {
        let height = UIScreen.main.bounds.height * 0.90
        let width = UIScreen.main.bounds.width * 0.85
        return SizeConstraint(maxHeight: height,
                              maxWidth: width,
                              minHeight: height,
                              minWidth: width)
    }
    private static let stackViewMargin: CGFloat = 10
    private static let bigFont = UIFont(name: ThemeHelper.defaultFontNameBold,
                                        size: ThemeHelper.defaultFontSize + (UIScreen.widthClass == .iPhone345 ? 1 : 3))
    
    let sizeConstraint: SizeConstraint = This.sizeConstraint
    
    private let textView: UITextView
    
    var sectionDividerPosition: CGFloat { return 0 }
    
    var sectionHeight: CGFloat {
        return sectionHeader.frame.height
    }
    
    var headerView: UIView {
        let versionNumber = KyoozUtils.appVersion
        let version = versionNumber == nil ? "this Version" : "Version " + versionNumber!
        let whatsNewLabel = initLabel(text: "Whats New in \(version)",
                                      font: This.bigFont)
        
        let stackViewHeight = self.sizeConstraint.maxHeight
            - (KyoozOptionsViewController.cellHeight * 2)
            - self.sectionHeight

        return stackView(forSubviews: [whatsNewLabel, textView],
                         height: stackViewHeight,
                         widthMargin: This.stackViewMargin,
                         heightMargin: This.stackViewMargin)
    }
    
    lazy var sectionHeader:UIView = {
        let enjoyingLabel = self.initLabel(text: "Enjoying Kyooz?",
                                           font: This.bigFont)
        
        let pleaseRateLabel = self.initLabel(text: "Please tell us how we're doing",
                                             font: ThemeHelper.defaultFont(forStyle: .normal))
        let heightMargin:CGFloat = 15
        return self.stackView(forSubviews: [enjoyingLabel, pleaseRateLabel],
                              height: enjoyingLabel.frame.size.height + pleaseRateLabel.frame.size.height + heightMargin * 2,
                              widthMargin: This.stackViewMargin,
                              heightMargin: heightMargin)
    }()
    
    init() throws {
        textView = try UITextView(fileName: "ChangeLog", documentType: .html)
        textView.indicatorStyle = .white
    }
    
    
    func animation(forView view: UIView) -> CAAnimation {
        let animation = CASpringAnimation(keyPath: "transform.translation.y")

        animation.damping = 50
        animation.initialVelocity = 0
        animation.mass = 1.5
        animation.stiffness = 600
        
        animation.duration = animation.settlingDuration
        animation.fromValue = view.frame.height * 1.5
        animation.fillMode = kCAFillModeBackwards
        return animation
    }
    
    func headerView(forSection section: Int) -> UIView {
        return self.sectionHeader
    }
    
    //MARK: - Private funcs
    
    private func initLabel(text:String, font:UIFont?) -> UILabel {
        let label = UILabel()
        label.textColor = ThemeHelper.defaultFontColor
        label.font = font
        label.text = text
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        let size = label.intrinsicContentSize
        label.frame.size = CGSize(width: sizeConstraint.maxWidth, height: size.height)
        return label
    }
    
    private func stackView(forSubviews subViews: [UIView],
                                       height: CGFloat,
                                       widthMargin: CGFloat,
                                       heightMargin: CGFloat) -> UIStackView {
        
        let stackView = UIStackView(arrangedSubviews: subViews)
        stackView.axis = .vertical
        stackView.spacing = 5
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: heightMargin,
                                               left: widthMargin,
                                               bottom: heightMargin,
                                               right: widthMargin)
        
        stackView.frame.size = CGSize(width: sizeConstraint.maxWidth, height: height)
        return stackView

    }
    
}
