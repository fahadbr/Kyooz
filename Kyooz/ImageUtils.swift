//
//  ImageUtils.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/31/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

struct ImageUtils {
	
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
    
    static func resizeImage(image:UIImage, toSize newSize:CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        
        image.drawInRect(CGRect(origin: CGPoint.zero, size: newSize))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage;
    }
	
	static func imageForView(inputView:UIView, opaque:Bool = true) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, opaque, 0)
		inputView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image
	}
    
    
    static func mergeArtwork(forTracks tracks:[AudioTrack], usingSize size:CGSize) -> UIImage? {
        guard !tracks.isEmpty else { return nil }
        
        var albumTrackMap = [UInt64:AudioTrack]()
        
        for track in tracks {
            guard track.hasArtwork else { continue }
            
            albumTrackMap[track.albumId] = track
            
            if albumTrackMap.count == 4 { break }
        }
        
        switch albumTrackMap.count {
        case 0:
            return nil
        case 1:
            return albumTrackMap.first?.1.artworkImage(forSize: size)
        case 2, 3:
            UIGraphicsBeginImageContextWithOptions(size, true, 0)

            guard let image1 = albumTrackMap[albumTrackMap.startIndex].1.artworkImage(forSize: size) else { return nil }
            guard let image2 = albumTrackMap[albumTrackMap.startIndex.successor()].1.artworkImage(forSize: size) else { return nil }
            let halfWidth = size.width/2
//            let i = CGImageCreateWithImageInRect(nil, CGRect.zero)
//            CGImageRend
            image1.drawInRect(CGRect(x: 0, y: 0, width: halfWidth, height: size.height))
            image2.drawInRect(CGRect(x: halfWidth, y: 0, width: halfWidth, height: size.height))
        case 4:
            UIGraphicsBeginImageContextWithOptions(size, true, 0)
            var i = 1
            for (_, track) in albumTrackMap {
                let halfSize = CGSize(width: size.width/2, height: size.height/2)
                guard let image = track.artworkImage(forSize: size) else { return nil }
                
                let origin:CGPoint
                switch i {
                case 1:
                    origin = CGPoint.zero
                case 2:
                    origin = CGPoint(x: halfSize.width, y: 0)
                case 3:
                    origin = CGPoint(x: 0, y: halfSize.height)
                case 4:
                    origin = CGPoint(x: halfSize.width, y: halfSize.height)
                default:
                    fatalError("should not be a value outside of 1...4")
                }
                i += 1
                image.drawInRect(CGRect(origin: origin, size: halfSize))
            }
        default:
            Logger.error("should not have more than 4 tracks in albumTrackMap")
            return nil
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}