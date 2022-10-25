//
//  NXRightsViewFlowlayout.swift
//  skyDRM
//
//  Created by Stepanoval (Xinxin) Huang on 2019/9/26.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

class NXRightsViewFlowlayout: NSCollectionViewFlowLayout {
    var maximumInteritemSpace : CGFloat?
    
    override func prepare() {
        maximumInteritemSpace = 15
        minimumLineSpacing = 15
        minimumInteritemSpacing = 15
        sectionInset = NSEdgeInsetsMake(11, 11, 11, 0)
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
        var temIndexPathSection:Int = 0
        var temIndexPathY:CGFloat = 0
        
        for attributes in newAnswer {
            let index = newAnswer.firstIndex(of: attributes);
            if index == 0 {
                continue;
            }
            if attributes.representedElementKind == "UICollectionElementKindSectionHeader"{
                continue;
            }
            
            if attributes.indexPath?.item == 0 {
                temIndexPathSection = attributes.indexPath!.section
                temIndexPathY = attributes.frame.origin.y
                
                var frame = attributes.frame;
                frame.origin.x = sectionInset.left;
                let maxWidth = collectionViewContentSize.width - sectionInset.right - sectionInset.left;
                frame.size.width = frame.size.width > maxWidth ? maxWidth : frame.size.width;
                attributes.frame = frame;
                continue
            }
            
            if attributes.indexPath?.section == temIndexPathSection  && temIndexPathY != attributes.frame.origin.y {
                temIndexPathY = attributes.frame.origin.y
                var frame = attributes.frame;
                frame.origin.x = sectionInset.left;
                let maxWidth = collectionViewContentSize.width - sectionInset.right - sectionInset.left;
                frame.size.width = frame.size.width > maxWidth ? maxWidth : frame.size.width;
                attributes.frame = frame;
            }
            
            if attributes.indexPath?.section == temIndexPathSection && temIndexPathY == attributes.frame.origin.y{
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
        }
        
        return newAnswer;
    }
}

