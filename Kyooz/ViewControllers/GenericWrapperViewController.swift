//
//  GenericWrapperViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/12/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

final class GenericWrapperViewController<T:UIView> : UIViewController {
    
    let wrappedView:T
    
    init(viewToWrap:T) {
        self.wrappedView = viewToWrap
        super.init(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        self.view = wrappedView
    }
    
    
    
}
