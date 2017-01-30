//
//  TodayViewController.swift
//  Kyooz Up Next
//
//  Created by FAHAD RIAZ on 10/15/16.
//  Copyright © 2016 FAHAD RIAZ. All rights reserved.
//

import UIKit
import NotificationCenter
import MediaPlayer

class TodayViewController: UITableViewController, NCWidgetProviding {
    
    lazy var userDefaults = UserDefaults(suiteName: AudioPlayerCommon.groupId)
    
    var currentIndex: Int = 0
    var lowestPersistedIndex: Int = 0
    var queueIds = [NSNumber]()
    let rowheight: CGFloat = 50
    var rowCount = 2
        
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOSApplicationExtension 10.0, *) {
            self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
            if let displayMode = self.extensionContext?.widgetActiveDisplayMode {
                determineRowCount(activeDisplayMode: displayMode)
            }
        }
        tableView.rowHeight = rowheight
        
        reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func reloadData() {
        guard let queueIds = userDefaults?.object(forKey: AudioPlayerCommon.queueKey) else {
            return
        }
        
        self.queueIds = queueIds as? [NSNumber] ?? []
        self.lowestPersistedIndex = userDefaults?.integer(forKey: AudioPlayerCommon.lastPersistedIndexKey) ?? 0
        self.currentIndex = deriveQueueIndex(musicPlayer: MPMusicPlayerController.systemMusicPlayer(),
                                             lowestIndexPersisted: lowestPersistedIndex,
                                             queueSize: self.queueIds.count)
        tableView.reloadData()
        
    }
    
    @available(iOSApplicationExtension 10.0, *)
    private func determineRowCount(activeDisplayMode: NCWidgetDisplayMode) {
        rowCount = activeDisplayMode == .expanded ? 5 : 2
    }
    
    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        reloadData()
        completionHandler(NCUpdateResult.newData)
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        determineRowCount(activeDisplayMode: activeDisplayMode)
        preferredContentSize = CGSize(width: maxSize.width, height: rowheight * CGFloat(rowCount) + 10)
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(queueIds.count - currentIndex, rowCount)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "todayCell") else {
            return UITableViewCell()
        }
        let index = currentIndex + indexPath.row
        
        guard index < queueIds.count else {
            return cell
        }
        let id = queueIds[index]
        let query = MPMediaQuery.songs()
        query.addFilterPredicate(MPMediaPropertyPredicate(value: id,
                                                          forProperty: MPMediaItemPropertyPersistentID))
        
        guard let track = query.items?.first else {
            return cell
        }
        
        cell.textLabel?.text = track.title ?? "Nothing to play"
        cell.detailTextLabel?.text = "\(track.albumArtist ?? "") - \(track.albumTitle ?? "")"
        cell.imageView?.image = track.artwork?.image(at: cell.imageView!.frame.size)
        
        if indexPath.row == 0 {
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
        } else {
            cell.textLabel?.font = UIFont.systemFont(ofSize: UIFont.labelFontSize)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
}
