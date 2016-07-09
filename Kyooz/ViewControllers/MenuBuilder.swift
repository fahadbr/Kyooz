//
//  MenuBuilder.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/3/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class MenuBuilder {
	
	private var title: String?
	private var details: String?
	private var originatingCenter: CGPoint?
	private var optionsProviders = [KyoozOptionsProvider]()
	
	var viewController: UIViewController {
		var op = optionsProviders
		op.append(BasicKyoozOptionsProvider(options:KyoozMenuAction(title:"CANCEL")))
		return KyoozOptionsViewController(optionsProviders: op,
		                                  delegate: MenuOptionsDelegate(title: title,
																		details: details,
																		originatingCenter: originatingCenter))
		
		
	}
	
	func with(title title: String?) -> MenuBuilder {
		self.title = title
		return self
	}
	
	func with(details details: String?) -> MenuBuilder {
		self.details = details
		return self
	}
	
	func with(originatingCenter originatingCenter: CGPoint?) -> MenuBuilder {
		self.originatingCenter = originatingCenter
		return self
	}
	
	func with(optionsProviders providers: KyoozOptionsProvider...) -> MenuBuilder {
		optionsProviders.appendContentsOf(providers)
		return self
	}
	
	func with(options options:KyoozOption...) -> MenuBuilder {
		optionsProviders.append(BasicKyoozOptionsProvider(options: options))
		return self
	}
    
    func with(options options:[KyoozOption]) -> MenuBuilder {
        optionsProviders.append(BasicKyoozOptionsProvider(options: options))
        return self
    }
	
	
}