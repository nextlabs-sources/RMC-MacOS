//
//  NXFileSharingManageViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 16/05/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXFileSharingManageViewControllerDelegate: NSObjectProtocol {
    func close(with file: NXNXLFile)
    func back(with file: NXNXLFile)
}

class NXFileSharingManageViewController: NSViewController {
    
    fileprivate struct Constant {
        static let collectionViewItemIdentifier = "NXFileSharingManageViewItem"
        static let itemHeight: CGFloat = 54
        static let standardInterval: CGFloat = 8
    }
    
    // Input
    var file: NXNXLFile!
    
    // View
    @IBOutlet weak var fileNameTextField: NSTextField!
    @IBOutlet weak var sharedCollection: NSCollectionView!
    @IBOutlet weak var emailContainerView: NSView!
    @IBOutlet weak var commentContainerView: NSView!
    @IBOutlet weak var updateBtn: NSButton!
    @IBOutlet weak var cancelBtn: NSButton!
    
    var emailView: NXEmailView!
    var waitingView: NXWaitingView?
    fileprivate var commentView: NXCommentsView!
    
    fileprivate var downloadOrUploadId: Int? = nil
    
    // Delegate
    weak var delegate: NXFileSharingManageViewControllerDelegate?
    
    // Data
    var recipients = [String]()
    var recipientChange: (adds: [String], removes: [String]) = ([String](), [String]())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        initView()
        initData()
    }
    
    override func viewWillDisappear() {
        if downloadOrUploadId != nil {
            DownloadUploadMgr.shared.cancel(id: downloadOrUploadId!)
        }
    }
    
    private func initData() {
        if let recipients = file.recipients {
            self.recipients = recipients
        }
    }
    
    private func initView() {
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        
        initControl()
        settingCollectionViewLayout()
        createWaitingView()
    }
    
    private func initControl() {
        fileNameTextField.stringValue = file.name
        
        emailView = NXCommonUtils.createViewFromXib(xibName: "NXEmailView", identifier: "emailView", frame:emailContainerView.bounds, superView: emailContainerView) as? NXEmailView
        
        commentView = NXCommonUtils.createViewFromXib(xibName: "NXCommentsView", identifier: "commentsView", frame: nil, superView: commentContainerView) as? NXCommentsView
        commentView.placeholder = NSLocalizedString("COMMENT_VIEW_SHARE_COMMENT", comment: "")
        let centerStyle = NSMutableParagraphStyle()
        centerStyle.alignment = .center
    
    }
    
    private func createWaitingView() {
        waitingView = NXCommonUtils.createWaitingView(superView: self.view)
        waitingView?.isHidden = true
    }
    
    private func settingCollectionViewLayout() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: (sharedCollection.bounds.width - 5 * Constant.standardInterval)/2, height: Constant.itemHeight)
        flowLayout.sectionInset = NSEdgeInsets(top: Constant.standardInterval, left: Constant.standardInterval, bottom: Constant.standardInterval, right: Constant.standardInterval)
        flowLayout.minimumInteritemSpacing = Constant.standardInterval
        flowLayout.minimumLineSpacing = Constant.standardInterval
        sharedCollection.collectionViewLayout = flowLayout
    }
    
    @IBAction func close(_ sender: Any) {
        close()
    }
    
    @IBAction func back(_ sender: Any) {
        back()
    }
    
    @IBAction func update(_ sender: Any) {
        
        if !checkEmail() {
            return
        }
        
        recipientChange.adds.append(contentsOf: emailView.emailsArray)
        
        updateShareFile()
        
    }
    
    private func updateShareFile() {
        
        guard let duid = file.getNXLID() else {
            print("cannot get duid")
            return
        }
        
        let (_, adds, deletes) = NXCommonUtils.diffChanges(olds: recipientChange.removes, news: recipientChange.adds)
        
        waitingView?.isHidden = false
        NXLoginUser.sharedInstance.nxlClient?.updateSharedFileRecipients(byDUID: duid, newRecipients: adds, removeRecipients: deletes, comment: commentView.comments) { error in
            
            DispatchQueue.main.async {
                self.waitingView?.isHidden = true
            }
            
            if error != nil {
                Swift.print("\(String(describing: error))")
                
                DispatchQueue.main.async {
                    if (error as NSError?)?.code == 2012 {
                        NXToastWindow.sharedInstance?.toast(NSLocalizedString("UPDATE_SHARE_FILE_NO_UPDATE", comment: ""))
                    } else {
                        NXToastWindow.sharedInstance?.toast(NSLocalizedString("UPDATE_SHARE_FILE_FAIL", comment: ""))
                    }
                }
                return
            }
            
            self.emailView.clear()
            
            self.recipients.append(contentsOf: self.recipientChange.adds)
            
            self.saveRecipientToCoreData()
            
            var addsSet:Set<String> = Set(self.recipientChange.adds)
            addsSet.subtract(Set(self.recipientChange.removes))
            let nameAddlist = addsSet.joined(separator: ",")
            
            var removesSet:Set<String> = Set(self.recipientChange.removes)
            removesSet.subtract(Set(self.recipientChange.adds))
            let nameRemovelist = removesSet.joined(separator: ",")
            
            if nameAddlist == "" {
                if nameRemovelist == "" {
                    NXCommonUtils.showNotification(title:"SkyDRM", content: NSLocalizedString("UPDATE_SHARE_FILE_NO_UPDATE", comment: ""))
                } else {
                    NXCommonUtils.showNotification(title:"SkyDRM", content: String(format: NSLocalizedString("UPDATE_SHARE_FILE_REMOVE_SUCCESS", comment: ""), nameRemovelist))
                }
            } else {
                if nameRemovelist == "" {
                    NXCommonUtils.showNotification(title:"SkyDRM", content: String(format: NSLocalizedString("UPDATE_SHARE_FILE_ADD_SUCCESS", comment: ""), nameAddlist))
                } else {
                    NXCommonUtils.showNotification(title:"SkyDRM", content: String(format: NSLocalizedString("UPDATE_SHARE_FILE_ADD_REMOVE_SUCCESS", comment: ""), nameAddlist, nameRemovelist))
                }
            }
            
            self.recipientChange.adds.removeAll()
            self.recipientChange.removes.removeAll()
            
            DispatchQueue.main.async {
                self.sharedCollection.reloadData()
            }
            
        }
    }
    
    private func checkEmail() -> Bool {
        self.emailView.currentEmailTextFieldItem?.inputTextField.keyDownClosure!(.ReturnKey)
        
        for item in self.emailView.emailsArray {
            if emailView.isValidate(email: item) == false {
                NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_EXIST_INVALID_EMAIL", comment: ""))
                return false
            }
        }
        let (updates, _, _) = NXCommonUtils.diffChanges(olds: recipients, news: emailView.emailsArray)
        if !updates.isEmpty {
            let namelist = updates.joined(separator: ",")
            NSAlert.showAlert(withMessage: String(format: NSLocalizedString("FILE_OPERATION_EXIST_SHARED_EMAIL", comment: ""), namelist))
            return false
        }
        
        return true
    }
    
    fileprivate func saveRecipientToCoreData() {
        guard let dbFile = DBMyVaultFileHandler.shared.fetchMyVaultFile(with: self.file.fullServicePath) else {
            return
        }
        
        let sharedWith = scrabSharedWith()
        dbFile.sharedWith = sharedWith
        _ = DBMyVaultFileHandler.shared.updateAll()
        
        let file = NXNXLFile()
        DBMyVaultFileHandler.format(from: dbFile, to: file)
        self.file = file
    }
    
    // FIXME: scrab "sharedWith" as server look like
    private func scrabSharedWith() -> String {
        var sharedWith = ""
        if recipients.count == 0 { return sharedWith }
        if recipients.count >= 1 { sharedWith = recipients[0] }
        if recipients.count == 1 { return sharedWith }
        if recipients.count >= 2 { sharedWith += ", " + recipients[1] }
        if recipients.count == 2 { return sharedWith }
        if recipients.count > 2 { sharedWith +=  " and " + String(recipients.count - 2) + " others " }
        return sharedWith
        
    }
    
    @IBAction func cancel(_ sender: Any) {
        back()
    }
    
    private func close() {
        delegate?.close(with: file)
    }
    
    private func back() {
        self.view.removeFromSuperview()
        delegate?.back(with: file)
    }
}

// MARK: Collection Delegate

extension NXFileSharingManageViewController: NSCollectionViewDataSource {
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return recipients.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let viewItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.collectionViewItemIdentifier), for: indexPath)
        
        if let sharedItem = viewItem as? NXFileSharingManageViewItem {
            sharedItem.delegate = self
            
            let emailString = recipients[indexPath.item]
            let abbrev = NXCommonUtils.abbreviation(forUserName: emailString)
            let firstLowLetter = String(abbrev[..<abbrev.index(after: abbrev.startIndex)]).lowercased()
            let backgroundColor = NSColor(colorWithHex: NXCommonUtils.circleViewBKColor[firstLowLetter]!, alpha: 1.0)
            
            sharedItem.emailTextField.stringValue = emailString
            sharedItem.icon.text = abbrev
            sharedItem.icon.backgroundColor = backgroundColor!
        }
        
        return viewItem
    }
    
}

extension NXFileSharingManageViewController: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
    }
}

extension NXFileSharingManageViewController: NXFileSharingManageViewItemDelegate {
    func removeItem(with item: NSCollectionViewItem) {
        guard let indexPath = sharedCollection.indexPath(for: item) else {
            return
        }
        
        recipientChange.removes.append(recipients[indexPath.item])
        recipients.remove(at: indexPath.item)
        
        DispatchQueue.main.async {
            self.sharedCollection.reloadData()
        }
    }
}
