    //
//  FileInfoViewController.swift
//  FileInfoDemo
//
//  Created by pchen on 02/03/2017.
//  Copyright © 2017 CQ. All rights reserved.
//

import Cocoa
import SDML
    
enum FileInfoType {
    case noViewRight
    case noViewPolicy
    case haveViewRight
    case haveViewPolicy
}

class FileInfoViewController: NSViewController {

    fileprivate struct Constant {
        static let rightsViewControllerXibName = "RightsViewController"
        static let tagsRightsVCXibName = "NXTagsViewController"
        static let fileInfoActionViewControllerXibName = "FileInfoActionViewController"
        static let defaultInterval: CGFloat = 8
        
        static let noramlInfoViewControllerXibName = "NXFileInfoNormaInfolViewController"
        static let myVaultInfoViewControllerXibName = "NXFileInfoMyVaultInfoViewController"
        
        // Display message
        static let stewardText = NSLocalizedString("FILE_INFO_STEWARD_RIGHTS", comment: "")
        static let notStewardText = NSLocalizedString("FILE_INFO_NOT_STEWARD_RIGHTS", comment: "")
        static let noRightsText = NSLocalizedString("FILE_INFO_NO_RIGHTS", comment: "")
        static let errorText = NSLocalizedString("FILE_INFO_GET_RIGHTS_FAILED", comment: "")
    }
    
    @IBOutlet weak var fileInfoView: NSView!
    @IBOutlet weak var rightsView: NSView!
    @IBOutlet weak var closeBtn: NSButton!
    
    var file: NXNXLFile!
    var type: FileInfoType = .noViewRight
    
    @IBOutlet weak var infoViewHeight: NSLayoutConstraint!
    @IBOutlet weak var rightsViewHeight: NSLayoutConstraint!
    
    fileprivate var rightsViewController: RightsViewController? = nil
    fileprivate var infoViewController: NXLocalFileInfoInfoViewController? = nil
    fileprivate var tagsRightsViewController: NXTagsViewController? = nil
    
    let semaphore = DispatchSemaphore(value: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.closeBtn.isHidden = true

        // Add mask to parentWindow.
        addMaskView()
        
        checkRight()
    }
    
    private func checkRight() {
        if file.rights == nil || file.rights?.count == 0  {
            self.view.addSubview(NXLoadingView.sharedInstance)
            NXClient.getObligationForViewInfo(file: NXSyncFile(file: file)) { (file, error) in
                NXLoadingView.sharedInstance.removeFromSuperview()

                if let error = error {
                    if let sdmlError = error as? SDMLError,
                        case SDMLError.commonFailed(reason: .networkUnreachable) = sdmlError {
                        NSAlert.showAlert(withMessage: "Lose Internet Connect".localized) { type in
                            self.closeWindow()
                        }
                        return
                    }
                }

                self.display()
            }
        } else {
            self.display()
        }
        
    }
    
    private func display() {
        initView()
        
        DispatchQueue.global().async {
            self.semaphore.wait()
            DispatchQueue.main.async {
                self.adjustWindow()
            }
            
        }
        
    }
    
    func initView() {
        addInfoView()
        if file.rights != nil && file.rights?.count != 0 {
            if file.isTagFile == true {
                if file.rights?.contains(.view) == true {
                    type = .haveViewPolicy
                } else {
                    // have no view right just show tags
                    type = .noViewPolicy
                }
            } else {
                if file.isOwner == true {
                    type = .haveViewRight
                } else {
                    if file.rights?.contains(.view) == true {
                        type = .haveViewRight
                    } else {
                        // have no view rights
                        type = .noViewRight
                    }
                }
            }
        } else {
            if file.isTagFile == true && file.tags?.count != 0 {
                type = .noViewPolicy
            } else {
                //没有view权限
                type = .noViewRight
            }
        }

        if (type == .haveViewPolicy || type == .noViewPolicy) {
            addTagsRightsView()
        }else {
            addRightsView()
        }

        closeBtn.highlight(true)
        
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor(colorWithHex: "#F2F2F2")!.cgColor
        
        self.closeBtn.isHidden = false
    }
    
    func addTagsRightsView() {
        tagsRightsViewController = NXTagsViewController(nibName:Constant.tagsRightsVCXibName, bundle: nil)
        tagsRightsViewController?.view.frame = CGRect(x: 0, y: 0, width: 650, height: (type == .haveViewPolicy ? 372 : 330))
        rightsView.addSubview((tagsRightsViewController?.view)!)
        addChild(tagsRightsViewController!)
        let right = NXRightObligation()
        right.rights = file.rights ?? [NXRightType]()
        right.watermark = file.watermark
        right.expiry = file.expiry
        tagsRightsViewController?.right = right
        tagsRightsViewController?.tags = file.tags!
        tagsRightsViewController?.type = type
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.view.window?.styleMask.remove(.resizable)
        self.view.window?.title = NXConstant.kTitle
        
        // Can adujust window.
        semaphore.signal()
    }
    
    private func adjustWindow() {
        
        if (type == .haveViewPolicy || type == .noViewPolicy)  {
            rightsViewHeight.constant = rightsViewHeight.constant + (type == .haveViewPolicy ? 122 : 80)
            rightsView.needsLayout = true
            if let frame = self.view.window?.frame {
                let rect = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: frame.height + (type == .haveViewPolicy ? 100 : 60)))
                self.view.window?.setFrame(rect, display: true)
            }
        }else if type == .noViewRight {
            rightsViewHeight.constant = rightsViewHeight.constant - 150
            rightsView.needsLayout = true
            if let frame = self.view.window?.frame {
                let rect = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: frame.height - 150))
                self.view.window?.setFrame(rect, display: true)
            }
        }
        
        if file.recipients == nil || file.recipients?.count == 0 {
            infoViewHeight.constant = infoViewHeight.constant - 100
            if let frame = self.view.window?.frame {
                let rect = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: frame.height-100))
                self.view.window?.setFrame(rect, display: true)
                
            }
            
        }
    }
    
    private func addInfoView() {
        infoViewController = NXLocalFileInfoInfoViewController(nibName: "NXLocalFileInfoInfoViewController", bundle: nil)
        infoViewController?.file = file
        infoViewController?.view.frame = fileInfoView.bounds
        fileInfoView.addSubview((infoViewController?.view)!)
        addChild(infoViewController!)
    }
    
    func addRightsView() {
        rightsViewController = RightsViewController(nibName:  Constant.rightsViewControllerXibName, bundle: nil)
        rightsViewController?.view.frame = CGRect(x: 0, y: 0, width: 650, height: (type == .haveViewRight ? 250 : 100))
        
        rightsViewController?.type  = type
        
        rightsView.addSubview((rightsViewController?.view)!)
        addChild(rightsViewController!)
        let right = NXRightObligation()
        right.rights = file.rights ?? [NXRightType]()
        right.watermark = file.watermark
        /////
        right.expiry = file.expiry
        
        rightsViewController?.right = right
        
    }
    
    func addMaskView() {
        if let parentView = NSApplication.shared.keyWindow?.contentView {
            parentView.addSubview(MaskView.sharedInstance)
        }
    }
    
    func removeMaskView() {
        MaskView.sharedInstance.removeFromSuperview()
    }
    
    @IBAction func close(_ sender: Any) {
        closeWindow()
    }
    
    func closeWindow() {
        self.presentingViewController?.dismiss(self)
        removeMaskView()
    }
}

extension FileInfoViewController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        removeMaskView()
    }
}
