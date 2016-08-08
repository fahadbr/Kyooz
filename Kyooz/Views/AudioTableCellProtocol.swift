//
//  ConfigurableAudioTableCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 9/2/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

protocol AudioTableCellProtocol : class {
    
    weak var delegate:AudioTableCellDelegate? { get set }
    
    var isNowPlaying:Bool { get set }
    
    func configureCellForItems(_ entity:AudioEntity, libraryGrouping:LibraryGrouping)

}

protocol AudioTableCellDelegate : class {
	
	var shouldAnimateInArtwork:Bool { get }
	
	func presentActionsForCell(_ cell:UITableViewCell, title:String?, details:String?, originatingCenter:CGPoint)
	
}
