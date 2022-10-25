//
//  NXCommentsView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 11/07/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXCommentsViewDelegate: NSObjectProtocol {
    func textDidChange(with view: NXCommentsView)
}
extension NXCommentsViewDelegate {
    func textDidChange(with view: NXCommentsView){}
}

class NXCommentsView: NSView {
    
    @IBOutlet var text: NXPlaceholderTextView!
    @IBOutlet weak var indicatorLabel: NSTextField!
    
    // Input and Output.
    var comments: String {
        get {
            return _comments
        }
        set {
            _comments = newValue
        }
    }
    
    fileprivate var _comments = "" {
        didSet {
            DispatchQueue.main.async {
                if self.comments.count > self.maxcount {
                    let index = self.comments.index(self.comments.startIndex, offsetBy: self.maxcount)
                    let subStr = String(self.comments[..<index])
                    self.text.string = subStr
                    self._comments = subStr
                    self.indicatorLabel.stringValue = "0 / \(self.maxcount)"
                    self.text.setSelectedRange(NSMakeRange(subStr.count, 0))
                }
                else {
                    self.text.string = self.comments
                    self.indicatorLabel.stringValue = "\(self.maxcount - self.comments.count) / \(self.maxcount)"
                }
            }
        }
    }
    
    
    var placeholder = "" {
        didSet {
            text.placeHolderString = placeholder
        }
    }
    var isEnable = true {
        didSet {
            text.isEditable = isEnable
        }
    }
    weak var delegate: NXCommentsViewDelegate?
    
    private var _maxCount: Int = 250
    var maxcount: Int {
        get {
            return _maxCount
        }
        set {
            _maxCount = newValue
            indicatorLabel.stringValue = "\(newValue) / \(newValue)"
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if newWindow != nil {
            indicatorLabel.stringValue = "\(maxcount) / \(maxcount)"
        }
    }
}

extension NXCommentsView: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        if text.string != comments {
            
            let textStr = text.string
             _comments = textStr
        }
        
        delegate?.textDidChange(with: self)
    }
    
    func textDidBeginEditing(_ notification: Notification) {
        NotificationCenter.post(notification: .addEmailItem, object: nil, userInfo: nil)
    }

}
