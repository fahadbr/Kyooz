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

struct ImageHelper {
    
    static func customSnapshotFromView(inputView:UIView) -> UIView {
        //Make an image from the input view
        let image = imageForView(inputView, opaque: false)
        
        //Create an image view
        let snapshot = UIImageView(image: image)
        snapshot.layer.shadowOffset = CGSize.zero
        snapshot.layer.shadowRadius = 5.0
        snapshot.layer.shadowOpacity = 0.6
        
        return snapshot
    }
    
    static func imageForView(inputView:UIView, opaque:Bool = true) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, opaque, 0)
        inputView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}