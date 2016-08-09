//
//  KyoozTweaks.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 7/9/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

struct KyoozTweaks : TweakLibraryType {
    
    static let menuSpringAnimation = SpringAnimationTweakTemplate("Animations", "Menu")
    static let whatsNewSpringAnimation = SpringAnimationTweakTemplate("Animations", "Whats New")
    
    static let defaultStore: TweakStore = {
        let all: [TweakClusterType] = [menuSpringAnimation, whatsNewSpringAnimation]
        
        return TweakStore(tweaks:all, enabled: TweakDebug.isActive)
    }()
    
}
