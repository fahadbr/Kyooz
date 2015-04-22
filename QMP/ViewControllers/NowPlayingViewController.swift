//
//  NowPlayingViewController.swift
//  MediaPlayer
//
//  Created by FAHAD RIAZ on 12/28/14.
//  Copyright (c) 2014 FAHAD RIAZ. All rights reserved.
//

import UIKit
import MediaPlayer

class NowPlayingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {

    let notificationCenter = NSNotificationCenter.defaultCenter()
    let queueBasedMusicPlayer = MusicPlayerContainer.queueBasedMusicPlayer
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.defaultCenter()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        registerForMediaPlayerNotifications()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

    }
    
    deinit {
        unregisterForMediaPlayerNotifications()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let nowPlayingQueue = queueBasedMusicPlayer.getNowPlayingQueue()
        if(nowPlayingQueue != nil) {
            var count = nowPlayingQueue!.count
            return count
        } else {
            return 0
        }
    }
    
    
    @IBAction func clearUpcomingItems(sender: UIBarButtonItem) {
        queueBasedMusicPlayer.clearUpcomingItems()
        tableView.reloadData()
    }
    

    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    func handleNowPlayingItemChanged(notification:NSNotification) {
        tableView.reloadData()
    }
    
    func handlePlaybackStateChanged(notification:NSNotification) {
//        println("handling playback state changed notification");
        tableView.reloadData()
    }
    
    func handlePlaybackStateCorrected(notification:NSNotification) {
        tableView.reloadData()
    }
    
    private func registerForMediaPlayerNotifications() {
        let musicPlayer = MusicPlayerContainer.defaultMusicPlayerController
        notificationCenter.addObserver(self, selector: "handleNowPlayingItemChanged:",
            name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification,
            object: musicPlayer)
        
        notificationCenter.addObserver(self, selector: "handlePlaybackStateChanged:",
            name:MPMusicPlayerControllerPlaybackStateDidChangeNotification,
            object: musicPlayer)
        
        notificationCenter.addObserver(self, selector: "handlePlaybackStateCorrected:",
            name:PlaybackStateManager.PlaybackStateCorrectedNotification,
            object: PlaybackStateManager.instance)
        musicPlayer.beginGeneratingPlaybackNotifications()
    }
    
    private func unregisterForMediaPlayerNotifications() {
        let musicPlayer = MusicPlayerContainer.defaultMusicPlayerController
        notificationCenter.removeObserver(self, name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification, object: musicPlayer)
        notificationCenter.removeObserver(self, name: MPMusicPlayerControllerPlaybackStateDidChangeNotification, object: musicPlayer)
        notificationCenter.removeObserver(self, name: PlaybackStateManager.PlaybackStateCorrectedNotification, object: PlaybackStateManager.instance)
        musicPlayer.endGeneratingPlaybackNotifications()
    }

    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("nowPlayingItem", forIndexPath: indexPath) as! UITableViewCell
        
        var queue = queueBasedMusicPlayer.getNowPlayingQueue()
        if(queue == nil) {
            return cell
        }
        
        var wrappedSong = queue?[indexPath.row]
        if(wrappedSong == nil) {
            return cell
        }
        
        var song = wrappedSong!
        
        cell.textLabel?.text = song.title
        cell.textLabel?.font = ThemeHelper.defaultFont
//            + "(" + String.convertFromStringInterpolationSegment(song.persistentID) + ")"
        cell.accessoryType = UITableViewCellAccessoryType.None
        
        if(queueBasedMusicPlayer.musicIsPlaying
            && isNowPlayingItem(self.queueBasedMusicPlayer.nowPlayingItem, mediaItemToCompare:song, index:indexPath.row)) {
                
            //this is the now playing item that should be highlighted
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var index = indexPath.row
        queueBasedMusicPlayer.playItemWithIndexInCurrentQueue(index: index)
    }
    

    
    private func getSongForIndex(index: Int) -> MPMediaItem? {
        var queue = queueBasedMusicPlayer.getNowPlayingQueue()
        if(queue == nil) {
            return nil
        }
        
        return queue?[index]
    }
    
    private func isNowPlayingItem(baseMediaItem:MPMediaItem?, mediaItemToCompare:MPMediaItem, index:Int) -> Bool{
        if(baseMediaItem?.persistentID != mediaItemToCompare.persistentID) {
            return false
        }
        
//        if(index != musicPlayer.indexOfNowPlayingItem){
//            return false
//        }
        
        return true
        
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    // Override to support editing the table view.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            queueBasedMusicPlayer.deleteItemAtIndexFromQueue(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
           
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        } 
        
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
//        tableView.moveRowAtIndexPath(<#indexPath: NSIndexPath#>, toIndexPath: <#NSIndexPath#>)
        queueBasedMusicPlayer.rearrangeMediaItems(sourceIndexPath.row, toIndexPath: destinationIndexPath.row)
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
