//
//  LongPressDragAndDropGestureHandler.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer


final class LongPressDragAndDropGestureHandler : LongPressToDragGestureHandler{
    
    var dragSource:DragSource
    var dropDestination:DropDestination
    
    var itemsToDrag:[AudioTrack]!
    var cancelView:CancelView
    var cancelViewVisible:Bool = false
    
    override var locationInDestinationTableView:Bool {
        didSet {
            (wrapperDSD as? DragToInsertDSDWrapper)?.locationInDestinationTableView = locationInDestinationTableView
        }
    }

    
    init(dragSource:DragSource, dropDestination:DropDestination) {
        self.dragSource = dragSource
        self.dropDestination = dropDestination

        let originalTableBounds = dropDestination.destinationTableView.bounds
        let frame = CGRect(origin: CGPoint(x: 0, y: -dropDestination.destinationTableView.contentInset.top),
            size: originalTableBounds.size)
        
        cancelView = CancelView(frame: frame)
        
        super.init(sourceTableView: dragSource.sourceTableView, destinationTableView: dropDestination.destinationTableView)

        shouldHideSourceView = false
        snapshotScale = 0.85
        updateSnapshotXPosition = true
        cornerRadiusForSnapshot = 10
    }
    
    override func removeSnapshotFromView(viewToFadeIn: UIView?, viewToFadeOut: UIView, completionHandler: (Bool) -> ()) {
        super.removeSnapshotFromView(nil, viewToFadeOut: viewToFadeOut, completionHandler: completionHandler)
    }
    
    override func gestureDidBegin(sender: UIGestureRecognizer) {
        super.gestureDidBegin(sender)

        let tableView = dropDestination.destinationTableView
        let location = sender.locationInView(tableView)
        let destinationIndexPath = tableView.indexPathForRowAtPoint(CGPoint(x: 0, y: location.y)) ?? NSIndexPath(forRow: tableView.dataSource!.tableView(tableView, numberOfRowsInSection: 0) - 1, inSection: 0)
        indexPathOfMovingItem = destinationIndexPath

        tableView.insertRowsAtIndexPaths([destinationIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
    override func createWrapperDSD(tableView:UITableView, sourceDSD:AudioEntityDSDProtocol, originalIndexPath:NSIndexPath) -> DragToRearrangeDSDWrapper? {
        guard let entities = dragSource.getSourceData()?.getTracksAtIndex(originalIndexPath) else {
            return nil
        }
        return DragToInsertDSDWrapper(tableView: tableView, datasourceDelegate: sourceDSD, originalIndexPath: originalIndexPath, entitiesToInsert: entities)
    }
}

protocol DragSource {

    var sourceTableView:UITableView? { get }
    
    func getSourceData() -> AudioEntitySourceData?
    
}

protocol DropDestination {
    
    var destinationTableView:UITableView { get }
    
    func setDropItems(dropItems:[AudioTrack], atIndex:NSIndexPath) -> Int
    
}