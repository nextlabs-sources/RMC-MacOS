//
//  NXEmailView.swift
//  macexample
//
//  Created by nextlabs on 2/6/17.
//  Copyright © 2017 zhuimengfuyun. All rights reserved.
//

import Cocoa

class NXEmailView: NSView {
    
    let kMargin:CGFloat = 8;
    
    var emailsArray = [String]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    var currentEmailTextFieldItem:NXEmailTextFieldItem?
    
    weak var delegate : NXEmailViewDelegate?
    @IBOutlet weak var scrollView: NSScrollView!
    
    @IBOutlet weak var collectionView: NSCollectionView!
    
    var vaildEmailsArray: [String] {
        let emails = NSMutableArray()
        for item in emailsArray {
            if isValidate(email: item) {
                emails.add(item);
            }
        }
        return NSArray(array: emails) as! [String];
    }
    var isEnable = true {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var textFieldIsFirstRespon = true
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidMoveToWindow() {
        let t1 = DispatchTime.now() + 0.1
        let t2 = DispatchTime.now() + 0.4
        DispatchQueue.main.asyncAfter(deadline: t1) {
            self.collectionView.reloadData()
        }
        DispatchQueue.main.asyncAfter(deadline: t2) {
            self.currentEmailTextFieldItem?.inputTextField.becomeFirstResponder()
        }
    }
    
    // add emailItem
    @objc func addEmailItemAction() {
        textFieldIsFirstRespon = false
        self.currentEmailTextFieldItem?.inputTextField.keyDownClosure?(.ReturnKey)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib();
        collectionView.register(NXEmailItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier.init("collectionViewItem"))
        collectionView.register(NXEmailTextFieldItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier.init("collectionViewInputItem"))
        NotificationCenter.add(self, selector: #selector(addEmailItemAction), notification:.addEmailItem )
    }
    
    public func isValidate(email:String)-> Bool {
        
        if email.utf8.count <= 0 {
            return false;
        }
        let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let firstMatch = dataDetector?.firstMatch(in: email, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSRange(location: 0, length: email.count))
        return (firstMatch?.range.location != NSNotFound && firstMatch?.url?.scheme == "mailto")
    }
    
    public func clear() {
        emailsArray.removeAll()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    func scrollToBottom() -> Bool {
        guard let documentView = scrollView.documentView else {
            return false
        }
        let newScrollOrigin: NSPoint
        if documentView.isFlipped == true {
            newScrollOrigin = NSPoint(x: 0, y: documentView.frame.maxY - scrollView.contentView.bounds.height)
        } else {
            newScrollOrigin = NSPoint(x: 0, y: 0)
        }
        
        documentView.scroll(newScrollOrigin)
        
        return true
    }
    
    override func mouseDown(with event: NSEvent) {
        if (self.window?.firstResponder as? NSTextView)?.delegate === currentEmailTextFieldItem?.inputTextField {
            currentEmailTextFieldItem?.inputTextField.keyDownClosure!(.ReturnKey)
        } else {
            currentEmailTextFieldItem?.inputTextField.becomeFirstResponder()
        }
    }
}

extension NXEmailView : NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return isEnable ? (emailsArray.count) + 1 : emailsArray.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        if indexPath.item == emailsArray.count  {
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "collectionViewInputItem"), for: indexPath) as! NXEmailTextFieldItem;
            currentEmailTextFieldItem = item
            item.keydownClosure = { (type) in
                switch type {
                case .ReturnKey:
                    if item.inputTextField.stringValue.utf8.count > 0
                    {
                        if self.emailsArray.count >= 1  {
                            for emailItem in self.emailsArray{
                                if emailItem.localizedCaseInsensitiveContains(item.inputTextField.stringValue) {
                                    collectionView.reloadData();
                                    item.inputTextField.stringValue = ""
                                    return
                                }
                            }
                            
                        }
                        
                        let inputTextField:String = item.inputTextField.stringValue
                        let trimmingEmails = inputTextField
                            .replacingOccurrences(
                                of: "\\s+",
                                with: " ",
                                options: .regularExpression
                            )
                            .trimmingCharacters(in: .whitespaces)
                            .components(separatedBy: " ")
                        
                        let spliter = CharacterSet(charactersIn: ",;")
                        var hasServeralValues = false
                        for trimmingEmail in trimmingEmails {
                            let splitEmails = trimmingEmail.components(separatedBy: spliter)
                            if splitEmails.count > 1{
                                hasServeralValues = true
                            }
                        self.emailsArray.append(contentsOf: splitEmails.filter{$0 != ""})
                        }
                        self.emailsArray = self.emailsArray.map({$0.lowercased()})
                        if trimmingEmails.count > 1 || hasServeralValues == true{
                            if self.emailsArray.count > 1 {
                                var tempArraySet = Set<String>()
                                for emailStr in self.emailsArray {
                                    tempArraySet.insert(emailStr.lowercased())
                                }
                                
                                self.emailsArray.removeAll()
                                for item in tempArraySet {
                                    if item != "" {
                                        self.emailsArray.append(item)
                                    }
                                }
                            }
                        }
                        
                        collectionView.reloadData()
                        item.inputTextField.stringValue = ""
                        
                        let t = DispatchTime.now() + 0.2
                        DispatchQueue.main.asyncAfter(deadline: t) {
                            _ = self.scrollToBottom()
                        }
                         self.delegate?.checkInputTextValidity()
                        
                        let t1 = DispatchTime.now() + 0.001
                        DispatchQueue.main.asyncAfter(deadline: t1) {
                            collectionView.reloadData()
                        }
                        
                    }
                case .SpaceKey:
                    if item.inputTextField.stringValue.utf8.count > 0 {
                        self.emailsArray.append(item.inputTextField.stringValue)
                        collectionView.reloadData()
                        item.inputTextField.stringValue = ""
                    }
                case .DeleteKey:
                    if self.emailsArray.count > 0 {
                        self.emailsArray.removeLast()
                        collectionView .reloadData()
                    }
                    
                    let t = DispatchTime.now() + 0.2
                    DispatchQueue.main.asyncAfter(deadline: t) {
                        collectionView.reloadData()
                    }
                    
                case .BackSpaceKey:
                    if self.emailsArray.count > 0 {
                        self.emailsArray.removeLast()
                        collectionView .reloadData()
                    }
                    
                    let t1 = DispatchTime.now() + 0.2
                    DispatchQueue.main.asyncAfter(deadline: t1) {
                        collectionView.reloadData()
                    }
                }
            }
             self.delegate?.emailViewTextFieldChanged()
            if textFieldIsFirstRespon {
                item.inputTextField.becomeFirstResponder()
            }
            textFieldIsFirstRespon = true
            _ = self.scrollToBottom()
            return item;
        } else {
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier.init("collectionViewItem"), for: indexPath) as! NXEmailItem
            let view = item.view as!NXEmailItemView
                view.isEnable = self.isEnable
                view.deleteClosure = {
                self.emailsArray.remove(at: indexPath.item)
                     collectionView.reloadData()
                    
                    let t1 = DispatchTime.now() + 0.01
                    DispatchQueue.main.asyncAfter(deadline: t1) {
                        collectionView.reloadData()
                    }
                }
            
            let emailText = emailsArray[indexPath.item]
            if isValidate(email: emailText) {
                let underlineAttribute = [NSAttributedString.Key.underlineStyle:0,NSFontDescriptor.AttributeName.name: NSFont.systemFont(ofSize:12)] as! [NSAttributedString.Key : Any]
                let underlineAttributedString = NSAttributedString(string: emailText, attributes: underlineAttribute)
                view.titleLabel.attributedStringValue = underlineAttributedString;
            } else {
                let underlineAttribute = [NSAttributedString.Key.underlineStyle:1, NSAttributedString.Key.underlineColor:NSColor.red, NSFontDescriptor.AttributeName.name: NSFont.systemFont(ofSize:14)] as! [NSAttributedString.Key : Any]
                let underlineAttributedString = NSAttributedString(string: emailText, attributes: underlineAttribute)
                
                view.titleLabel.attributedStringValue = underlineAttributedString
            }
            return item
        }
    }
}

extension NXEmailView : NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        if indexPath.item == emailsArray.count {
            return NSSize(width:collectionView.bounds.width/2, height:25)
        } else {
            let title = emailsArray[indexPath.item];
            let size = NXEmailItem.sizeForTitle(tilte:title);
            return NSSize(width: size.width, height: size.height)
        }
    }
}

extension NXEmailView : NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        //TODO
    }
}
