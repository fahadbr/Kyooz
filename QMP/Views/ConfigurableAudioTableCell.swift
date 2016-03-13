//
//  ConfigurableAudioTableCell.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 9/2/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import MediaPlayer

protocol ConfigurableAudioTableCell : class {
    
    weak var delegate:ConfigurableAudioTableCellDelegate? { get set }
    
    var isNowPlaying:Bool { get set }
    
    func configureCellForItems(entity:AudioEntity, libraryGrouping:LibraryGrouping)

}

protocol ConfigurableAudioTableCellDelegate : class {
	func presentActionsForCell(cell:UITableViewCell, title:String?, details:String?, originatingCenter:CGPoint)
}
