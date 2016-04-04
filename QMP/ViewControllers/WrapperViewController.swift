//
//  WrapperViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/2/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

//view controller primarily used for wrapping a view in a view controller object
final class WrapperViewController : UIViewController {
    
    var completionBlock:(()->())?
    
    let index:Int
    let id:UInt64
    private let wrappedView:UIView
    private let frameInset:CGFloat
    private let resizeView:Bool
    
    
    
    init(wrappedView:UIView, frameInset:CGFloat, resizeView:Bool, index:Int, id:UInt64) {
        self.wrappedView = wrappedView
        self.frameInset = frameInset
        self.resizeView = resizeView
        self.index = index
        self.id = id
        super.init(nibName:nil, bundle:nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        view.addSubview(wrappedView)
    }
    
    override func viewDidLayoutSubviews() {
        if resizeView {
            wrappedView.frame = CGRectInset(view.bounds, frameInset, frameInset)
        } else {
            wrappedView.center = view.center
        }
    }
}
