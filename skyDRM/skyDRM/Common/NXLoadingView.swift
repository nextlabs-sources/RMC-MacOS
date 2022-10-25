//
//  LoadingView.swift
//  TestLoadingView
//
//  Created by Paul (Qian) Chen on 8/22/19.
//  Copyright © 2019 Paul (Qian) Chen. All rights reserved.
//

import Cocoa

class NXLoadingView: NSView {
    
    // MARK: Custom properties.
    var alpha: CGFloat {
        get {
            return self.alphaValue
        }
        set {
            self.alphaValue = newValue
        }
    }
    
    struct Constant {
        static let viewLength: CGFloat = 100
        static let indicatorLength: CGFloat = 20
    }
    
    static let sharedInstance = NXLoadingView()
    private override init(frame frameRect: NSRect) { super.init(frame: frameRect) }
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private convenience init() {
        let defaultRect = NSRect(x: 0, y: 0, width: Constant.viewLength, height: Constant.viewLength)
        self.init(frame: defaultRect)
        
        self.autoresizingMask = [.minXMargin, .minYMargin, .width, .height]
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.gray.cgColor
        self.alphaValue = 0.5
    
    }
    
    private lazy var indicator: NSProgressIndicator = {
        let defaultRect = NSRect(x: 0, y: 0, width: Constant.indicatorLength, height: Constant.indicatorLength)
        let view = NSProgressIndicator(frame: defaultRect)
        view.style = .spinning
        
        self.addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        let c1 = view.widthAnchor.constraint(equalToConstant: Constant.indicatorLength)
        let c2 = view.heightAnchor.constraint(equalToConstant: Constant.indicatorLength)
        let c3 = view.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        let c4 = view.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        NSLayoutConstraint.activate([c1, c2, c3, c4])

        return view
    }()
    
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        if let superView = newSuperview {
            self.frame = superView.frame
            indicator.startAnimation(nil)
            
        } else {
            indicator.stopAnimation(nil)
        }
    }
    
}
