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

    private static let greenHeaderColor = UIColor(red: 0, green: 0.4, blue: 0, alpha: 1)
    
    private let audioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    private var previewQueue = ApplicationDefaults.audioQueuePlayer.nowPlayingQueue
    private var nowPlayingItem:AudioTrack!
    
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var headerView: UIView!
    
    private var indexOfNewItem:Int? {
        didSet {
            if oldValue == nil && indexOfNewItem != nil {
                UIView.transition(with: messageLabel, duration: 0.5, options: UIViewAnimationOptions.transitionFlipFromBottom, animations: { () -> Void in
                    self.messageLabel.text = "Choose another track or tap here to Finish!"
                    }, completion: {_ in self.tableView.reloadData() })
                UIView.animate(withDuration: 0.3, animations: { [weak self]() -> Void in
                    self?.headerView.backgroundColor = SystemQueueResyncWorkflowController.greenHeaderColor
                })
            }
        }
    }
    
    var completionBlock:((Int)->())?
    
    @IBAction func cancelWorkflow(_ sender: UIButton?) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func messageLabelTapped(_ sender:UITapGestureRecognizer) {
        guard let newIndex = indexOfNewItem else {
            return
        }
        dismiss(animated: true) { [completionBlock = self.completionBlock] in
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
        
        tableView.register(NibContainer.songTableViewCellNib, forCellReuseIdentifier: SongDetailsTableViewCell.reuseIdentifier)
        tableView.register(KyoozSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: KyoozSectionHeaderView.reuseIdentifier)
        NotificationCenter.default.addObserver(
            forName: AudioQueuePlayerUpdate.nowPlayingItemChanged.notification,
            object: audioQueuePlayer,
            queue: OperationQueue.main,
            using: self.handleNowPlayingItemChanged(_:)
        )

//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(self.handleNowPlayingItemChanged(_:)),
//            name: NSNotification.Name(rawValue: AudioQueuePlayerUpdate.nowPlayingItemChanged.rawValue),
//            object: audioQueuePlayer)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return previewQueue.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SongDetailsTableViewCell.reuseIdentifier) as? SongDetailsTableViewCell else {
            return UITableViewCell()
        }
        let indexToUse = (indexPath as NSIndexPath).row
        var isNowPlayingItem = false
        
        if let index = indexOfNewItem, index == (indexPath as NSIndexPath).row {
            isNowPlayingItem = true
        }
        
        let mediaItem = previewQueue[indexToUse]
        
        cell.configureCellForItems(mediaItem, libraryGrouping: LibraryGrouping.Songs)
        cell.isNowPlaying = isNowPlayingItem
        cell.menuButton.isHidden = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var index = (indexPath as NSIndexPath).row
        if let oldIndex = indexOfNewItem {
            if oldIndex == (index - 1) || oldIndex == index {
                return
            }
            
            if oldIndex < index {
                index = index - 1
            }
            
            let item = previewQueue.remove(at: oldIndex)
            previewQueue.insert(item, at: index)
            indexOfNewItem = index
            tableView.moveRow(at: IndexPath(row: oldIndex, section: 0), to: IndexPath(row: index, section: 0))
            return
        }
        

        if index == 0 || nowPlayingItem.id != previewQueue[index - 1].id {
            indexOfNewItem = index
            previewQueue.insert(nowPlayingItem, at: index)
            tableView.insertRows(at: [indexPath], with: .middle)
        } else {
            indexOfNewItem = index - 1
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: KyoozSectionHeaderView.reuseIdentifier) as? KyoozSectionHeaderView else {
            return nil
        }
        
        headerView.headerTitleLabel.text = indexOfNewItem == nil ? "CURRENT QUEUE" : "PREVIEW QUEUE"
        return headerView
    }
    
    //MARK: - Class functions
    
    func handleNowPlayingItemChanged(_ notification:Notification!) {
        if let item = audioQueuePlayer.nowPlayingItem {
            nowPlayingItem = item
            if let index = indexOfNewItem {
                previewQueue[index] = nowPlayingItem
                tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.fade)
            }
        } else {
            cancelWorkflow(nil)
        }
    }
}
