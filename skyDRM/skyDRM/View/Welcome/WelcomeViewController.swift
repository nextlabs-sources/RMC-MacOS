//
//  WelcomeViewController.swift
//  WelcomePage
//
//  Created by pchen on 07/02/2017.
//  Copyright © 2017 pchen. All rights reserved.
//

import Cocoa

protocol NXWelcomeVCDelegate: NSObjectProtocol {
    func willLoginFinished()
    func didLoginFinished()
}
extension NXWelcomeVCDelegate {
    func willLoginFinished(){}
    func didLoginFinished(){}
}

class WelcomeViewController: NSViewController {

    @IBOutlet weak var loginBtn: NSButton!
    @IBOutlet weak var signUpLbl: NXMouseEventTextField!
    @IBOutlet weak var alreadyTip: NSTextField!
    weak var delegate: NXWelcomeVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NXCommonUtils.setLoginTicketCount()
        // Do view setup here.
        changeAppearance()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        _ = self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable)
        view.window?.backgroundColor = NSColor.white
        if let frame = view.window?.frame {
            view.window?.setFrame(NSMakeRect(frame.minX, frame.minY, 900, 600), display: true)
        }
        view.window?.delegate = self
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let pageController = segue.destinationController as? WelcomePageController {
            pageController.isWelcomeVC = true
        }
    }
    func changeAppearance() {
        
        /// change signup button display
        loginBtn.wantsLayer = true
        loginBtn.layer?.backgroundColor = NSColor(colorWithHex: "#34994C", alpha: 1.0)?.cgColor
        loginBtn.layer?.cornerRadius = 4
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center

        let titleAttr = NSMutableAttributedString(attributedString: loginBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, loginBtn.title.count))
        loginBtn.attributedTitle = titleAttr
        // set linear color
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = loginBtn.bounds
        gradientLayer.colors = [NSColor(colorWithHex: "#6AB3FA", alpha: 1.0)!.cgColor, NSColor(colorWithHex: "#087FFF", alpha: 1.0)!.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        loginBtn.layer?.addSublayer(gradientLayer)

        // change login button display
        signUpLbl.textColor = NSColor(colorWithHex: "#34994C", alpha: 1.0)
        signUpLbl.mouseDelegate = self
    }
    

    @IBAction func login(_ sender: Any) {
        login()

    }
}

/// Not welcome logic, may move to other place in future
extension WelcomeViewController {
//    fileprivate func setRestApiAddress() {
//        hostURLString = NXCommonUtils.getCurrentRMSAddress()
//    }
//    fileprivate func prepareAfterLogin() {
//        setRestApiAddress()
//        addDefaultBoundService()
//    }
    
//    fileprivate func addDefaultBoundService() {
//    }
//    
//    fileprivate func addMyDriveToCoreData() {
//        let bs = NXBoundService()
//        bs.repoId = ""
//        bs.serviceAlias = "MyDrive"
//        bs.serviceIsAuthed = true
//        bs.serviceIsSelected = true
//        bs.serviceType = ServiceType.kServiceSkyDrmBox.rawValue
//        bs.userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId)!
//        
//        if (!CacheMgr.shared.addNewBoundService(bs: bs)){
//            Swift.print("mydrive is already in coredata, or save to core data failed")
//        }
//        
//    }
//    
//    // local bound service
//    fileprivate func addMyVaultToCoreData() {
//        let bs = NXBoundService()
//        /// repoId only use in local
//        bs.repoId = "local repoId"
//        bs.serviceAlias = "MyVault"
//        bs.serviceIsAuthed = true
//        bs.serviceIsSelected = true
//        bs.serviceType = ServiceType.kServiceMyVault.rawValue
//        bs.userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId)!
//        
//        if (!CacheMgr.shared.addNewBoundService(bs: bs)){
//            Swift.print("myvault is already in coredata, or save to core data failed")
//        }
//        
//    }
    
    fileprivate func signUp() {
        NXClient.getCurrentClient().signUp(viewController: self) { result in
        }
    }
    
    fileprivate func login() {
        let vc = NXSetLoginUrlViewController()
        vc.delegate = self
        self.presentAsModalWindow(vc)
    }
}

extension WelcomeViewController: NXMouseEventTextFieldDelegate {
    func mouseDownTextField(sender: Any, event: NSEvent) {
        if let label = sender as? NXMouseEventTextField,
            label == signUpLbl {
            signUp()
        }
    }
}
extension WelcomeViewController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {        
        NXWindowsManager.sharedInstance.setupTray()
    }
    
}

extension WelcomeViewController: NXSetLoginUrlViewControllerDelegate {
    func willLoginFinished()
    {
        self.delegate?.willLoginFinished()
    }
    
    func didLoginFinished()
    {
        self.delegate?.didLoginFinished()
    }
}

