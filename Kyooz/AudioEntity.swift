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

    func titleForGrouping(libraryGrouping:LibraryGrouping) -> String?
    
    func persistentIdForGrouping(libraryGrouping:LibraryGrouping) -> UInt64
	
	func artworkImage(forSize size:CGSize) -> UIImage?
	
}

@objc protocol AudioTrackCollection : AudioEntity {
    
    var tracks:[AudioTrack] { get }

}


extension AudioEntity {
	
	func artworkImage(forSize size:CGSize, completion:(UIImage)->()) {
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
			let image = self.artworkImage(forSize: size) ?? ImageUtils.resizeImage(ImageContainer.defaultAlbumArtworkImage, toSize: size)
			KyoozUtils.doInMainQueueAsync() {
				completion(image)
			}
		}
	}
	
	
}