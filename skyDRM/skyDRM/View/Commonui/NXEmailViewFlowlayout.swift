//
//  NXEmailViewFlowlayout.swift
//  macexample
//
//  Created by nextlabs on 2/7/17.
//  Copyright © 2017 zhuimengfuyun. All rights reserved.
//

import Cocoa

class NXEmailViewFlowlayout: NSCollectionViewFlowLayout {
    var maximumInteritemSpace : CGFloat?
    
    override func prepare() {
        maximumInteritemSpace = 8
        minimumLineSpacing = 8
        minimumInteritemSpacing = 8
        sectionInset = NSEdgeInsetsMake(8, 8, 8, 8)
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
        return true
    }
    
    override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
        let answer = super.layoutAttributesForElements(in: rect);
        let newAnswer = NSArray(array: answer, copyItems: true) as! [NSCollectionViewLayoutAttributes]
        if newAnswer.count > 0 {
            let temp = newAnswer[0];
            var frame = temp.frame;
            frame.origin.x = sectionInset.left;
            let maxWidth = collectionViewContentSize.width - sectionInset.right - sectionInset.left;
            frame.size.width = frame.size.width > maxWidth ? maxWidth : frame.size.width;
            temp.frame = frame;
        }
        for attributes in newAnswer {
            let index = newAnswer.firstIndex(of: attributes);
            if index == 0 {
                continue;
            }
            let origin = newAnswer[index!-1].frame.maxX;
            
            if origin + maximumInteritemSpace! + attributes.frame.size.width < collectionViewContentSize.width - sectionInset.right {
                //two cell's max space to work
                var frame = attributes.frame;
                frame.origin.x = origin + maximumInteritemSpace!;
                attributes.frame = frame;
            } else {
                //for first row in new row, just make it align left.
                var frame = attributes.frame;
                frame.origin.x = sectionInset.left;
                attributes.frame = frame;
            }
            
            //when itemsize.width is out of range of collectionview's bounds, just make item's width adjust the width
            if attributes.frame.size.width > collectionViewContentSize.width {
                var frame = attributes.frame;
                frame.size.width = collectionViewContentSize.width - frame.origin.x - sectionInset.right;
                attributes.frame = frame;
            }
        }
        return newAnswer;
    }
}
