//
//  NXHomeShareConfigureView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/22.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXHomeShareConfigureViewDelegate: NSObjectProtocol {
    func onShareFinish(files: [NXNXLFile], right: NXRightObligation, emails: [String], comments: String)
    func onShareFailed()
    func closeShareConfigure(files: [NXNXLFile])
    func onTapCancelShareButton()
}

class NXHomeShareConfigureView: NXProgressIndicatorView {
    
    @IBOutlet var fileNameTextView: NSTextView!
    @IBOutlet weak var rightsContainerView: NSView!
    @IBOutlet weak var emailContainerView: NSView!
    @IBOutlet weak var shareBtn: NSButton!
    @IBOutlet weak var commentContainerView: NSView!
    @IBOutlet weak var backgroundView: NSView!
    @IBOutlet weak var titleLbl: NSTextField!
    
    var selectedFile: [NXNXLFile]! {
        didSet {
            DispatchQueue.main.async {
                var nameStr = self.selectedFile.reduce("", { (str, file) -> String in
                    return str + "\n" + file.name
                })
                nameStr.removeFirst()
                nameStr.removeFirst()
                
                self.fileNameTextView.string = nameStr
                self.fileNameTextView.textColor = NSColor.init(colorWithHex: "#2F80ED")
                
                if self.selectedFile.count > 1 {
                    self.titleLbl.stringValue = "Share protected files"
                }
                
                if let recipients = self.selectedFile.first?.recipients {
                    self.emailView?.emailsArray = recipients
                }
            }
        }
    }
    
    var selectedFileReadyForProtectAndShare: [NXSelectedFile]! {
        willSet {
            let urls = newValue.map() { $0.url! }
            if checkFiles(urls: urls) {
                DispatchQueue.main.async {
                    var str = ""
                    for url in urls {
                        str += url.path + "\n"
                    }
                    // Remove last separator.
                    str.removeLast()
                    
                    self.fileNameTextView.string = str
                    self.fileNameTextView.setTextColor(NSColor.init(colorWithHex: "#828282"), range: NSMakeRange(0, str.count) )
                    self.fileNameTextView.font = NSFont.systemFont(ofSize: 10)
                    self.emailView?.emailsArray = [String]()
                   
                }
            }
            
            if urls.count > 1 {
                self.titleLbl.stringValue = "Share protected files"
            }
        }
    }
    
    var sharingFileCount = 0
    var sharedFile = [NXNXLFile]()
    let serialQueue = DispatchQueue(label: "com.skydrm.serial")
    
    var isNeedProtectFirst = false
    
    var right: NXRightObligation? {
        didSet {
            DispatchQueue.main.async {
                self.rightView?.right = self.right
            }
        }
    }

    weak var delegate: NXHomeShareConfigureViewDelegate?
    
    fileprivate var emailView: NXEmailView?
    fileprivate var commentView: NXCommentsView?
    fileprivate var rightView: NXRightViewOnly?
    fileprivate var localFileSize: Int64 = 0
    fileprivate var repositoryfile = NXFileBase()
    fileprivate var gradientLayer: CALayer?
    
    private var filePathId: String?
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let _ = superview else {
            return
        }

        disableBtn()
        
        rightView = NXCommonUtils.createViewFromXib(xibName: "NXRightViewOnly", identifier: "rightViewOnly", frame: nil, superView: rightsContainerView) as? NXRightViewOnly
        
        emailView = NXCommonUtils.createViewFromXib(xibName: "NXEmailView", identifier: "emailView", frame: nil, superView: emailContainerView) as? NXEmailView
        emailView?.delegate = self
        commentView = NXCommonUtils.createViewFromXib(xibName: "NXCommentsView", identifier: "commentsView", frame: nil, superView: commentContainerView) as? NXCommentsView
        commentView?.placeholder = NSLocalizedString("COMMENT_VIEW_SHARE_COMMENT", comment: "")
       
        
        fileNameTextView.isEditable = false
        fileNameTextView.textColor = NSColor.init(colorWithHex: "#2F80ED")
        fileNameTextView.font = NSFont.systemFont(ofSize: 14)
        
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = NSColor.init(colorWithHex: "#E3E3E3")?.cgColor
        backgroundView.layer?.borderWidth = 1
        backgroundView.layer?.borderColor = NSColor(colorWithHex: "#BDBDBD")!.cgColor
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window = self.window else {
            return
        }
        window.styleMask.remove(.resizable)
    }
    
    // Define a closure and Boolean type
    //    typealias EmailFail = (Bool)->Void
    fileprivate var emailFail: ((Bool)->Void)?;
    var isOnShare = false
    
    @IBAction func onShare(_ sender: Any) {
        if let expiry = self.right?.expiry,
            NXClient.isExpiryForever(expiry: expiry) {
            NSAlert.showAlert(withMessage: "EXPIRY_CANNOT_SHARE".localized) { type in
                self.close()
            }
            return
        }
        
        //if emailInpuTextfield have values not added
        if self.emailView?.currentEmailTextFieldItem?.inputTextField.stringValue.count ?? 0 >= 1 {
            isOnShare = true
            emailView?.textFieldIsFirstRespon = false
            self.emailView?.currentEmailTextFieldItem?.inputTextField.keyDownClosure!(.ReturnKey)
            emailFail = { (type) in
                if self.shareBtn.isEnabled  {
                self.shareFile()
                }
            }
        } else {
              self.shareFile()
        }
    }
    
    private func close() {
        if self.selectedFile != nil {
              delegate?.closeShareConfigure(files: self.selectedFile)
            return
        }
        delegate?.onTapCancelShareButton()
    }
    
    @IBAction func onCancel(_ sender: Any) {
        close()
    }
    
    @IBAction func onCloseImage(_ sender: Any) {
        close()
    }
    
    private func reshare() {
        guard
            let emails = emailView?.emailsArray,
            emails.count > 0 else {
                return
        }
        let comment = commentView!.comments
        
        startAnimation()
        
        let group = DispatchGroup()
        for file in selectedFile {
            group.enter()
            NXClient.getCurrentClient().reshare(file: file, newRecipients: emails, comment: comment) { (error) in
                if let error = error {
                    debugPrint(error)
                }
                
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            self.delegate?.onShareFinish(files: self.selectedFile, right: self.right!, emails: emails, comments: comment)
        }
    }
    
    private func shareFile() {
        if isNeedProtectFirst == true {
            let paths = selectedFileReadyForProtectAndShare.map() { $0.url!.path }
            startAnimation()
            protectFile(paths: paths, rights: right, tags: nil) { [weak self] (files,failedFiles) in
                
                // If any file failed, show it.
                if files.count < paths.count {
                    let successedCount = files.count
                    let failedCount = paths.count - files.count
                    NXToastWindow.sharedInstance?.toast("\(successedCount) success, \(failedCount) failed.")
                }
                
                if files.count > 0 {
                    guard
                        let emails = self?.emailView?.emailsArray,
                        emails.count > 0 else {
                            return
                    }
                    let comment = self?.commentView!.comments
                    
                    let group = DispatchGroup()
                    for file in files {
                        group.enter()
                        NXClient.getCurrentClient().reshare(file: file, newRecipients: emails, comment: comment!) { (error) in
                            if let error = error {
                                debugPrint(error)
                            }
                            
                            group.leave()
                        }
                    }
                    
                    group.notify(queue: DispatchQueue.main) {
                        self?.stopAnimation()
                        self?.delegate?.onShareFinish(files: files, right: self!.right!, emails: emails, comments: comment!)
                    }
                }
                
                if failedFiles.count > 0 {
                    //protect failed
                    self?.stopAnimation()
                    
                    var failedFileArray = [String]()
                    for path in failedFiles {
                        let fileName = path.components(separatedBy: NSCharacterSet(charactersIn: "/") as CharacterSet).last
                        failedFileArray.append(fileName!)
                    }
                    
                    if failedFileArray.count > 0{
                        var display = String()
                        display.append(String(format: "\n"))
                        for temp in failedFileArray{
                            display.append(temp)
                            display.append(String(format: "\n"))
                        }
                        
                        let message = String(format: NSLocalizedString("FILE_OPERATION_PROTECT_FAILED_FILE", comment: ""), display)
                        
                        NSAlert.showAlert(withMessage: message, dismissClosure: {_ in
                            DispatchQueue.main.async {
                            }
                        })
                        return
                    }
                }
            }
            return
        }
            reshare()
    }
    
    func getGradientLayer() -> CALayer {
        let startColor = NSColor(colorWithHex: "#6AB3FA")!
        let endColor = NSColor(colorWithHex: "#087FFF")!
        // Fix Bug: Share button bigger than cancel button.
        let rect = CGRect(origin: CGPoint(x: 0, y: 2), size: CGSize(width: shareBtn.bounds.width, height: shareBtn.bounds.height - 5))
        let layer = NXCommonUtils.createLinearGradientLayer(frame: rect, start: startColor, end: endColor)
        layer.cornerRadius = 5
        return layer
    }
    
    
    fileprivate func enableBtn() {
        if shareBtn.isEnabled == true {
            return
        }
        
        shareBtn.isEnabled = true
        shareBtn.wantsLayer = true
        shareBtn.isBordered = false
        if gradientLayer == nil {
            gradientLayer = getGradientLayer()
        }
        shareBtn.layer?.addSublayer(gradientLayer ?? CALayer())
        let titleAttr = NSMutableAttributedString(attributedString: shareBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, shareBtn.title.count))
        shareBtn.attributedTitle = titleAttr
    }
    
    fileprivate func disableBtn() {
        if shareBtn.isEnabled == false {
            return
        }
        shareBtn.isEnabled = false
        shareBtn.isBordered = true
        shareBtn.wantsLayer = true
        gradientLayer?.removeFromSuperlayer()
        let titleAttr = NSMutableAttributedString(attributedString: shareBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.black], range: NSMakeRange(0, shareBtn.title.count))
        shareBtn.attributedTitle = titleAttr
    }
    
    private func checkFiles(urls: [URL]) -> Bool {
        var result = true
        
        startAnimation()
        for url in urls {
            let isNXL = NXClient.isNXLFile(path: url.path)
            if isNXL == true {
                result = false
                break
            }
        }
        
        // Show alert.
        if result == false {
            let message = NSLocalizedString("FILE_OPERATION_PROTECT_FAILED", comment: "")
            NSAlert.showAlert(withMessage: message, informativeText: "", dismissClosure: { _ in
//                self.onProtectFailed()
            })
        }
        stopAnimation()
        return result
    }
    
    private func protectFile(paths: [String], rights: NXRightObligation?, tags: [String: [String]]?, completion: @escaping ([NXNXLFile],[String]) -> ()) {
        var result = [NXNXLFile]()
        var protectFailedFile = [String]()
        result.reserveCapacity(paths.count)
        let names = paths.map { path -> String in
            let name = URL(fileURLWithPath: path).lastPathComponent
            return name
            }.filter { (name) -> Bool in
                return  name.contains("*") || name.contains("?") || name.contains("<") || name.contains("|") || name.contains(">") || name.contains(":")
        }
        
        if names.count > 0 {
            self.stopAnimation()
            NSAlert.showAlert(withMessage: #"We don't support to protect a file, which the file name contains any of the following characters: \ / : * ? < > |"#)
            return
        }
        
        let group = DispatchGroup()
        for path in paths {
            group.enter()
            NXClient.getCurrentClient().protectFile(type: .myVaultShared, path: path, right: (rights != nil ? rights : nil), tags: (rights != nil ? nil : tags), parentFile: nil) { (file, error) in
                if let file = file {
                    
                    NotificationCenter.default.post(name: NXNotification.myVaultProtected.notificationName,object: file)
                    let nxFile = NXSyncFile(file: file as NXFileBase)
                    let status = NXSyncFileStatus()
                    status.status = .waiting
                    nxFile.syncStatus = status
                    nxFile.syncStatus?.status = .waiting
                    NotificationCenter.post(notification: NXNotification.waitingUpload, object: nxFile)
                    result.append(file)
                    
                } else {
                    protectFailedFile.append(path)
                    debugPrint(error as Any)
                }
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            completion(result,protectFailedFile)
        }
    }
}

extension NXHomeShareConfigureView: NXEmailViewDelegate {
    
     func checkInputTextValidity()
     {
        guard let emails = emailView?.emailsArray else {
            return
        }
        if emails.count == 0 {
            return
        }
     
        if emailView?.isValidate(email: emails.last!) == false {
            NSAlert.showAlert(withMessage: NSLocalizedString("HOME_SHARE_INVALID_EMAIL", comment: ""))
            return
        }
     }
    
    func emailViewTextFieldChanged() {
        guard let emails = emailView?.emailsArray else {
            return
        }
        if emails.count == 0 {
            disableBtn()
            isOnShare = false
            return
        }
        for email in emails {
            if emailView?.isValidate(email: email) == false {
                disableBtn()
                //if email is error set
               // emailView?.textFieldIsFirstRespon = false
                isOnShare = false
                return
            }
        }
        enableBtn()
        // if shareBtn is enable and it came in by clicking the shareFile button
        if isOnShare {
            emailFail?(true)
        }
        isOnShare = false
    }
}
