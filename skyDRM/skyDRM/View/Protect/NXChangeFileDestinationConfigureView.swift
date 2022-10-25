//
//  NXChangeFileDestinationConfigureView.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/3/26.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

enum DestinationType {
    case local
    case centralMyVault
    case project
    case workspace
}

protocol NXChangeFileDestinationConfigureViewDelegate: NSObjectProtocol {
    func changeFileDestination(type: DestinationType, files: [NXSelectedFile], project: NXProjectModel?, syncFile: NXSyncFile?, destinationString: String?)
}

typealias ChangeDestinationBlock = (_ files: [NXSelectedFile]) -> ()

class NXChangeFileDestinationConfigureView: NXProgressIndicatorView {
    
    @IBOutlet weak var titleLab: NSTextField!
    @IBOutlet weak var selectedFileLab: NSTextField!
    @IBOutlet var fileTextView: NSTextView!
    @IBOutlet weak var changeFileBtn: NXTrackingButton!
    @IBOutlet weak var localBtn: NSButton!
    @IBOutlet weak var centralBtn: NSButton!
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var destinationStrLab: NSTextField!
    @IBOutlet weak var selectBtn: NSButton!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    
    weak var       delegate: NXChangeFileDestinationConfigureViewDelegate?
    var        selectedFile: [NXSelectedFile]!{
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
                    str.removeLast()
                    
                    if urls.count > 1 {
                        let str = String(format: "Selected files (%i)", urls.count)
                        self.selectedFileLab.stringValue = str
                        if self.protectType == .myVaultShared {
                            self.titleLab.stringValue = "Share protected files"
                        } else {
                            self.titleLab.stringValue = "Create protected files"
                        }
                    } else {
                        self.selectedFileLab.stringValue = "Selected file"
                        if self.protectType == .myVaultShared {
                            self.titleLab.stringValue = "Share a protected file"
                        } else {
                            self.titleLab.stringValue = "Create a protected file"
                        }
                    }
                    
                    self.fileTextView.string = str
                    self.fileTextView.setTextColor(NSColor.init(colorWithHex: "#828282"), range: NSMakeRange(0, str.count) )
                    self.fileTextView.font = NSFont.systemFont(ofSize: 10)
                }
            }
            
        }
    }
    var   changeFileBlock: ChangeDestinationBlock?
    var   destinationString: String? 
    var         protectType: NXProtectType? {
        didSet {
            changeDestinationWithType(type: protectType!)
        }
    }
    var  projectRootModel: NXProjectRoot? {
        didSet {
            destinationView?.rootModel = projectRootModel
        }
    }
    
   var  syncFile: NXSyncFile? {
        didSet {
            destinationView?.syncFile     = syncFile
        }
    }
    var projectModel: NXProjectModel? {
        didSet {
            destinationView?.projectModel = projectModel
        }
    }
    private var destinationView: NXSelectDestinationView?
    private var  selectPathView: NXLocalDriveSelectView?
    
    
    
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let _ = superview else {
            return
        }
        
        destinationStrLab.lineBreakMode = .byTruncatingTail
        
        self.window?.delegate = self
        selectBtn.wantsLayer = true
        selectBtn.layer?.backgroundColor = GREEN_COLOR.cgColor
        selectBtn.layer?.cornerRadius = 5
        let muAtti = NSMutableAttributedString(attributedString: changeFileBtn.attributedTitle)
        muAtti.addAttribute(NSAttributedString.Key.underlineStyle, value: NSNumber.init(value: NSUnderlineStyle.single.rawValue), range: NSMakeRange(0, changeFileBtn.title.count))
        changeFileBtn.attributedTitle = muAtti
        
        let startColor = NSColor.init(colorWithHex: NXConstant.NXColor.linear.0)!
        let endColor = NSColor.init(colorWithHex: NXConstant.NXColor.linear.1)!
        let gradientLayer = NXCommonUtils.createLinearGradientLayer(frame: selectBtn.bounds, start: startColor, end: endColor)
        selectBtn.layer?.addSublayer(gradientLayer)
        
        let titleAttr = NSMutableAttributedString(attributedString: selectBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, selectBtn.title.count))
        selectBtn.attributedTitle = titleAttr
        fileTextView.isEditable = false
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.white.cgColor
        
        if NXClient.getCurrentClient().getUser().0?.isPersonal == true {
            localBtn.isHidden = true
            for constraint in centralBtn.constraintsAffectingLayout(for: .horizontal) {
                if constraint.firstItem === centralBtn, constraint.firstAttribute == .centerX {
                    constraint.constant = 0
                }
            }
        }
        
    }
    
    func changeDestinationWithType(type: NXProtectType) {
        if let window = self.window {
            window.title = NXConstant.kTitle
            window.styleMask.remove(.resizable)
            window.delegate = self
            window.setContentSize(NSSize(width: 650, height: ((type == .project || type == .myVault || type == .workspace) ? 550 : 460)))
        }
        localBtn.state = (type == .project || type == .myVault || type == .workspace) ? NSControl.StateValue.off : NSControl.StateValue.on
        centralBtn.state = (type == .project || type == .myVault || type == .workspace) ? NSControl.StateValue.on : NSControl.StateValue.off
        contentViewHeight.constant = (type == .project || type == .myVault || type == .workspace) ? 190 : 100
        contentView.needsLayout = true
        if (type == .project || type == .myVault || type == .workspace ) {
            if selectPathView != nil {
                selectPathView?.removeFromSuperview()
            }
            if destinationView == nil {
                destinationView = NXCommonUtils.createViewFromXib(xibName: "NXSelectDestinationView", identifier: "selectDestinationView", frame: CGRect(x: 0, y: 0, width: 600, height: 190), superView: contentView) as? NXSelectDestinationView
                if (type == .project || type == .myVault || type == .workspace) {
                    destinationView?.destinationStr = destinationString
                }
                destinationView?.projectModel = projectModel
                destinationView?.syncFile     = syncFile
                destinationView?.protectType  = protectType
                destinationView?.rootModel    = projectRootModel
                
                weak var weakSelf = self
                destinationView?.destinationBlock = { (destination) -> () in
                    weakSelf?.destinationString = destination
                    weakSelf?.destinationStrLab.stringValue = destination ?? ""
                }
            } else {
                destinationString = destinationView?.destinationStr
                destinationView?.frame = CGRect(x: 0, y: 0, width: 600, height: 190)
                contentView.addSubview(destinationView!)
            }
            destinationStrLab.stringValue = destinationString ?? ""
        } else {
            if  destinationView != nil {
                destinationView?.removeFromSuperview()
            }
            if selectPathView == nil {
                selectPathView = NXCommonUtils.createViewFromXib(xibName: "NXLocalDriveSelectView", identifier: "localDriveSelectView", frame: CGRect(x: 0, y: 0, width: 600, height: 100), superView: contentView) as? NXLocalDriveSelectView
                if type == .local {
                    if protectType == .local {
                        selectPathView?.setDisplayPath(destinatonStr: destinationString!)
                    } else {
                        selectPathView?.setDisplayPath(destinatonStr: "")
                    }
                    
                }
                destinationString = selectPathView?.pathTextField.stringValue
                weak var weakSelf = self
                selectPathView?.pathBlock = { (path) -> () in
                    weakSelf?.destinationString = path ?? ""
                    weakSelf?.destinationStrLab.stringValue = path ?? ""
                }
            }else{
                destinationString = selectPathView?.pathTextField.stringValue
                selectPathView?.frame = CGRect(x: 0, y: 0, width: 600, height: 100)
                contentView.addSubview(selectPathView!)
            }
            destinationStrLab.stringValue = destinationString ?? ""
        }
    }
    
    @IBAction func changeFileAction(_ sender: NSButton) {
        let action: ([URL]) -> Void = { urls in
            self.selectedFile = urls.map() { .localFile(url: $0) }
        }
        
        if let window = self.window {
            NXCommonUtils.openPanel(parentWindow: window, allowMultiSelect: true, completion: action)
        }
    }
    @IBAction func localDriveAction(_ sender: NSButton) {
        changeDestinationWithType(type: .local)
    }
    
    @IBAction func centralLocationAction(_ sender: NSButton) {
        changeDestinationWithType(type: .project)
    }
    
    //MARK: - The event processing
    @IBAction func onCancel(_ sender: Any) {
        guard let vc = self.window?.contentViewController else {
            return
        }
        vc.presentingViewController?.dismiss(vc)
    }
    
    
    @IBAction func onSelect(_ sender: NSButton) {
        if (localBtn.state == NSControl.StateValue.on && delegate != nil) {
            if destinationString == "" {
                NSAlert.showAlert(withMessage: "WARNING_EMPTY_FOLDER".localized)
                return
            }
            delegate?.changeFileDestination(type: .local, files: selectedFile, project: nil, syncFile: nil, destinationString: destinationString)
        } else {
            if delegate == nil {
                return
            }
            let (type, project, syncFile) = (destinationView?.getLastData())!
            if type == .myVault {
                delegate?.changeFileDestination(type: .centralMyVault, files: selectedFile, project: nil, syncFile: nil, destinationString: destinationString)
            } else if type == .project {
                delegate?.changeFileDestination(type: .project, files: selectedFile, project: project, syncFile: nil, destinationString: destinationString)
            } else if type == .folder {
                delegate?.changeFileDestination(type: .project, files: selectedFile, project: nil, syncFile: syncFile, destinationString: destinationString)
            } else if type == .workspace {
                delegate?.changeFileDestination(type: .workspace, files: selectedFile, project: nil, syncFile: syncFile, destinationString: destinationString)
            }
        }
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
            })
        }
        
        stopAnimation()
        
        return result
        
    }
}




extension NXChangeFileDestinationConfigureView: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        self.onCancel(self)
    }
}
