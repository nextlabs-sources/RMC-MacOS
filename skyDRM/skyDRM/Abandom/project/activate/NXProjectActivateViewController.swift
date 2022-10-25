//
//  NXProjectActivateViewController.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 31/05/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXProjectActivateViewController: NSViewController {
    @IBOutlet weak var createBtn: NSButton!
    @IBOutlet weak var cancelBtn: NSButton!
    
    fileprivate var projectService: NXProjectAdapter?
    
    var newProjectVC:NXNewProjectVC?
    
    deinit {
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        createBtn.wantsLayer = true
        createBtn.layer?.backgroundColor = NSColor(colorWithHex: "#34994C", alpha: 1.0)?.cgColor
        createBtn.layer?.cornerRadius = 4
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        
        createBtn.title = NSLocalizedString("ACTIVATE_CREATE_BUTTON", comment: "")
        let titleAttr = NSMutableAttributedString(attributedString: createBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.paragraphStyle: pstyle], range: NSMakeRange(0, createBtn.title.count))
        createBtn.attributedTitle = titleAttr
        
        // set linear color
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = createBtn.bounds
        gradientLayer.colors = [NSColor(colorWithHex: "#34994C", alpha: 1.0)!.cgColor, NSColor(colorWithHex: "#70B55B", alpha: 1.0)!.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        createBtn.layer?.addSublayer(gradientLayer)
        
        if let profile = NXLoginUser.sharedInstance.nxlClient?.profile {
            projectService = NXProjectAdapter(withUserID: profile.userId, ticket: profile.ticket)
            projectService?.delegate = self
        }

        NXMainMenuHelper.shared.onProjectActivate()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        _ = self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable)
        view.window?.backgroundColor = NSColor.white
        if let frame = view.window?.frame {
            view.window?.setFrame(NSMakeRect(frame.minX, frame.minY, 900, 600), display: true)
        }
        self.view.window?.delegate = self
    }
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let pageController = segue.destinationController as? WelcomePageController {
            pageController.isWelcomeVC = false
        }
    }
    @IBAction func onCreate(_ sender: Any) {
        if newProjectVC == nil {
            newProjectVC = NXNewProjectVC()
        }
        newProjectVC?.delegate = self
        
        NSApplication.shared.keyWindow?.windowController?.contentViewController?.presentAsModalWindow(newProjectVC!)
    }
    @IBAction func onCancel(_ sender: Any) {
        if let controller = self.storyboard?.instantiateController(withIdentifier:"ViewController") as? ViewController {
            self.view.window?.contentViewController = controller
        }
    }
    
    func didRecvLogOutMsg(notification:NSNotification){
        Swift.print("didMsgRecv: \(String(describing: notification.userInfo))")
        
        //clear WKWebView of NXLMacLoginVC
        let cookiesStorage = HTTPCookieStorage.shared
        if let cookies = cookiesStorage.cookies {
            for cookie in cookies {
                cookiesStorage.deleteCookie(cookie)
            }
        }
        if let currentClient = NXLoginUser.sharedInstance.nxlClient {
            // TODO: error handle
            try? currentClient.signOut()
            NXLoginUser.sharedInstance.clear()
        }
        
        NXSpecificProjectWindow.sharedInstance.closeCurrentWindow()
        NXFileRenderManager.shared.closeAllFile()
        
        if let controller =  self.storyboard?.instantiateController(withIdentifier:  "WelcomeViewController"), let welcome = controller as? WelcomeViewController {
            self.view.window?.contentViewController = welcome
        }
        
        // Fix bug: close or exit crash
        NSApplication.shared.windows.first?.delegate = nil
    }
    
}
extension NXProjectActivateViewController: NXNewProjectDelegate {
    func onNewProject(title: String, description: String, emailArray: [String], invitationMsg: String) {
        createBtn.isEnabled = false
        cancelBtn.isEnabled = false
        let project = NXProject()
        project.name = title
        project.projectDescription = description
        project.invitationMsg = invitationMsg
        projectService?.createProject(project: project, invitedEmails: emailArray)
    }
}

extension NXProjectActivateViewController: NXProjectAdapterDelegate {
    func createProjectFinish(projectName: String, projectId: String?, error: Error?) {
        newProjectVC?.onCreateFinish()
        createBtn.isEnabled = true
        cancelBtn.isEnabled = true
        if error != nil {
            NXToastWindow.sharedInstance?.toast(NSLocalizedString("CREATEPROJECT_FAIL", comment: ""))
            return
        }
        if let controller = self.storyboard?.instantiateController(withIdentifier:  "ViewController") as? ViewController {
            self.view.window?.contentViewController = controller
        }
    }
}

extension NXProjectActivateViewController: NSWindowDelegate {
    func windowDidResignMain(_ notification: Notification) {
        NXMainMenuHelper.shared.onModalSheetWindow()
    }
    func windowDidResignKey(_ notification: Notification) {
        NXMainMenuHelper.shared.onModalSheetWindow()
    }
    func windowDidBecomeKey(_ notification: Notification) {
        NXMainMenuHelper.shared.onProjectActivate()
    }
    func windowDidBecomeMain(_ notification: Notification) {
        NXMainMenuHelper.shared.onProjectActivate()
    }
}
