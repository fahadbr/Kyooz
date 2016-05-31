//
//  ImageContainer.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 4/26/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit

struct ImageContainer {
    
    static let defaultAlbumArtworkImage:UIImage = UIImage(named: "AlbumPlaceHolder")!
    static let smallDefaultArtworkImage:UIImage = ImageContainer.resizeImage(defaultAlbumArtworkImage, toSize: CGSize(width: 150, height: 150))
    
    static func resizeImage(image:UIImage, toSize newSize:CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        
        image.drawInRect(CGRect(origin: CGPoint.zero, size: newSize))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage;
    }
}

