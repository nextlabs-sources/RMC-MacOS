//
//  SplashViewController.swift
//  WelcomePage
//
//  Created by pchen on 10/02/2017.
//  Copyright © 2017 pchen. All rights reserved.
//

import Cocoa

class SplashViewController: NSViewController {
    
    struct Constants {
        static let identifier_WelcomePage = "WelcomeViewController"
        static let identifier_HomePage = "ViewController"
        static let greenColor = "#34994C"
        static let splashTime = 2
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(colorWithHex: Constants.greenColor, alpha: 1.0)?.cgColor
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        _ = self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Constants.splashTime)) {
            self.toLogin()
        }
    }
    
    private func toLogin() {
        
        NXCommonUtils.setLoginTicketCount()
        if self.isLogin() {
             // to home
            hideMainVC()
           
        } else {
            // to welcome
            self.loadWelcomeView()
        }

    }
    
    private func isLogin() -> Bool
    {
        do{
            let client = try NXLClient.currentNXLClient()
            NXLoginUser.sharedInstance.nxlClient = client
            
        } catch {
            
            return false
        }
        
        return true
    }
    
    private func loadHomeView() {
        if let controller = self.storyboard?.instantiateController(withIdentifier:  Constants.identifier_HomePage), let home = controller as? ViewController {
            self.view.window?.contentViewController = home
        }
    }
    
    private func hideMainVC() {
        self.view.window?.alphaValue = 0
    }
    
    private func loadWelcomeView() {
        if let controller = self.storyboard?.instantiateController(withIdentifier:  Constants.identifier_WelcomePage), let welcome = controller as? WelcomeViewController {
            self.view.window?.contentViewController = welcome
        }
    }
}
