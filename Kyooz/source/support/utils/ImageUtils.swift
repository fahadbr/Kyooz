//
//  ImageUtils.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/31/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

struct ImageUtils {
	
	static func customSnapshotFromView(_ inputView:UIView) -> UIView {
		//Make an image from the input view
		let image = imageForView(inputView, opaque: false)
		
		//Create an image view
		let snapshot = UIImageView(image: image)
		snapshot.layer.shadowOffset = CGSize.zero
		snapshot.layer.shadowRadius = 5.0
		snapshot.layer.shadowOpacity = 0.6
		
		return snapshot
	}
    
    static func resizeImage(_ image:UIImage, toSize newSize:CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        
        image.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!;
    }
	
	static func imageForView(_ inputView:UIView, opaque:Bool = true) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, opaque, 0)
		inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return image!
	}
    
    
static func mergeArtwork(forTracks tracks:[AudioTrack], usingSize size:CGSize) -> UIImage? {
        guard !tracks.isEmpty else { return nil }
        
        var albumTrackMap = [UInt64:AudioTrack]()
        
        for track in tracks {
            guard track.hasArtwork else { continue }
            
            albumTrackMap[track.albumId] = track
            
            if albumTrackMap.count == 4 { break }
        }
		
		var images = albumTrackMap.map() { $0.1.artworkImage(forSize: size) }
        
        switch albumTrackMap.count {
        case 0:
            return nil
        case 1:
            return albumTrackMap.first?.1.artworkImage(forSize: size)
		case 2:
			images.append(images[1])
			images.append(images[0])
		case 3:
			images.append(images[0])
        default:
            break
        }
		UIGraphicsBeginImageContextWithOptions(size, true, 0)
		for case let (i,image?) in images.enumerated() {
			let halfSize = CGSize(width: size.width/2, height: size.height/2)
			
			let origin:CGPoint
			switch i {
			case 0:
				origin = CGPoint.zero
			case 1:
				origin = CGPoint(x: halfSize.width, y: 0)
			case 2:
				origin = CGPoint(x: 0, y: halfSize.height)
			case 3:
				origin = CGPoint(x: halfSize.width, y: halfSize.height)
			default:
				fatalError("should not be a value outside of 0...3")
			}
			image.draw(in: CGRect(origin: origin, size: halfSize))
		}
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
