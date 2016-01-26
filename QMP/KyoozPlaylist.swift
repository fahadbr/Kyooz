//
//  KYPlaylist.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/25/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import Foundation

final class KyoozPlaylist : NSObject, NSSecureCoding {
	
	static let nameKey = "kyoozPlaylist.name"
	static let tracksKey = "kyoozPlaylist.tracks"
	static let countKey = "kyoozPlaylist.count"
	
	static func supportsSecureCoding() -> Bool {
		return true
	}
	
	let name:String
	var count:Int
	
	private var tracks:[AudioTrack]! {
		didSet {
			count = tracks.count
		}
	}
	
	init(name:String, tracks:[AudioTrack]) {
		self.name = name
		self.tracks = tracks
		self.count = tracks.count
	}
	
	init?(coder aDecoder: NSCoder) {
		guard let persistedName = aDecoder.decodeObjectOfClass(NSString.self, forKey: KyoozPlaylist.nameKey) as? String else {
			name = "Unknown"
			tracks = [AudioTrack]()
			count = 0
			return
		}
		
		count = aDecoder.decodeIntegerForKey(KyoozPlaylist.countKey)
		name = persistedName
	}
	
	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(name, forKey: KyoozPlaylist.nameKey)
		aCoder.encodeObject(tracks as NSArray, forKey: KyoozPlaylist.tracksKey)
		aCoder.encodeInteger(count, forKey: KyoozPlaylist.countKey)
	}
	
	
	func getTracks() -> [AudioTrack] {
		let tracksPath = ""
		if tracks == nil {
			guard NSFileManager.defaultManager().fileExistsAtPath(tracksPath) else {
				tracks = [AudioTrack]()
				return tracks
			}
			if let pTracks = NSKeyedUnarchiver.unarchiveObjectWithFile(tracksPath) as? [AudioTrack] {
				tracks = pTracks
			} else {
				tracks = [AudioTrack]()
			}
		}
		return tracks
	}
	
	func setTracks(newTracks:[AudioTrack]) {
		let tracksPath = ""
		guard NSKeyedArchiver.archiveRootObject(newTracks as NSArray, toFile: tracksPath) else {
			Logger.error("failed to persist new tracks for playlist with name \(name)")
			return
		}
		
	}
	
}