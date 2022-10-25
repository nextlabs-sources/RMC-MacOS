//
//  NXImageLabel.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 04/07/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa

class NXImageLabel: NSView {
    private struct Constant {
        static let constraint_ImageTrailingLabelLeading: CGFloat = 2
    }
    
    // Views.
    private let imageView = NSImageView()
    private let label = NSTextField(labelWithString: "")
    
    // Content.
    var image: NSImage? {
        didSet {
            updateLayout()
        }
    }
    
    var stringValue = "" {
        didSet {
            label.stringValue = stringValue
        }
    }
    
    // Other property.
    lazy var imageSize = CGSize.init(width: self.bounds.height, height: self.bounds.height)
    
    // FIXME: For easy use.
    override var tag: Int {
        get {
            return 100
        }
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        guard let _ = self.window else {
            return
        }
        
        self.addSubview(imageView)
        self.addSubview(label)
        label.drawsBackground = true
        updateLayout()
    }
    
    func updateLayout() {
        // ImageView.
        if let image = image {
            imageView.image = image
            imageView.isHidden = false
            
            let imageViewX: CGFloat = 0
            let imageViewY = (self.bounds.height - imageSize.height)/2
            imageView.frame = CGRect.init(origin: CGPoint.init(x: imageViewX, y: imageViewY), size: imageSize)
        } else {
            imageView.isHidden = true
        }
        
        // Label.
        label.stringValue = stringValue
        let labelX = (image != nil) ? (imageSize.width + Constant.constraint_ImageTrailingLabelLeading) : CGFloat(0)
        let labelY = (self.bounds.height - label.bounds.height)/2
        let labelWidth = self.bounds.width - labelX
        label.frame = CGRect.init(x: labelX, y: labelY, width: labelWidth, height: label.bounds.height)
    }
    
}
