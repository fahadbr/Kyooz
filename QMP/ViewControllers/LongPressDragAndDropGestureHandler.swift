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

    override var indexPathOfMovingItem:NSIndexPath! {
        didSet {
            dropDestination.indexPathOfMovingItem = indexPathOfMovingItem
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
        snapshotScale = 1.0
        updateSnapshotXPosition = true
        cornerRadiusForSnapshot = 10
    }
    
    override func getViewForSnapshot(sender: UIGestureRecognizer) -> UIView? {
        guard let indexPath = originalIndexPathOfMovingItem, let sourceData = dragSource.getSourceData() else {
            return nil
        }
        itemsToDrag = sourceData.getTracksAtIndex(indexPath)
        let v = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.width * 0.6, height: 100))
        v.backgroundColor = ThemeHelper.defaultTableCellColor
        
        func configureLabel(label:UILabel, text:String?, font:UIFont?) {
            label.textAlignment = .Center
            label.font = font ?? ThemeHelper.defaultFont
            label.text = text
            label.textColor = ThemeHelper.defaultFontColor
            label.numberOfLines = 0
            label.lineBreakMode = .ByWordWrapping
            label.frame = label.textRectForBounds(v.bounds, limitedToNumberOfLines: 0)
        }
        
        let label1 = UILabel()
        configureLabel(label1, text: itemsToDrag?.first?.titleForGrouping(sourceData.libraryGrouping), font: UIFont(name: ThemeHelper.defaultFontNameMedium, size: 15))
        let label2 = UILabel()
        configureLabel(label2, text: "\(itemsToDrag?.count ?? 0) Tracks", font: UIFont(name: ThemeHelper.defaultFontName, size: 12))
        
        let stackView = UIStackView(arrangedSubviews: [label1, label2])
        stackView.frame = CGRect(x: 0, y: 0, width: v.frame.width, height: v.frame.height/2)
        stackView.axis = .Vertical
        stackView.alignment = .Center
        v.addSubview(stackView)
        
        v.layer.borderColor = ThemeHelper.defaultVividColor.CGColor
        v.layer.borderWidth = 1.5
        return v
        
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
    
    override func gestureDidChange(sender: UIGestureRecognizer, newLocationInsideTableView: CGPoint?) {
        if newLocationInsideTableView == nil && !cancelViewVisible {
            cancelView.cancelLabel.alpha = 0
            cancelViewVisible = true
            let tableView = dropDestination.destinationTableView
            tableView.addSubview(cancelView)
            cancelView.center.x = tableView.center.x
            cancelView.frame.origin.y = tableView.contentOffset.y + tableView.contentInset.top
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.cancelView.blurView.effect = UIBlurEffect(style: .Light)
                self.cancelView.cancelLabel.alpha = 1.0
            })
        } else if newLocationInsideTableView != nil && cancelViewVisible {
            removeCancelView()
        }
    }
    
    private func removeCancelView() {
        cancelView.cancelLabel.alpha = 1.0
        cancelViewVisible = false
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.cancelView.blurView.effect = nil
            self.cancelView.cancelLabel.alpha = 0.0
            }, completion: { (finished:Bool) -> Void in
                self.cancelView.removeFromSuperview()
        })
    }
    
    override func persistChanges(sender: UIGestureRecognizer) {
        if(cancelViewVisible) {
            removeCancelView()
        }
        let tableView = dropDestination.destinationTableView
        let location = sender.locationInView(tableView)
        let insideTableView = tableView.pointInside(location, withEvent: nil)
        let localItemsToInsert = itemsToDrag
        let localIndexPathForInserting = indexPathOfMovingItem
        
        tableView.deleteRowsAtIndexPaths([localIndexPathForInserting], withRowAnimation: .None)
        
        if(insideTableView) {
            if let itemsToInsert = localItemsToInsert {
                var indexPaths = [NSIndexPath]()
                let startingIndex = localIndexPathForInserting.row
                let noOfItemsToInsert = dropDestination.setDropItems(itemsToInsert, atIndex:localIndexPathForInserting)
                for index in startingIndex ..< (startingIndex + noOfItemsToInsert)  {
                    indexPaths.append(NSIndexPath(forRow: index, inSection: 0))
                }
                
                tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: noOfItemsToInsert == 1 ? .Fade : .Automatic)
            }
        }
    }
}

protocol DragSource {

    var sourceTableView:UITableView? { get }
    
    func getSourceData() -> AudioEntitySourceData?
    
}

protocol DropDestination {
    
    var indexPathOfMovingItem:NSIndexPath! { get set }
    
    var destinationTableView:UITableView { get }
    
    func setDropItems(dropItems:[AudioTrack], atIndex:NSIndexPath) -> Int
    
}