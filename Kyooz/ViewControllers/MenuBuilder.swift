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
	
	@discardableResult
	func with(title: String?) -> MenuBuilder {
		self.title = title
		return self
	}
	
	@discardableResult
	func with(details: String?) -> MenuBuilder {
		self.details = details
		return self
	}
	
	@discardableResult
	func with(originatingCenter: CGPoint?) -> MenuBuilder {
		self.originatingCenter = originatingCenter
		return self
	}
	
	@discardableResult
	func with(optionsProviders providers: KyoozOptionsProvider...) -> MenuBuilder {
		optionsProviders.append(contentsOf: providers)
		return self
	}
	
	@discardableResult
	func with(options:KyoozOption...) -> MenuBuilder {
		optionsProviders.append(BasicKyoozOptionsProvider(options: options))
		return self
	}
	
	@discardableResult
    func with(options:[KyoozOption]) -> MenuBuilder {
        optionsProviders.append(BasicKyoozOptionsProvider(options: options))
        return self
    }
	
	
}
