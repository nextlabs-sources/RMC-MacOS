//
//  NXMyVaultRenderShareViewController.swift
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 6/1/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXMyVaultRenderShareViewController: NSViewController {
    fileprivate struct Constant {
        static let collectionViewItemIdentifier = "NXFileSharingManageViewItem"
        static let itemHeight: CGFloat = 54
        static let standardInterval: CGFloat = 8
    }
    
    var file: NXNXLFile!

    @IBOutlet weak var fileNameTextField: NSTextField!
    @IBOutlet weak var rightsSelectView: NSView!
    @IBOutlet weak var emailContainerView: NSView!
    @IBOutlet weak var commentContainerView: NSView!
    @IBOutlet weak var sharedCollection: NSCollectionView!
    @IBOutlet weak var updateBtn: NSButton!
    @IBOutlet weak var cancelBtn: NSButton!
    
    fileprivate var emailView: NXEmailView!
    fileprivate var waitingView: NXWaitingView?
    fileprivate var rightsView: NXRightsView!
    fileprivate var commentView: NXCommentsView!
    
    fileprivate var downloadOrUploadId: Int? = nil
    
    //Delegate
    weak var delegate: NXFileSharingManageViewControllerDelegate?
    
    //Data
    var recipients = [String]()
    var recipientChange: (adds: [String], removes: [String]) = ([String](), [String]())
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        initView()
        sendRequestForRecipents()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.view.window?.titleVisibility = .hidden
        self.view.window?.titlebarAppearsTransparent = true
        self.view.window?.styleMask = .titled
    }
    
    
    private func sendRequestForRecipents() {
        guard
            let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId,
            let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket
            else { return }
        
        let service = MyVaultService(withUserID: userId, ticket: ticket)
        service.delegate = self
        
        waitingView?.isHidden = false
        _ = service.getMetaData(file: file)
        
    }
    
    private func initView(){
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        
        initControl()
        settingCollectionViewLayout()
        createWaitingView()
    }
    
    private func initControl(){
        fileNameTextField.stringValue = file.name
        emailView = NXCommonUtils.createViewFromXib(xibName: "NXEmailView", identifier: "emailView", frame: emailContainerView.bounds, superView: emailContainerView) as? NXEmailView
        rightsView = NXCommonUtils.createViewFromXib(xibName: "NXRightsView", identifier: "rightsView", frame: rightsSelectView.bounds, superView: rightsSelectView) as? NXRightsView
        
        // Init watermark and expiry from preference.
        var watermark: NXFileWatermark?
        var expiry: NXFileExpiry?
        if let text = NXClient.getCurrentClient().getUserPreference()?.getDefaultWatermark().getText() {
            watermark = NXFileWatermark(text: text)
        }
        if let preferenceExpiry = NXClient.getCurrentClient().getUserPreference()?.getDefaultExpiry() {
            expiry = NXCommonUtils.transform(from: preferenceExpiry)
        }
        rightsView?.set(watermark: watermark, expiry: expiry)
        
        commentView = NXCommonUtils.createViewFromXib(xibName: "NXCommentsView", identifier: "commentsView", frame: nil, superView: commentContainerView) as? NXCommentsView
        commentView.placeholder = NSLocalizedString("COMMENT_VIEW_SHARE_COMMENT", comment: "")
    }
    
    private func createWaitingView(){
        waitingView = NXCommonUtils.createWaitingView(superView: self.view)
        waitingView?.isHidden = true
    }
    
    private func settingCollectionViewLayout(){
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: (sharedCollection.bounds.width - 3 * Constant.standardInterval)/2, height: Constant.itemHeight)
        flowLayout.sectionInset = NSEdgeInsets(top: Constant.standardInterval, left: Constant.standardInterval, bottom: Constant.standardInterval, right: Constant.standardInterval)
        flowLayout.minimumInteritemSpacing = Constant.standardInterval
        flowLayout.minimumLineSpacing = Constant.standardInterval
        sharedCollection.collectionViewLayout = flowLayout
    }
    
    
    private func checkEmail()->Bool{
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
    
    fileprivate func saveRecipientToCoreData(){
        guard let file = DBMyVaultFileHandler.shared.fetchMyVaultFile(with: file.fullServicePath) else{
            return
        }
        
        let sharedWith = scrabSharedWith()
        file.sharedWith = sharedWith
        _ = DBMyVaultFileHandler.shared.updateAll()
    }
    
    private func scrabSharedWith()->String{
        var sharedWith = ""
        if recipients.count == 0 {return sharedWith}
        if recipients.count >= 1 {sharedWith = recipients[0]}
        if recipients.count == 1 {return sharedWith}
        if recipients.count >= 2 {sharedWith += ", " + recipients[1]}
        if recipients.count == 2 {return sharedWith}
        if recipients.count > 2 {sharedWith += " and " + String(recipients.count - 2) + " others "}
        return sharedWith
    }
    
    @IBAction func update(_ sender: Any) {
        if !checkEmail() {
            return
        }
        
        recipientChange.adds.append(contentsOf: emailView.emailsArray)
        
        updateShareFile()
    }
    
    private func updateShareFile(){
        guard let duid = file.getNXLID() else{
            return
        }
        
        waitingView?.isHidden = false
        NXLoginUser.sharedInstance.nxlClient?.updateSharedFileRecipients(byDUID: duid, newRecipients: recipientChange.adds, removeRecipients: recipientChange.removes, comment: commentView.comments){ error in
            DispatchQueue.main.async {
                self.waitingView?.isHidden = true
            }
            
            if error != nil{
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
            
            let namelist = self.recipientChange.adds.joined(separator: ",")
            NXCommonUtils.showNotification(title:"SkyDRM", content: String(format: NSLocalizedString("UPDATE_SHARE_FILE_ADD_SUCCESS", comment: ""), namelist))
            
            self.recipientChange.adds.removeAll()
            self.recipientChange.removes.removeAll()
            
            DispatchQueue.main.async {
                self.sharedCollection.reloadData()
            }
        }
    }
    
    func convertNXLRightsToFileRight(rights: [NXRightType]?) -> NXLRights?{
        
        guard let rights = rights else {
            return nil
        }
        
        let fileRights = NXLRights()
    
        
        fileRights.setRight(.NXLRIGHTVIEW, value: true)
        fileRights.setRight(.NXLRIGHTPRINT, value: rights.contains(.print))
        fileRights.setRight(.NXLRIGHTSHARING, value: rights.contains(.share))
        fileRights.setRight(.NXLRIGHTSDOWNLOAD, value: rights.contains(.saveAs))
        fileRights.setRight(.NXLRIGHTEDIT, value: rights.contains(.edit))
        fileRights.setObligation(.NXLOBLIGATIONWATERMARK, value: rights.contains(.watermark))
        
        return fileRights
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(nil)
        delegate?.back(with: file)
    }
    @IBAction func close(_ sender: Any) {
        self.dismiss(nil)
        delegate?.close(with: file)
    }
}
extension NXMyVaultRenderShareViewController: NSCollectionViewDataSource{
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return recipients.count
    }
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let viewItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.collectionViewItemIdentifier), for: indexPath)
        if let sharedItem = viewItem as? NXFileSharingManageViewItem{
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
extension NXMyVaultRenderShareViewController: NSCollectionViewDelegate{
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
    }
}
extension NXMyVaultRenderShareViewController: NXFileSharingManageViewItemDelegate{
    func removeItem(with item: NSCollectionViewItem) {
        guard let indexPath = sharedCollection.indexPath(for: item) else{
            return
        }
        
        recipientChange.removes.append(recipients[indexPath.item])
        recipients.remove(at: indexPath.item)
        
        DispatchQueue.main.async {
            self.sharedCollection.reloadData()
        }
    }
}
extension NXMyVaultRenderShareViewController: NXServiceOperationDelegate {
    func getMetaDataFinished(servicePath: String?, error: NSError?) {
        DispatchQueue.main.async {
            self.waitingView?.isHidden = true
        }
        if let recipients = file.recipients {
            self.recipients = recipients
            self.sharedCollection.reloadData()
        }
        
    }
}
