//
//  ArrayExtension.swift
//  Kyooz
//
//  Created by FAHAD RIAZ on 5/17/15.
//  Copyright (c) 2015 FAHAD RIAZ. All rights reserved.
//

import Foundation

extension Array {
    
    mutating func insertAtIndex(_ itemsToInsert:[Element], index:Int, placeHolderItem:Element) {
        if(itemsToInsert.isEmpty) { return }
        
        if(index >= self.count) {
            self.append(contentsOf: itemsToInsert)
            return
        }
        
        if(itemsToInsert.count == 1) {
            self.insert(itemsToInsert[0], at: index)
            return
        }
        
        //create a new array and place items in it accordingly, as it is much more efficient
        //than calling the insert function on the array multiple times
        let originalArray = self
        let endIndexOfInsertedItems = index + itemsToInsert.count
        let newArraySize = originalArray.count + itemsToInsert.count

        var newArray = [Element](repeating: placeHolderItem, count: newArraySize)
        
        for i in 0..<newArraySize {
            if(index <= i && i < endIndexOfInsertedItems) {
                newArray[i] = itemsToInsert[i - index]
            } else if (i < index){
                newArray[i] = originalArray[i]
            } else if (i >= endIndexOfInsertedItems) {
                newArray[i] = originalArray[i - itemsToInsert.count]
            }
        }
        
        self = newArray
    }


    func diffed(with array: [Element], predicate:(Element, Element) -> Bool) -> ArrayDiff<Element> {
        return ArrayDiff(lhs: self, rhs: array, predicate: predicate)
    }
}

enum ValueResult { case added, removed }

struct ArrayDiffValue<T> { let index:Int, value:T, result:ValueResult }

struct ArrayDiff<T> {
    
    let diffValues:[ArrayDiffValue<T>]
    
    init(lhs:[T], rhs:[T], predicate:(T, T) -> Bool ) {
        var diffValues = [ArrayDiffValue<T>]()
        diffValues.append(contentsOf: lhs.filter { i in !rhs.contains(where: { predicate($0, i) }) }.enumerated().map { ArrayDiffValue(index: $0, value: $1, result: .removed) })
        diffValues.append(contentsOf: rhs.filter { i in !lhs.contains(where: { predicate($0, i) }) }.enumerated().map { ArrayDiffValue(index: $0, value: $1, result: .added) })
        self.diffValues = diffValues
    }
    
}
