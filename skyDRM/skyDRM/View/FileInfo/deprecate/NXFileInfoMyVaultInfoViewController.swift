//
//  NXFileInfoMyVaultInfoViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 15/05/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXFileInfoMyVaultInfoViewControllerDelegate: NSObjectProtocol {
    func close(with file: NXNXLFile)
    func back(with file: NXNXLFile)
}

class NXFileInfoMyVaultInfoViewController: NSViewController {

    fileprivate struct Constant {
        static let manageViewControllerXibName = "NXFileSharingManageViewController"
        
        static let maxSharedWithCount = 5
        
        static let manageTitle = NSLocalizedString("FILE_INFO_MANAGE_TITLE", comment: "")
        static let detailTitle = NSLocalizedString("FILE_INFO_DETAIL_TITLE", comment: "")
        
        static let deletedMessage = NSLocalizedString("FILE_INFO_DELETED_MESSAGE", comment: "")
        static let revokedMessage = NSLocalizedString("FILE_INFO_REVOKED_MESSAGE", comment: "")
        
        static let revokeConfirm = NSLocalizedString("FILE_INFO_REVOKE_CONFIRM", comment: "")
        
        static let fileInfoViewIdentifier = "FileInfoView"
        static let collectionViewItemIdentifier = "NXFileSharingManageViewItem"
        
        static let itemHeight: CGFloat = 54
        static let standardInterval: CGFloat = 8
    }
    
    // Input
    var file: NXNXLFile!
    
    // View
    @IBOutlet weak var filePath: NSTextField!
    @IBOutlet weak var fileName: NSTextField!
    @IBOutlet weak var fileSize: NSTextField!
    @IBOutlet weak var lastModified: NSTextField!
    @IBOutlet weak var originFilePath: NSTextField!
    @IBOutlet weak var sharedView: NXMultiCircleView!
    @IBOutlet weak var manageUserBtn: NSButton!
    @IBOutlet weak var revokeAllBtn: NSButton!
    @IBOutlet weak var sharedArea: NSView!
    @IBOutlet weak var fileStatusTextField: NSTextField!
    
    @IBOutlet weak var sharedWithMemberView: NSView!
    @IBOutlet weak var sharedWithMemberLabel: NSTextField!
    @IBOutlet weak var memberCollectionView: NSCollectionView!
    
    var waitingView: NXWaitingView?
    
    // Delegate
    weak var delegate: NXFileInfoMyVaultInfoViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        initView()
        initData()
        
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        sendRequestForRecipents()
    }
    
    private func initView() {
        if file.isRevoked == true || file.isDeleted == true {
            initRevokeDeleteFileView()
            
        } else {
            initSharedFileView()
        }
        
        createWaitingView()
        
    }
    
    private func initData() {
        settingFileInfo()
    }
    
    private func initSharedFileView() {
        
        sharedArea.isHidden = false
        sharedWithMemberView.isHidden = true
        
        let centerStyle = NSMutableParagraphStyle()
        centerStyle.alignment = .center
        let manageTitleAttributes = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: NSColor(colorWithHex: "#2F80ED", alpha: 1.0), NSAttributedString.Key.paragraphStyle: centerStyle]
        manageUserBtn.attributedTitle = NSAttributedString(string: manageUserBtn.title, attributes: manageTitleAttributes as [NSAttributedString.Key : Any])
        
        revokeAllBtn.wantsLayer = true
        revokeAllBtn.layer?.backgroundColor = NSColor(colorWithHex: "#EB5757", alpha: 1.0)?.cgColor
        revokeAllBtn.layer?.cornerRadius = 2
        
        let revokeTitleAttributes = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 15), NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.paragraphStyle: centerStyle]
        revokeAllBtn.attributedTitle = NSAttributedString(string: revokeAllBtn.title, attributes: revokeTitleAttributes)
        
        sharedView.maxDisplayCount = Constant.maxSharedWithCount
        
        fileStatusTextField.isHidden = true
    }
    
    private func initRevokeDeleteFileView() {
        sharedArea.isHidden = true
        sharedWithMemberView.isHidden = false
        
        let fileStatusStr: String = {
            if file.isDeleted == true {
                return Constant.deletedMessage
            } else if file.isRevoked == true {
                return Constant.revokedMessage
            } else {
                return ""
            }
        }()
        
        fileStatusTextField.isHidden = false
        fileStatusTextField.stringValue = fileStatusStr
        let attribute = [NSAttributedString.Key.foregroundColor: NSColor(colorWithHex: "#EB5757", alpha: 1.0)]
        fileStatusTextField.attributedStringValue = NSAttributedString(string: fileStatusTextField.stringValue, attributes: attribute as [NSAttributedString.Key : Any])
        
        settingCollectionViewLayout(with: memberCollectionView)
        memberCollectionView.reloadData()
        
    }
    
    private func settingCollectionViewLayout(with collectionView: NSCollectionView) {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: (collectionView.bounds.width - 5 * Constant.standardInterval)/2, height: Constant.itemHeight)
        flowLayout.sectionInset = NSEdgeInsets(top: Constant.standardInterval, left: Constant.standardInterval, bottom: Constant.standardInterval, right: Constant.standardInterval)
        flowLayout.minimumInteritemSpacing = Constant.standardInterval
        flowLayout.minimumLineSpacing = Constant.standardInterval
        collectionView.collectionViewLayout = flowLayout
    }
    
    private func createWaitingView() {
        waitingView = NXCommonUtils.createWaitingView(superView: self.view)
        waitingView?.isHidden = true
    }
    
    private func settingFileInfo() {
        if file.isDeleted == true || file.isRevoked == true {
            filePath.stringValue = Constant.detailTitle
        } else {
            filePath.stringValue = Constant.manageTitle
        }
        fileName.stringValue = file.name
        fileName.lineBreakMode = .byTruncatingMiddle
        fileSize.stringValue = NXCommonUtils.formatFileSize(fileSize: file.size)
        lastModified.stringValue = formatDateToString(date: file.lastModifiedDate as Date)
        
        var originDisplay = ""
        if let fromService = file.customMetadata?.sourceRepoName {
            originDisplay = fromService + " : "
        }
        if let fromDisplayPath = file.customMetadata?.sourceFilePathDisplay {
            originDisplay += fromDisplayPath
        }
        originFilePath.stringValue = originDisplay
    }
    
    private func formatDateToString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "dd MMMM yyyy, hh:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        
        let dateString = dateFormatter.string(from: date)
        
        return dateString
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
    
    @IBAction func manageUser(_ sender: Any) {
        
        let sharingViewController = NXFileSharingManageViewController(nibName: Constant.manageViewControllerXibName, bundle: nil)
      
        
        addChild(sharingViewController)
        
        sharingViewController.file = file
        sharingViewController.delegate = self
        
        let fileInfoView: NSView? = {
            var parentView = self.view.superview
            let maxCycle = 7
            var i = 0
            while let notnilView = parentView, i < maxCycle {
                if notnilView.identifier!.rawValue == Constant.fileInfoViewIdentifier {
                    return notnilView
                }
                parentView = notnilView.superview
                i += 1
            }
            
            return nil
        }()
        
        if let rootView = fileInfoView {
            self.view.isHidden = true
            sharingViewController.view.frame = rootView.frame
            rootView.addSubview(sharingViewController.view)
        }
        
    }
    
    @IBAction func revokeAll(_ sender: Any) {
        NSAlert.showAlert(withMessage: Constant.revokeConfirm, confirmButtonTitle:"Confirm", cancelButtonTitle:"Cancel", dismissClosure: {(type) in
            DispatchQueue.main.async {
                if type == .sure{
                    guard let duid = self.file?.getNXLID() else {
                        return
                    }
                    
                    self.waitingView?.isHidden = false
                    NXLoginUser.sharedInstance.nxlClient?.revokingDocument(byDocumentId: duid) {
                    error in
                    DispatchQueue.main.async {
                        self.waitingView?.isHidden = true
                    }
                    if error != nil {
                        print("revoke failed")
                        return
                    }
                    self.saveRevokeToCoreData()
                        
                    DispatchQueue.main.async {
                        self.initRevokeDeleteFileView()
                        }
                    }
                }
            }
        })
    }
    
    private func saveRevokeToCoreData() {
        
        self.file.isRevoked = true
        
        guard let file = DBMyVaultFileHandler.shared.fetchMyVaultFile(with: file.fullServicePath) else {
            return
        }
        
        file.isRevoked = true
        _ = DBMyVaultFileHandler.shared.updateAll()
    }
}

extension NXFileInfoMyVaultInfoViewController: NXServiceOperationDelegate {
    func getMetaDataFinished(servicePath: String?, error: NSError?) {
        DispatchQueue.main.async {
            self.waitingView?.isHidden = true
        }
        
        /// shared file must have a recipient at least
        guard let recipients = file.recipients else {
            return
        }
        
        DispatchQueue.main.async {
            if self.sharedArea.isHidden {
                self.sharedWithMemberLabel.stringValue = "Shared with" + " " + String(recipients.count) + " " + "members"
                self.memberCollectionView.reloadData()
            } else {
                self.sharedView.data = recipients
            }
        }
        
    }
}

extension NXFileInfoMyVaultInfoViewController: NXFileSharingManageViewControllerDelegate {
    func close(with file: NXNXLFile) {
        removeChild(at: 0)
        delegate?.close(with: file)
    }
    
    func back(with file: NXNXLFile) {
        self.view.isHidden = false
        removeChild(at: 0)
        
        delegate?.back(with: file)
    }
}

// MARK: Collection Delegate

extension NXFileInfoMyVaultInfoViewController: NSCollectionViewDataSource {
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return file.recipients?.count ?? 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let viewItem = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.collectionViewItemIdentifier), for: indexPath)
        guard let recipients = file.recipients else {
            return viewItem
        }
        
        if let sharedItem = viewItem as? NXFileSharingManageViewItem {
            
            sharedItem.closeBtn.isHidden = true
            
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
