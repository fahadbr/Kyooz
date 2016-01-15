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

    private enum WorkflowState:Int {
        case SelectItemToPlayNow, SelectItemInQueueToPlayNext, ConfirmChoices
        
        mutating func moveToNextState() {
            if let nextState = WorkflowState(rawValue: self.rawValue + 1) {
                self = nextState
            } else {
                self = ConfirmChoices
            }
        }
        
        mutating func moveToPreviousState() {
            if let previousState = WorkflowState(rawValue: self.rawValue - 1) {
                self = previousState
            } else {
                self = SelectItemToPlayNow
            }
         }
    }
    
    private lazy var nowPlayingViewController = ContainerViewController.instance.nowPlayingViewController!
    private var audioQueuePlayer:AudioQueuePlayer = ApplicationDefaults.audioQueuePlayer
    
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    private var workflowState:WorkflowState = .SelectItemToPlayNow {
        didSet {
            reloadSections()
        }
    }
    
    private var itemToPlayNow:AudioTrack?
    private var indexOfNewItem:Int?
    
    private let itemToPlayNowName = "Track to Play"
    private let itemToPlayNextName = "Track to Play Next In Queue"
    private let keepPlayingCurrentTrackName = "Keep Playing Current Track"
    private let currentQueueName = "Current Queue"
    private var sectionHeaderNames:[String]!
    
    
    @IBAction func cancelWorkflow(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func finishWorkFlow(sender: UIButton) {
        guard let itemToPlayNow = self.itemToPlayNow, let indexOfNewItem = self.indexOfNewItem else {
            Logger.debug("workflow is not done yet!")
            return
        }
        
        if audioQueuePlayer.nowPlayingQueue[indexOfNewItem].id != itemToPlayNow.id {
            audioQueuePlayer.insertItemsAtIndex([itemToPlayNow], index: indexOfNewItem)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sectionHeaderNames = [keepPlayingCurrentTrackName, currentQueueName]
        tableView.registerNib(NibContainer.songTableViewCellNib, forCellReuseIdentifier: SongDetailsTableViewCell.reuseIdentifier)
        tableView.registerNib(NibContainer.headerView, forHeaderFooterViewReuseIdentifier: SearchResultsHeaderView.reuseIdentifier)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        switch workflowState {
        case .SelectItemToPlayNow, .SelectItemInQueueToPlayNext:
            return 2
        case .ConfirmChoices:
            return 3
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 || (workflowState == .ConfirmChoices && section == 1) {
            return 1
        }
        return audioQueuePlayer.nowPlayingQueue.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        func configureCell(cell:SongDetailsTableViewCell, audioTrack:AudioTrack) {
            cell.configureTextLabelsForMediaItem(audioTrack, isNowPlayingItem: false)
            cell.imageView?.image = nowPlayingViewController.getImageForCell(imageSize: cell.imageView!.frame.size, withMediaItem: audioTrack, isNowPlayingItem: false)
        }
        
        switch workflowState {
        case .SelectItemToPlayNow, .SelectItemInQueueToPlayNext:
            if indexPath.section != 0 {
                break
            }
            guard let cell = tableView.dequeueReusableCellWithIdentifier(SongDetailsTableViewCell.reuseIdentifier) as? SongDetailsTableViewCell, audioTrack = workflowState == .SelectItemToPlayNow ? audioQueuePlayer.nowPlayingItem : itemToPlayNow else {
                return UITableViewCell()
            }
            configureCell(cell, audioTrack: audioTrack)
            return cell
            
        case .ConfirmChoices:
            if indexPath.section > 1 {
                break
            }
            guard let cell = tableView.dequeueReusableCellWithIdentifier(SongDetailsTableViewCell.reuseIdentifier) as? SongDetailsTableViewCell, audioTrack = indexPath.section == 0 ? itemToPlayNow : audioQueuePlayer.nowPlayingQueue[indexPath.row]  else {
                return UITableViewCell()
            }
            configureCell(cell, audioTrack: audioTrack)
            return cell
        }
        
        return nowPlayingViewController.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch workflowState {
        case .SelectItemToPlayNow:
            if indexPath.section == 0 {
                itemToPlayNow = audioQueuePlayer.nowPlayingItem
            } else {
                itemToPlayNow = audioQueuePlayer.nowPlayingQueue[indexPath.row]
            }
            workflowState.moveToNextState()
            let indexSet = NSIndexSet(index: 0)
            tableView.beginUpdates()
            tableView.deleteSections(indexSet, withRowAnimation: .Right)
            tableView.insertSections(indexSet, withRowAnimation: .Left)
            tableView.endUpdates()
        case .SelectItemInQueueToPlayNext:
            if indexPath.section == 0 {
                break
            }
            indexOfNewItem = indexPath.row - 1
            workflowState.moveToNextState()
            tableView.insertSections(NSIndexSet(index: 1), withRowAnimation: .Middle)
        default:
            break
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SearchResultsHeaderView.reuseIdentifier) as? SearchResultsHeaderView else {
            return nil
        }
        headerView.headerTitleLabel.text = sectionHeaderNames[section]
        headerView.disclosureContainerView.hidden = true
        return headerView
    }
    
    //MARK: - Class functions
    
    private func reloadSections() {
        switch workflowState {
        case .SelectItemToPlayNow:
            sectionHeaderNames = [keepPlayingCurrentTrackName, currentQueueName]
        case .SelectItemInQueueToPlayNext:
            sectionHeaderNames = [itemToPlayNowName, currentQueueName]
        case .ConfirmChoices:
            sectionHeaderNames = [itemToPlayNowName, itemToPlayNextName, currentQueueName]
        }
    }
    
    
}
