//
//  NXEmailItem.swift
//  macexample
//
//  Created by nextlabs on 2/7/17.
//  Copyright © 2017 zhuimengfuyun. All rights reserved.
//

import Cocoa

class NXEmailItem: NSCollectionViewItem {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func loadView() {
        
        var topLevelObjects : NSArray?
        if (Bundle.main.loadNibNamed("NXEmailItemView", owner: self, topLevelObjects: &topLevelObjects)) {
            for item in topLevelObjects! {
                let myView = item as? NSView
                if myView != nil {
                    view = myView as! NXEmailItemView;
                }
            }
        }
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.init(colorWithHex: "#D2DDF0", alpha: 1)?.cgColor
        view.layer?.cornerRadius = 4;
    }
    
    class func sizeForTitle(tilte title:String) -> NSSize {
        
        let paragraph = NSMutableParagraphStyle();
        paragraph.lineBreakMode = .byTruncatingTail;
        paragraph.alignment = .center;
        
        let attributes = [NSAttributedString.Key.font:NSFont.systemFont(ofSize: 14), NSAttributedString.Key.paragraphStyle:paragraph];
        
        let attributeStr = NSAttributedString.init(string: title, attributes: attributes);
        
        let size = attributeStr.size();

        return NSSize(width: 24 + size.width + size.height, height: size.height + 8);
    }
    
}
