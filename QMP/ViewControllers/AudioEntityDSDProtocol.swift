//
//  AudioEntityTVDataSourceProtocol.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 2/3/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit

protocol RowLimitingDSDProtocol : UITableViewDelegate, UITableViewDataSource {
    var rowLimit:Int { get set }
    var rowLimitActive:Bool { get set }
    var hasData:Bool { get }
}

protocol AudioEntityDSDProtocol : RowLimitingDSDProtocol {
    
    var sourceData:AudioEntitySourceData { get }

}

