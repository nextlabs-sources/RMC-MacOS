//
//  NXWatermarkEditVC.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 23/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXWatermarkEditVCDelegate: NSObjectProtocol {
    func onSelect(watermark: NXFileWatermark)
    func onClose()
}

class NXWatermarkEditVC: NSViewController {
    @IBOutlet weak var warningLabel: NSTextField!
    @IBOutlet var textView: NXTextView!
    @IBOutlet weak var presetLabel: NSTextField!
    @IBOutlet weak var indicatorLabel: NSTextField!
    @IBOutlet weak var cancelBtn: NSButton!
    @IBOutlet weak var selectBtn: NSButton!
    @IBOutlet weak var tagAreaView: NSView!
    
    fileprivate struct Constant {
        static let minMargin: CGFloat = 10
        static let MAX_CHARS_NUM: Int = 50
    }
    
    private var _unusedTags = [NXWatermarkTag]()
    fileprivate func setAndDisplayUnusedTags(tags: [NXWatermarkTag]) {
        // Check is unused tags changed.
        if _unusedTags.count == tags.count {
            let oldSet = Set(_unusedTags)
            let newSet = Set(tags)
            let union = oldSet.union(newSet)
            if union.count == oldSet.count {
                return
            }
        }
            
        self._unusedTags = tags.sorted() { $0.rawValue < $1.rawValue }
        displayUnusedTags()
    }
    
    weak var delegate: NXWatermarkEditVCDelegate?
    
    private var _watermark: NXFileWatermark!
    // Input
    var watermark: NXFileWatermark! {
        get {
            return _watermark
        }
        set {
            _watermark = newValue
            updateUIWith(description: watermark.text)
        }
    }
    
    deinit {
        print("release")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        
        initView()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        view.window?.title = NXConstant.kTitle
        self.view.window?.styleMask.remove(.resizable)
    }
    
    func initView() {
        initTagArea()
        
        textView.delegate = self
        textView.eventDelegate = self
        if let font = NSFont(name: "Courier New", size: 20) {
            textView.typingAttributes = [NSAttributedString.Key.font: font]
        }
        
        warningLabel.isHidden = true
    }
    
    func initTagArea() {
        let tags: [NXWatermarkTag] = [.Date, .Time, .Email]
        for _ in 0 ..< tags.count {
            let button = NXMouseEventButton()
            button.isBordered = false
            button.imageScaling = .scaleAxesIndependently
            button.action = #selector(onTagClick)
            button.target = self
            button.isHidden = true
            
            self.tagAreaView.addSubview(button)
        }
        
        setAndDisplayUnusedTags(tags: tags)
    }
    
    // MARK: Edit
    
    // Init textview with watermark.
    fileprivate func updateUIWith(description: String) {
        
        // Find all tag positions.
        let allTags = NXWatermarkTag.allCases
        var tagPositions = [(Range<String.Index>, NXWatermarkTag)]()
        for tag in allTags {
            var searchIndex = description.startIndex
            while searchIndex < description.endIndex {
                if let range = description.range(of: tag.rmsShortcut(), options: .literal, range: searchIndex ..< description.endIndex),
                    !range.isEmpty {
                    tagPositions.append((range, tag))
                    
                    searchIndex = range.upperBound
                } else {
                    break
                }
            }
        }
        
        // Sort the array for the order.
        tagPositions.sort() { $0.0.lowerBound < $1.0.lowerBound }
        
        // Insert text.
        var text = description
        for i in 0..<tagPositions.count {
            text.replaceSubrange(tagPositions[tagPositions.count - 1 - i].0, with: "")
        }
        insertTextInTextView(text: text, at: 0)
        
        // Insert tags.
        var offset = 0
        for tagPosition in tagPositions {
            let at = tagPosition.0.lowerBound.utf16Offset(in: description) - offset
            insertTagInTextView(tag: tagPosition.1, at: at)
            offset += tagPosition.1.charaterNumber() - 1
        }
        
        // Update unused tags.
        var usedTags = Set<NXWatermarkTag>()
        for tagPosition in tagPositions {
            usedTags.insert(tagPosition.1)
        }
        delUnusedTag(tags: Array(usedTags))
        
        // Update indicator.
        updateIndicator()
    }
    
    @objc func onTagClick(_ sender: Any) {
        guard
            let button = sender as? NSButton,
            let str = button.identifier?.rawValue,
            let tagID = Int(str) else {
                return
        }
        
        guard
            let tag = NXWatermarkTag.init(rawValue: tagID),
            let range = textView.selectedRanges.first as? NSRange else {
                return
        }
        
        insertTagInTextView(tag: tag, at: range.location)
        delUnusedTag(tags: [tag])
        
        updateIndicator()
    }
    
    @IBAction func onLbClick(_ sender: Any) {
        guard let range = textView.selectedRanges.first as? NSRange else {
            return
        }
        insertTagInTextView(tag: .LineBreak, at: range.location)
        updateIndicator()
    }
    
    // MARK: Action.
    
    @IBAction func onCancel(_ sender: Any) {
        delegate?.onClose()
        self.presentingViewController?.dismiss(self)
    }
    
    @IBAction func onSelect(_ sender: Any) {
        // Get current watermark.
        let watermarkDescription = parseTextView()
        let watermark = NXFileWatermark(text: watermarkDescription)
        self._watermark = watermark
        
        delegate?.onSelect(watermark: watermark)
        self.presentingViewController?.dismiss(self)
    }
    
    // MARK: Internal methods.
    
    private func displayUnusedTags() {
        guard let buttons = self.tagAreaView.subviews as? [NSButton] else {
            return
        }
        
        var tags = self._unusedTags
        var x: CGFloat = 0
        for button in buttons {
            let tag = tags.first
            if let tag = tag {
                let imageSize = tag.getImage().size
                button.image = tag.getImage()
                button.isHidden = false
                button.frame = NSMakeRect(x + Constant.minMargin, Constant.minMargin, imageSize.width, imageSize.height)
                button.identifier = NSUserInterfaceItemIdentifier(rawValue: "\(tag.rawValue)")
                
                x = button.frame.maxX
                tags.remove(at: 0)
            } else {
                button.isHidden = true
                continue
            }
            
        }
    }
    
    fileprivate func insertTextInTextView(text: String, at: Int) {
        let textAttr = NSAttributedString(string: text)
        let textMutableAttr = NSMutableAttributedString(attributedString: textAttr)
        textMutableAttr.addAttribute(NSAttributedString.Key.font, value: NSFont(name: "Courier New", size: 20) ?? NSFont(), range: NSMakeRange(0, textMutableAttr.length))
        insert(on: self.textView.textStorage!, attrString: textMutableAttr, at: at)
    }

    fileprivate func insertTagInTextView(tag: NXWatermarkTag, at: Int) {
        let cell = NSTextAttachmentCell(imageCell: tag.getImage())
        let attachment = NSTextAttachment(data: nil, ofType: nil)
        attachment.attachmentCell = cell
        let str = NSAttributedString(attachment: attachment)
        let mutableStr = NSMutableAttributedString(attributedString: str)
        mutableStr.addAttribute(NSAttributedString.Key.cursor, value: NSCursor.pointingHand, range: NSMakeRange(0, 1))
        mutableStr.addAttribute(NSAttributedString.Key.font, value: NSFont(name: "Courier New", size: 20) ?? NSFont(), range: NSMakeRange(0, 1))
        mutableStr.addAttribute(NSAttributedString.Key(rawValue: tag.getAttributeKey()), value: 1, range: NSMakeRange(0, 1))
        
        insert(on: self.textView.textStorage!, attrString: mutableStr, at: at)
    }
    
    fileprivate func addUnusedTag(tags: [NXWatermarkTag]) {
        var unusedTags = self._unusedTags
        for tag in tags {
            if unusedTags.firstIndex(of: tag) == nil {
                unusedTags.append(tag)
            }
        }
        
        setAndDisplayUnusedTags(tags: unusedTags)
    }
    
    fileprivate func delUnusedTag(tags: [NXWatermarkTag]) {
        var unusedTags = self._unusedTags
        for tag in tags {
            if let index = unusedTags.firstIndex(of: tag) {
                unusedTags.remove(at: index)
            }
        }
        setAndDisplayUnusedTags(tags: unusedTags)
    }
    
    fileprivate func updateIndicator() {
        let num = charactersInTextView()
        let left = Constant.MAX_CHARS_NUM - num
        indicatorLabel.stringValue = "\(left) / \(Constant.MAX_CHARS_NUM)"
        if left < 0 {
            indicatorLabel.textColor = NSColor.red
            selectBtn.isEnabled = false
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("WATERMARK_EXCEED_MAXIMUM", comment: ""))
        }
        else if left == Constant.MAX_CHARS_NUM {
            selectBtn.isEnabled = false
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("WATERMARK_EMPTY", comment: ""))
            indicatorLabel.textColor = NSColor.black
        }
        else {
            selectBtn.isEnabled = true
            warningLabel.isHidden = true
            indicatorLabel.textColor = NSColor.black
        }
    }
    
    func checkTextContainTag() {
        var isContain = false
        
        let description = self.textView.string
        let allTags = NXWatermarkTag.allCases
        for tag in allTags {
            if let range = description.range(of: tag.rmsShortcut(), options: .literal, range: description.startIndex ..< description.endIndex),
                !range.isEmpty {
                isContain = true
                break
            }
        }
        
        if isContain {
            indicatorLabel.textColor = NSColor.red
            selectBtn.isEnabled = false
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("WATERMARK_TEXT_INCLUDE_TAG", comment: ""))
        }
    }
    
    fileprivate func charactersInTextView() -> Int {
        if let textStorage = textView.textStorage {
            var len: Int = textStorage.characters.count
            textStorage.enumerateAttributes(in: NSMakeRange(0, textStorage.string.count), options: .longestEffectiveRangeNotRequired, using: {attrs, range, stop in
                if let tag = NXWatermarkTag.create(keys:attrs.toTypingAttributes()){
                    len += tag.charaterNumber()
                    len -= 1
                }
            })
            return len
        }
        return 0
    }
    
    fileprivate func parseTextView() -> String {
        var description = ""
        if let textStorage = textView.textStorage {
            textStorage.enumerateAttributes(in: NSMakeRange(0, textStorage.string.count), options: .longestEffectiveRangeNotRequired, using: {attrs, range, stop in
                if let tag = NXWatermarkTag.create(keys:attrs.toTypingAttributes()) {
                    textStorage.replaceCharacters(in: range, with: tag.rmsShortcut())
                }
            })
            description = textStorage.string
        }
        return description
    }
    
    func updateUnusedTags() {
        var unusedTags = Set(NXWatermarkTag.allCases)
        unusedTags.remove(.LineBreak)
        
        guard let textStorage = textView.textStorage else {
            return
        }
        
        // Check used tags.
        textStorage.enumerateAttributes(in: NSMakeRange(0, textStorage.string.count), options: .longestEffectiveRangeNotRequired) {
            attrs, range, stop in
            if let tag = NXWatermarkTag.create(keys:attrs.toTypingAttributes()) {
                unusedTags.remove(tag)
            }
        }
        
        setAndDisplayUnusedTags(tags: Array(unusedTags))
    }
    
    fileprivate func getTagString(tag: NXWatermarkTag) -> NSAttributedString {
        let cell = NSTextAttachmentCell(imageCell: tag.getImage())
        let attachment = NSTextAttachment(data: nil, ofType: nil)
        attachment.attachmentCell = cell
        let str = NSAttributedString(attachment: attachment)
        let mutableStr = NSMutableAttributedString(attributedString: str)
        mutableStr.addAttribute(NSAttributedString.Key.cursor, value: NSCursor.pointingHand, range: NSMakeRange(0, 1))
        mutableStr.addAttribute(NSAttributedString.Key.font, value: NSFont(name: "Courier New", size: 20) ?? NSFont(), range: NSMakeRange(0, 1))
        mutableStr.addAttribute(NSAttributedString.Key(rawValue: tag.getAttributeKey()), value: 1, range: NSMakeRange(0, 1))
        
        return mutableStr
    }
    
    // MARK: TextStorage methods.
    
    func insert(on: NSTextStorage, attrString: NSAttributedString, at loc: Int) {
        on.beginEditing()
        on.insert(attrString, at: loc)
        on.endEditing()
    }
    
    func deleteCharacters(on: NSTextStorage, in range: NSRange) {
        on.beginEditing()
        on.deleteCharacters(in: range)
        on.endEditing()
    }

    func replaceCharacters(on: NSTextStorage, in range: NSRange, with str: NSAttributedString) {
        on.beginEditing()
        on.replaceCharacters(in: range, with: str)
        on.endEditing()
    }
}

extension NXWatermarkEditVC: NSTextViewDelegate {
    
    // Remove the image if clicked.
    func textView(_ textView: NSTextView, clickedOn cell: NSTextAttachmentCellProtocol, in cellFrame: NSRect, at charIndex: Int) {
        
        guard let mutableStr = self.textView.textStorage else {
            return
        }
        
        let attributes = mutableStr.attributes(at: charIndex, effectiveRange: nil)
        if let tag = NXWatermarkTag.create(keys:attributes.toTypingAttributes()) {
            deleteCharacters(on: mutableStr, in: NSMakeRange(charIndex, 1))
            
            if tag != .LineBreak {
                addUnusedTag(tags: [tag])
            }
            
            updateIndicator()
        }
        
    }
    
    func textDidChange(_ notification: Notification) {
        print("textDidChange")
        
        updateIndicator()
        checkTextContainTag()
        
        updateUnusedTags()
    }
}

extension NXWatermarkEditVC: NXTextViewDelegate {
     func onKeyEnter(range: NSRange) -> Bool {
        guard let textStorage = textView.textStorage else {
            return false
        }
        
        let lineBreakStr = getTagString(tag: .LineBreak)
        replaceCharacters(on: textStorage, in: range, with: lineBreakStr)
        updateIndicator()
        
        return true
     }
}

extension NXWatermarkEditVC: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        delegate?.onClose()
    }
    
}
