//
//  NXAddFileCreateNewFileView.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/5/20.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa
import SDML

protocol NXAddFileCreateNewFileViewDelegate: NSObjectProtocol {
    func addFileFinished(file: NXNXLFile, tags:[String: [String]], right: NXRightObligation?, destinationStr: String)
    func backAction(syncFile: NXSyncFile?, projectModel: NXProjectModel?, destinationString: String?)
}

class NXAddFileCreateNewFileView: NXProgressIndicatorView {
    fileprivate struct Constant{
        static let collectionViewItemIdentifier = "NXLocalRightsViewItem"
        static let standardInterval: CGFloat = 3
        static let rightCountInRow = 6
    }
    @IBOutlet weak var fileNameLab: NSTextField!
    @IBOutlet weak var projectNameLab: NSTextField!
    @IBOutlet weak var tagsContentView: NSView!
    @IBOutlet weak var rightsContentView: NSView!
    @IBOutlet weak var tagsCollectionView: NSCollectionView!
    @IBOutlet weak var collectionView: NSCollectionView!
    
    @IBOutlet weak var addFileBtn: NSButton!
    @IBOutlet weak var backBtn: NSButton!
    @IBOutlet weak var cancelBtn: NSButton!
    @IBOutlet weak var definedView: NSView!
    
    
    weak var delegate: NXAddFileCreateNewFileViewDelegate?
    
    var destinationStr: String?
    var rightsCollectionViewItemSize :NSSize?
    
    var projectModel: NXProjectModel? {
        didSet {
            if projectModel != nil {
                projectNameLab.stringValue = projectModel?.name ?? ""
                self.getRight(file: projectModel!)
            }
        }
    }
    var syncFile: NXSyncFile? {
        didSet {
            if syncFile != nil, let fileModel = syncFile?.file as? NXProjectFileModel {
                projectNameLab.stringValue = fileModel.project?.name ?? ""
                self.getRight(file: fileModel.project!)
            }
        }
    }
    
    var filePath: String? {
        didSet {
            if filePath != nil {
                self.fileNameLab.stringValue = (filePath! as NSString).lastPathComponent
            }
        }
    }
    
    var preFileModel: NXProjectFileModel? {
        didSet {
            if preFileModel != nil {
                fileNameLab.stringValue = preFileModel?.name ?? ""
            }
        }
    }
    var tags: [String: [String]]? {
        didSet {
            if tags != nil && tags?.count != 0 {
                self.tagsCollectionView.reloadData()
            }
        }
    }
    var right: NXRightObligation? {
        didSet {
            if right != nil {
                if (right?.rights.count)! > 0 {
                     definedView.isHidden = true
                }else
                {
                     definedView.isHidden = false
                }
               
            }else {
                definedView.isHidden = false
            }
        }
    }
    
    func getRight(file: NXProjectModel) {
        NXClient.getCurrentClient().getRightObligationWithTags(totalProject: file.sdmlProject, isWorkspace: false, tags: tags ?? [:]) { (nxObligation, error) in
            if error != nil {
                return
            }
            DispatchQueue.main.async {
                self.right = nxObligation
                self.collectionView.reloadData()
            }
        }
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.wantsLayer = true
        self.layer?.backgroundColor = RGB(r: 236, g: 236, b: 236).cgColor
        
        addFileBtn.wantsLayer = true
        addFileBtn.layer?.cornerRadius = 5
        
        cancelBtn.wantsLayer = true
        cancelBtn.layer?.cornerRadius = 5
        cancelBtn.layer?.backgroundColor = NSColor.white.cgColor
        
        backBtn.wantsLayer = true
        backBtn.layer?.cornerRadius = 5
        backBtn.layer?.backgroundColor = NSColor.white.cgColor
        
        projectNameLab.textColor = NSColor(red: 10.0 / 255, green: 128.0 / 255, blue: 255.0 / 255, alpha: 1)
        
        let startColor = NSColor.init(colorWithHex: NXConstant.NXColor.linear.0)!
        let endColor = NSColor.init(colorWithHex: NXConstant.NXColor.linear.1)!
        let gradientLayer = NXCommonUtils.createLinearGradientLayer(frame: addFileBtn.bounds, start: startColor, end: endColor)
        addFileBtn.layer?.addSublayer(gradientLayer)
        
        let titleAttr = NSMutableAttributedString(attributedString: addFileBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, addFileBtn.title.count))
        addFileBtn.attributedTitle = titleAttr
        
        tagsCollectionView.wantsLayer = true
//        tagsCollectionView.layer?.backgroundColor = NSColor.black.cgColor
        
        collectionView.register(NXLocalRightsViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier.init("NXLocalRightsViewItem"))
        tagsCollectionView.register(NXResultTagsCollectionViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier.init("NXResultTagsCollectionViewItemID"))
      
        
        collectionView.wantsLayer = true
        collectionView.layer?.backgroundColor = RGB(r: 236, g: 236, b: 236).cgColor
        configureCollectionView()
    }
    
  
    
    fileprivate func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        let width = (collectionView.bounds.width - (CGFloat(Constant.rightCountInRow - 1)) * Constant.standardInterval) / CGFloat(Constant.rightCountInRow)
        flowLayout.itemSize = NSSize(width: width, height: collectionView.bounds.height)
        rightsCollectionViewItemSize = NSSize(width: width, height: collectionView.bounds.height)
        flowLayout.minimumInteritemSpacing = Constant.standardInterval
        flowLayout.minimumLineSpacing = Constant.standardInterval
        collectionView.collectionViewLayout = flowLayout
    }
}

extension NXAddFileCreateNewFileView {
    @IBAction func cancelAction(_ sender: Any) {
        guard let vc = self.window?.contentViewController else {
            return
        }
        vc.presentingViewController?.dismiss(vc)
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.delegate?.backAction(syncFile: self.syncFile, projectModel: self.projectModel, destinationString: self.destinationStr)
    }
    
    @IBAction func addFileAction(_ sender: Any) {
        if (syncFile != nil || projectModel != nil) {
            self.startAnimation()
            NXClient.getCurrentClient().addNXLFileToProject(file: preFileModel, goalProject: (projectModel != nil ? projectModel?.sdmlProject?.getFileManager().getRootFolder() : syncFile?.file.sdmlBaseFile as? SDMLProjectFile)!, systemFilePath:  filePath, tags: tags!) { (file, error) in
                self.stopAnimation()
                
                if let error = error {
                    if let sdmlError = error as? SDMLError {
                        if case SDMLError.commonFailed(reason: .networkUnreachable) = sdmlError {
                            NSAlert.showAlert(withMessage: "Lose Internet Connect".localized) { type in
                                self.window?.close()
                            }
                        } else if case SDMLError.protectFailed = sdmlError {
                            let message = String(format: NSLocalizedString("FILE_OPERATION_PROTECT_FAILED_FILE", comment: ""), self.fileNameLab.stringValue)
                            NSAlert.showAlert(withMessage: message) { type in
                                self.window?.close()
                            }
                        } else {
                            let message = "PERMISSION_NO_RIGHTS_TEXT".localized
                            NSAlert.showAlert(withMessage: message) { type in
                                self.window?.close()
                            }
                        }
                    } else {
                        let message = "PERMISSION_NO_RIGHTS_TEXT".localized
                        NSAlert.showAlert(withMessage: message) { type in
                            self.window?.close()
                        }
                    }
                    return
                }
                
                NotificationCenter.default.post(name: NXNotification.projectProtected.notificationName,object: file)
                self.delegate?.addFileFinished(file: file!, tags: self.tags ?? [:], right: self.right, destinationStr: self.destinationStr ?? "")
                
            }
        }
    }
}

extension NXAddFileCreateNewFileView: NSCollectionViewDataSource{
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == tagsCollectionView {
            return tags?.keys.count ?? 0
        }
        return right?.rights.count ?? 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        if collectionView == tagsCollectionView {
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NXResultTagsCollectionViewItemID"), for: indexPath)
            guard let viewItem = item as? NXResultTagsCollectionViewItem else {
                return item
            }
            let keys = Array((tags?.keys)!)
            let key  = keys[indexPath.item]
            let labels = tags![key]
            if labels?.count == 1 {
                let tagDisplay = key + ": " + (labels?.first)!
                viewItem.setLabelDisplay(tagString: tagDisplay)
            }else if labels?.count ?? 0 >= 2 {
                var labStr = ""
                for (index,str) in (labels?.enumerated())! {
                    if index == (labels?.count)! - 1 {
                        labStr = labStr + str
                    }else{
                        labStr = labStr + str + ","
                    }
                }
                let tagDisplay = key + ": " + labStr
                viewItem.setLabelDisplay(tagString: tagDisplay)
            }
            return viewItem
        }else {
            if let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.collectionViewItemIdentifier), for: indexPath) as? NXLocalRightsViewItem {
                var image: NSImage?
                var text: String?
                switch right?.rights[indexPath.item] {
                case .view?:
                    image = NSImage.init(named: "view")
                    text = "View"
                case .print?:
                    image = NSImage.init(named: "print")
                    text = "Print"
                case .share?:
                    image = NSImage.init(named: "share")
                    text = "Share"
                case .saveAs?:
                    image = NSImage.init(named: "saveas")
                    text = "SaveAs"
                case .edit?:
                    image = NSImage.init(named: "edit")
                    text = "Edit"
                case .extract?:
                    image = NSImage.init(named: "extract")
                    text = "Extract"
                case .watermark?:
                    image = NSImage.init(named: "watermark")
                    text = "Watermark"
                case .validity?:
                    image = NSImage.init(named: "validity")
                    text = "Validity"
                case .none:
                    image = NSImage.init(named: "view")
                    text = "Nono"
                }
                
                item.imageView?.image = image
                item.textField?.stringValue = text ?? ""
                return item
            }
            let item = NSCollectionViewItem()
            return item
        }
    }
}

extension NXAddFileCreateNewFileView : NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        
        if collectionView == tagsCollectionView {
            let keys = Array((tags?.keys)!)
            let key  = keys[indexPath.item]
            let labels = tags![key]
            if labels?.count == 1 {
                let tagDisplay = labels!.first! + key
                let size = getStringSizeWithFont(string: tagDisplay, font: NSFont.systemFont(ofSize: 14), maxSize: NSSize(width: 527, height: CGFloat.greatestFiniteMagnitude))
                  return NSSize(width: 660,height: size.height + 12)
            }else if labels?.count ?? 0 >= 2 {
                var labStr = ""
                for (index,str) in (labels?.enumerated())! {
                    if index == (labels?.count)! - 1 {
                        labStr = labStr + str
                    }else{
                        labStr = labStr + str + ","
                    }
                }
                 let tagDisplay = labStr + key
                 let size = getStringSizeWithFont(string: tagDisplay, font: NSFont.systemFont(ofSize: 14), maxSize: NSSize(width: 527, height: CGFloat.greatestFiniteMagnitude))
                  return NSSize(width: 660,height: size.height + 12)
            }else{
                return NSSize(width: 660,height: 30)
            }
        }else{
            return rightsCollectionViewItemSize!
        }
    }
}

