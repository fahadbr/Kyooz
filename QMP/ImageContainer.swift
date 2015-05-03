//
//  ImageContainer.swift
//  QMP
//
//  Created by FAHAD RIAZ on 4/26/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

struct ImageContainer {
    
    static let defaultAlbumArtworkImage:UIImage = UIImage(named: "headphones")!
    
    static let currentlyPlayingImage:UIImage = UIImage(named: "play_button_highlighted")!
    
    static let currentlyPausedImage:UIImage = UIImage(named:"pause_button_highlighted")!
    
    static func resizeImage(image:UIImage, toSize newSize:CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        
        image.drawInRect(CGRect(origin: CGPoint.zeroPoint, size: newSize))
        
        var newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage;
    }
}