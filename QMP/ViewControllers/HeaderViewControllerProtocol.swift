//
//  HeaderViewControllerProtocol.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/17/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

protocol HeaderViewControllerProtocol {
    
    var height:CGFloat { get }
    var minimumHeight:CGFloat { get }
    
    var shuffleButton: ShuffleButtonView! { get }
    var selectModeButton: ListButtonView! { get }
    
}