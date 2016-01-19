//
//  SystemQueueResyncWorkflowController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 1/12/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

final class SystemQueueResyncWorkflowController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private static let greenHeaderColor = UIColor(colorLiteralRed: 0, green: 0.4, blue: 0, alpha: 1)
    
    private lazy var nowPlayingViewController = ContainerViewController.instance.nowPlayingViewController!
    private let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    private var previewQueue = ApplicationDefaults.audioQueuePlayer.nowPlayingQueue
    private var nowPlayingItem:AudioTrack!
    
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var headerView: UIView!
    
    private var indexOfNewItem:Int? {
        didSet {
            if oldValue == nil && indexOfNewItem != nil {
                UIView.transitionWithView(messageLabel, duration: 0.5, options: UIViewAnimationOptions.TransitionFlipFromBottom, animations: { () -> Void in
                    self.messageLabel.text = "Choose another track or tap here to Finish!"
                    }, completion: {_ in self.tableView.reloadData() })
                UIView.animateWithDuration(0.3, animations: { [weak self]() -> Void in
                    self?.headerView.backgroundColor = SystemQueueResyncWorkflowController.greenHeaderColor
                })
            }
        }
    }
    
    var completionBlock:((Int)->())?
    
    @IBAction func cancelWorkflow(sender: UIButton?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func messageLabelTapped(sender:UITapGestureRecognizer) {
        guard let newIndex = indexOfNewItem else {
            return
        }
        dismissViewControllerAnimated(true) { [completionBlock = self.completionBlock] in
            completionBlock?(newIndex)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let item = audioQueuePlayer.nowPlayingItem else {
            cancelWorkflow(nil)
            return
        }
        
        nowPlayingItem = item
        
        tableView.registerNib(NibContainer.songTableViewCellNib, forCellReuseIdentifier: SongDetailsTableViewCell.reuseIdentifier)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleNowPlayingItemChanged:", name: AudioQueuePlayerUpdate.NowPlayingItemChanged.rawValue, object: audioQueuePlayer)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return previewQueue.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier(SongDetailsTableViewCell.reuseIdentifier) as? SongDetailsTableViewCell else {
            return UITableViewCell()
        }
        let indexToUse = indexPath.row
        var isNowPlayingItem = false
        
        if let index = indexOfNewItem where index == indexPath.row {
            isNowPlayingItem = true
        }
        
        let mediaItem = previewQueue[indexToUse]
        
        cell.configureTextLabelsForMediaItem(mediaItem, isNowPlayingItem:isNowPlayingItem)
        cell.menuButton.hidden = true
        cell.albumArtImageView.image = nowPlayingViewController.getImageForCell(imageSize: cell.albumArtImageView.frame.size, withMediaItem: mediaItem, isNowPlayingItem:isNowPlayingItem)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        var index = indexPath.row
        if let oldIndex = indexOfNewItem {
            if oldIndex == (index - 1) || oldIndex == index {
                return
            }
            
            if oldIndex < index {
                index = index - 1
            }
            
            let item = previewQueue.removeAtIndex(oldIndex)
            previewQueue.insert(item, atIndex: index)
            indexOfNewItem = index
            tableView.moveRowAtIndexPath(NSIndexPath(forRow: oldIndex, inSection: 0), toIndexPath: NSIndexPath(forRow: index, inSection: 0))
            return
        }
        

        if index == 0 || nowPlayingItem.id != previewQueue[index - 1].id {
            indexOfNewItem = index
            previewQueue.insert(nowPlayingItem, atIndex: index)
            tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Middle)
        } else {
            indexOfNewItem = index - 1
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let view = NSBundle.mainBundle().loadNibNamed("SearchResultsHeaderView", owner: self, options: nil)?.first as? SearchResultsHeaderView else {
            return nil
        }
        view.headerTitleLabel.text = indexOfNewItem == nil ? "CURRENT QUEUE" : "PREVIEW QUEUE"
        view.disclosureContainerView.hidden = true
        return view
    }
    
    //MARK: - Class functions
    
    func handleNowPlayingItemChanged(notification:NSNotification!) {
        if let item = audioQueuePlayer.nowPlayingItem {
            nowPlayingItem = item
            if let index = indexOfNewItem {
                previewQueue[index] = nowPlayingItem
                tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Fade)
            }
        } else {
            cancelWorkflow(nil)
        }
    }
}
