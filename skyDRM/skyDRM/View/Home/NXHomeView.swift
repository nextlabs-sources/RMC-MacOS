//
//  NXHomeView.swift
//  skyDRM
//
//  Created by nextlabs on 09/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXHomeView: NSView, NXHomeWelcomeViewDelegate {
    
    
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var activityView: NSView!
    
    public weak var converView:NXWaitingView?
    
    private var homeTopView: NXHomeTopView?
    var homeBottomView: NXHomeBottomView?
    private var activityViewController: NXActivityCollectionViewController!
    weak var delegate: NXHomeViewDelegate?
    struct Constant {
        static let collectionViewControllerXibName = "NXActivityCollectionViewController"
    }
    private struct UIConstant {
        static let topGap: CGFloat = 30
        static let initWidth: CGFloat = 820
        static let initTopHeight: CGFloat = 460
        static let initBottomHeight: CGFloat = 160
        static let gapHeight: CGFloat = 30
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
    }
    override func scrollWheel(with event: NSEvent) {
        scrollView.scrollWheel(with: event)
    }
    override func removeFromSuperview() {
        super.removeFromSuperview()
        self.scrollView.removeObserver(self, forKeyPath: #keyPath(frame))
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if let _ = superview {
            wantsLayer = true
            layer?.backgroundColor = NSColor.white.cgColor
            let bottomframe = NSMakeRect((frame.width-UIConstant.initWidth)/2, 0, UIConstant.initWidth, UIConstant.initBottomHeight)
            homeBottomView = NXCommonUtils.createViewFromXibToScrollView(xibName: "NXHomeBottomView", identifier: "homeBottomView", frame: bottomframe, scrollView: scrollView) as? NXHomeBottomView
            homeBottomView?.delegate = self
            homeBottomView?.frameDelegate = self
            let topframe = NSMakeRect((frame.width-UIConstant.initWidth)/2, scrollView.frame.maxY-UIConstant.initTopHeight, UIConstant.initWidth, UIConstant.initTopHeight)
            homeTopView = NXCommonUtils.createViewFromXibToScrollView(xibName: "NXHomeTopView", identifier: "homeTopView", frame: topframe, scrollView: scrollView) as? NXHomeTopView
            homeTopView?.delegate = self
            homeTopView?.frameDelegate = self
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = false
            scrollView.scrollerStyle = .legacy
            refreshScrollView()
            
            self.scrollView.addObserver(self, forKeyPath: #keyPath(frame), options: [.old, .new], context: nil)
        }
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(frame),
            let newFrame = change?[.newKey] as? NSRect,
            let oldFrame = change?[.oldKey] as? NSRect {
            if oldFrame.height == newFrame.height {
                return
            }
            
            updateDocumentView(with: newFrame, oldFrame: oldFrame)
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    private func updateDocumentView(with newFrame: NSRect, oldFrame: NSRect) {
        if let documentView = scrollView.documentView {
            let newHeight = documentView.frame.height - newFrame.height + oldFrame.height
            documentView.frame.size.height = newHeight
        }
    }
    func addActivityView() {
        
        let collectionViewController = NXActivityCollectionViewController(nibName: Constant.collectionViewControllerXibName, bundle: nil)
        
        let viewControllerc = collectionViewController
        activityViewController = viewControllerc
        viewControllerc.view.frame = frame
        activityView.addSubview(viewControllerc.view)
    }
    
    func addCoverView() {
        converView = NXCommonUtils.createWaitingView(superView: self)!
    }
    func refreshAccountName() {
        homeTopView?.refreshProfile()
        homeBottomView?.updateAccountName()
    }
    func refreshUI(){
        homeTopView?.refreshProfile()
        homeTopView?.refreshRepositoriesList()
    }
    func updateUIFromNetwork() {
        homeTopView?.updateUIFromNetwork()
        homeBottomView?.updateUIFromNetwork()
    }
    //NXHomeWelcomeViewDelegate
    func onOpenRepositoryVC() {
        delegate?.homeOpenRepositoryVC()
    }
    func onGotoMySpace() {
    }
    func onRefreshAvatar() {
        delegate?.homeRefreshAvatar()
    }
    fileprivate func refreshScrollView() {
        guard let homeTopView = homeTopView,
            let homeBottomView = homeBottomView else {
                return
        }
        let allheight = homeTopView.frame.height + homeBottomView.frame.height + UIConstant.gapHeight + UIConstant.topGap
        
        scrollView.documentView?.frame.size.height = max(allheight, scrollView.frame.height)
        homeTopView.frame = NSMakeRect((frame.width-UIConstant.initWidth)/2, UIConstant.topGap, UIConstant.initWidth, homeTopView.frame.height)
        homeBottomView.frame = NSMakeRect((frame.width-UIConstant.initWidth)/2, homeTopView.frame.maxY+UIConstant.gapHeight, UIConstant.initWidth, homeBottomView.frame.height)
        var point = NSZeroPoint
        if scrollView.documentView?.isFlipped == false {
            point = NSMakePoint(0, scrollView.documentView!.frame.maxY-scrollView.contentView.bounds.height)
        }
        scrollView.documentView?.scroll(point)
    }
}
extension NXHomeView: NXFrameChangeViewDelegate {
    func onFrameChange(frame: NSRect) {
        DispatchQueue.main.async {
            self.refreshScrollView()
        }
    }
}

extension NXHomeView: NXHomeTopViewDelegate {
    func viewMyVault() {
        delegate?.homeGotoMySpace(type: .myVault, alias: "MyVault")
    }
    func viewMyDrive() {
        delegate?.homeGotoMySpace(type: .cloudDrive, alias: "MyDrive")
    }
    func viewAllFiles() {
        delegate?.homeGotoMySpace(type: .allFiles, alias: NSLocalizedString("REPO_STRING_ALLFILES", comment: ""))
    }
    func viewRepository(alias: String) {
        delegate?.homeGotoMySpace(type: .cloudDrive, alias: alias)
    }
    func viewAccount() {
        delegate?.homeOpenAccountVC()
    }
}

extension NXHomeView: NXHomeBottomViewDelegate {
    func showAllProjects() {
        delegate?.homeOpenProject()
    }
    func activateProject() {
        delegate?.homeOpenProjectActivate()
    }
}
