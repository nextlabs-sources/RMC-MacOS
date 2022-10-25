//
//  NXProjectTabViewController.swift
//  skyDRM
//
//  Created by William (Weiyan) Zhao on 2019/3/27.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa
protocol NXProjectTabViewControllerDelegate: class {
    func getDisplayCount(_ displayCount:Int)
}

class NXProjectTabViewController: NSViewController {
    @IBOutlet weak var oneTableView: NSTabView!
    @IBOutlet weak var allProjects: NSTabViewItem!
    @IBOutlet weak var createByMe: NSTabViewItem!
    @IBOutlet weak var createByOthers: NSTabViewItem!
    weak var delegate:NXProjectTabViewControllerDelegate?
    var data:NXProjectRoot = NXProjectRoot()
    {
      didSet {
            displayData.createByMe = data.createdByMeProjects
            displayData.createByOthers = data.otherCreatedProjects
            displayData.chidren        = data.projects
            projectVC.data = displayData
        }
    }
    let projectVC = NXProjectViewController(nibName: "NXProjectViewController",bundle:nil)
    
    @objc dynamic var  displayData:NXProjectNewRoot = NXProjectNewRoot()
    @objc dynamic var displayCount: Int {
        get {
            return displayData.chidren.count
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
            setupTabView()
    }
    fileprivate func setupTabView() {
        projectVC.view.frame = self.view.bounds
        projectVC.view.frame = self.view.bounds
        allProjects.label = "All Projects"
        createByMe.label  = "Create by Me"
        createByOthers.label = "Create by Others"
        projectVC.view.frame = self.view.bounds
        createByMe.viewController = projectVC
        createByMe.view = projectVC.view
        allProjects.viewController = projectVC
        oneTableView.delegate = self
        allProjects.view = projectVC.view
        createByOthers.viewController = projectVC
        createByOthers.view = projectVC.view
    }
    
}
extension NXProjectTabViewController:NSTabViewDelegate {
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        if tabView.selectedTabViewItem == allProjects {
                displayData.createByMe = data.createdByMeProjects
                displayData.createByOthers = data.otherCreatedProjects
                projectVC.data = displayData
            delegate?.getDisplayCount(projectVC.displayCount)
        } else if tabView.selectedTabViewItem == createByMe {
                displayData.createByMe = data.createdByMeProjects
                displayData.createByOthers = []
                projectVC.data = displayData
            delegate?.getDisplayCount(projectVC.displayCount)
        } else if tabView.selectedTabViewItem == createByOthers {
                displayData.createByOthers = data.otherCreatedProjects
                displayData.createByMe = []
                projectVC.data = displayData
            delegate?.getDisplayCount(projectVC.displayCount)
        }
    }
}
