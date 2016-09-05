//
//  AudioEntity.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 6/5/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

@objc protocol AudioEntity : NSSecureCoding, NSObjectProtocol, SearchIndexValue {
    
    var count:Int { get }
    var representativeTrack:AudioTrack? { get }

    func titleForGrouping(_ libraryGrouping:LibraryGrouping) -> String?
    
    func persistentIdForGrouping(_ libraryGrouping:LibraryGrouping) -> UInt64
	
	func artworkImage(forSize size:CGSize) -> UIImage?
	
}


extension AudioEntity {
	
	func artworkImage(forSize size:CGSize, completion:@escaping (UIImage)->()) {
		DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
			let image = self.artworkImage(forSize: size) ?? ImageUtils.resizeImage(ImageContainer.defaultAlbumArtworkImage, toSize: size)
			KyoozUtils.doInMainQueueAsync() {
				completion(image)
			}
		}
	}
	
	
}
