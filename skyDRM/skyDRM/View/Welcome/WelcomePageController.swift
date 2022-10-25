//
//  ViewController.swift
//  WelcomePage
//
//  Created by pchen on 22/01/2017.
//  Copyright © 2017 pchen. All rights reserved.
//

import Cocoa
import CoreGraphics


class WelcomePageController: NSViewController {

    struct Constants {
        static let timeInterval = 4.0
    }
    fileprivate let welcomeInfoPrefix = ["WELCOME_SHARE_", "WELCOME_PROTECT_", "WELCOME_ACCESS_", "WELCOME_REVOKE_"]
    fileprivate let welcomeImageName = ["welcome_share", "welcome_protect", "welcome_access", "welcome_revoke"]
    fileprivate let activateInfoPrefix = ["ACTIVATE_SHARE_", "ACTIVATE_TEAMWORK_", "ACTIVATE_MANAGE_", "ACTIVATE_TRACK_"]
    fileprivate let activateImageName = ["activate_share", "activate_teamwork", "activate_manage", "activate_track"]
    fileprivate var numberOfPage = 4
    var isWelcomeVC = false
    
    @IBOutlet weak var pageControl: PageControl!
    var pageController: NSPageController?
    
    @IBOutlet weak var previousBtn: NSButton!
    @IBOutlet weak var nextBtn: NSButton!
    
    let queue = DispatchQueue(label: "com.nxrmc.skyDRM.WelcomePageController.timer")
    var timer: DispatchSourceTimer?
    
    var currentIndex: Int {
        get {
            return pageController?.selectedIndex ?? 0
        }
        set {
            
            if newValue == 0 {
                previousBtn.isEnabled = false
                nextBtn.isEnabled = true
            } else if newValue == numberOfPage - 1 {
                previousBtn.isEnabled = true
                nextBtn.isEnabled = false
            } else {
                previousBtn.isEnabled = true
                nextBtn.isEnabled = true
            }
            
            pageControl.currentIndex = newValue
            
            // To instantly change the selectedIndex:
            pageController?.selectedIndex = newValue
            
            // To animate a selectedIndex change:
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: DispatchTime.now()+Constants.timeInterval, repeating: Constants.timeInterval)
        timer?.setEventHandler {
            DispatchQueue.main.async {
                self.currentIndex = (self.currentIndex + 1) % self.numberOfPage
            }
        }
        timer?.resume()
        
        if self.parent is WelcomeViewController {
            isWelcomeVC = true
            numberOfPage = welcomeInfoPrefix.count
        }
        else {
            isWelcomeVC = false
            numberOfPage = activateInfoPrefix.count
        }
        settingPageControl()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        
        timer?.cancel()
        timer = nil
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        pageController = segue.destinationController as? NSPageController
        settingPageController()
    }
    
    @IBAction func previous(_ sender: Any) {

        currentIndex = currentIndex - 1
    }
    
    @IBAction func next(_ sender: Any) {

        currentIndex = currentIndex + 1
    }

    func settingPageControl() {
        pageControl.numberOfPage = numberOfPage
    }
    
    func settingPageController() {
        let intArray = [Int](0..<numberOfPage)
        pageController?.arrangedObjects = intArray.map({"\($0)"})
        pageController?.delegate = self
        pageController?.selectedIndex = 0
    }
}

extension WelcomePageController: NSPageControllerDelegate {
    
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> String {
        return String(describing: object)
    }
    
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        
        if isWelcomeVC {
            if let id = Int(identifier),
                id >= 0,
                id < welcomeInfoPrefix.count {
                let prefix = welcomeInfoPrefix[id]
                let first = NSLocalizedString("\(prefix)FIRST_LINE", comment: "")
                let second = NSLocalizedString("\(prefix)SECOND_LINE", comment: "")
                let third = NSLocalizedString("\(prefix)THIRD_LINE", comment: "")
                let info = NSLocalizedString("\(prefix)INFO", comment: "")
                if id != 0 {
                    let vc = NXWelcomeInfoViewController()
                    vc.welcomeInfo = NXWelcomeInfo(imageName: welcomeImageName[id], firstLine: first, secondLine: second, thirdLine: third, info: info)
                    return vc
                } else {
                    let vc = NXWelcomeInfoViewControllerFirstPage()
                    vc.welcomeInfo = NXWelcomeInfo(imageName: welcomeImageName[id], firstLine: first, secondLine: second, thirdLine: third, info: info)
                    return vc
                }
            }
            else {
                return NSViewController()
            }

        }
        else {
//            if let id = Int(identifier),
//                id >= 0,
//                id < activateInfoPrefix.count {
//                let prefix = activateInfoPrefix[id]
//                let first = NSLocalizedString("\(prefix)FIRST_LINE", comment: "")
//                let second = NSLocalizedString("\(prefix)SECOND_LINE", comment: "")
//                let info = NSLocalizedString("\(prefix)INFO", comment: "")
//                let vc = NXProjectActivateIntroVC()
//                vc.activateInfo = NXProjectActivateInfo(imageName: activateImageName[id], firstLine: first, secondLine: second, info: info)
//                return vc
//            }
//            else {
//                return NSViewController()
//            }
            return NSViewController()
        }
    }
    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        pageController.completeTransition()
    }
}
