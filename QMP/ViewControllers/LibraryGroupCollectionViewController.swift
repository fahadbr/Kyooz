//
//  LibraryGroupCollectionViewController.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 12/15/15.
//  Copyright © 2015 FAHAD RIAZ. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"
private let maxNumberOfItemsPerSection = 3
private let defaultCellSize = CGSize(width: 115, height: 30)
private let defaultInsets = UIEdgeInsets(top: 5, left: 13, bottom: 0, right: 13)

class LibraryGroupCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let items:[[LibraryGrouping]]
    
    var estimatedHeight:CGFloat {
        var estimate:CGFloat = 0.0
        for _ in items {
            estimate += (defaultCellSize.height + defaultInsets.top + defaultInsets.bottom)
            Logger.debug("estimate is \(estimate)")
        }
        return estimate
    }
    
    init(items:[LibraryGrouping]) {
        var sections = [[LibraryGrouping]]()
        var section = 0
        for (index, item) in items.enumerate() {
            if index % maxNumberOfItemsPerSection == 0 {
                sections.append([item])
            } else {
                sections[section].append(item)
            }
            if sections[section].count == maxNumberOfItemsPerSection {
                section++
            }
        }
        self.items = sections
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView!.backgroundColor = UIColor.blackColor()
        self.collectionView!.registerClass(LibraryGroupCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return items.count
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items[section].count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as? LibraryGroupCollectionViewCell else {
            Logger.error("Unkown cell class returned for collection view")
            return UICollectionViewCell()
        }
    
        cell.text = items[indexPath.section][indexPath.item].name
    
        return cell
    }

    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return defaultCellSize
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return defaultInsets
    }
    
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        Logger.debug("selected item \(indexPath)")
    }

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}
