//
//  NXTrayViewController.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 31/10/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXTrayViewControllerDelegate: NSObjectProtocol {
    func closePopover()
    func showPopover()
    func setUpPopoverAppearanceToVibrantLight(flag:Bool)
}

class NXTrayViewController: NSViewController {

    fileprivate enum MainView {
        case login
        case manage
    }
    fileprivate var mainView: MainView = .login {
        didSet {
            DispatchQueue.main.async {
                switch self.mainView {
                case .login:
                    self.showLoginView()
                    break
                case .manage:
                    self.showManageView()
                }
            }
        }
    }
    
    @IBOutlet weak var contentView: NSView!
    fileprivate var loginView: NXTrayLoginView?
    fileprivate var manageView: NXTrayManageView?
    fileprivate var setLoginUrlView: NXTraySetLoginUrlView?
  
    
    private var tokenExpiredFlag = false
    
    private var syncfilesContext = 0
    
    public var isOffline = false {
        didSet {
            manageView?.isOffline = isOffline
        }
    }
    
    public weak var delegate: NXTrayViewControllerDelegate?
    
    deinit {
        removeObservers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.mainView = NXClientUser.shared.user == nil ? .login : .manage
        
        addObservers()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if mainView == .manage {
            manageView?.updateUI()
        }
        
        isOffline = !NXClientUser.shared.isOnline
    }
    
    func addObservers() {
        NXClientUser.shared.addObserver(self, forKeyPath: "storage", options: .new, context: nil)
        NXClientUser.shared.addObserver(self, forKeyPath: "isOnline", options: .new, context: nil)
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .logout, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didRecvTokenExpiredMsg),
                                               name: NSNotification.Name(rawValue: SKYDRM_TOKEN_EXPIRED), object: nil)
        
    }
    
    func removeObservers() {
        NXClientUser.shared.removeObserver(self, forKeyPath: "storage")
        NXClientUser.shared.removeObserver(self, forKeyPath: "isOnline")
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "storage" {
            if mainView == .manage {
                manageView?.setStorage(myvault: NXClientUser.shared.storage!.myvault, total: NXClientUser.shared.storage!.total)
            }
        } else if keyPath == "isOnline" {
            isOffline = !NXClientUser.shared.isOnline
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    @objc func observeNotification(_ notification: Notification) {
        if notification.nxNotification == .logout {
            self.mainView = .login
        }
    }
    
    private func removeAllViews() {
        loginView?.removeFromSuperview()
        manageView?.removeFromSuperview()
        setLoginUrlView?.removeFromSuperview()
        loginView = nil
        manageView = nil
        setLoginUrlView = nil
    }
    
    private func showLoginView() {
        removeAllViews()
        setLoginUrlView = NXCommonUtils.createViewFromXib(xibName: "NXTraySetLoginUrlView", identifier: "setLoginUrlVieww", frame: nil, superView: contentView) as? NXTraySetLoginUrlView
        setLoginUrlView?.delegate = self
        
    }
    private func showManageView() {
        removeAllViews()
        manageView = NXCommonUtils.createViewFromXib(xibName: "NXTrayManageView", identifier: "trayManageView", frame: nil, superView: contentView) as? NXTrayManageView
        manageView?.delegate = self
        manageView?.isOffline = isOffline
        delegate?.showPopover()
    }
    
    @objc internal func didRecvTokenExpiredMsg(notification:NSNotification){
        weak var weakSelf = self
        if tokenExpiredFlag == false {
            synchronized(lock: self) {
                weakSelf?.tokenExpiredFlag = true
                NSAlert.showAlert(withMessage: NSLocalizedString("SKYDRM_Token_Expired_Tips", comment: ""), informativeText: "", dismissClosure: { (type) in
                    if type == .sure {

                    }
                })
            }
        }
    }
    private func synchronized(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
}

extension NXTrayViewController: NXTrayManageViewDelegate {
    func closePopover() {
        delegate?.closePopover()
    }
}

extension NXTrayViewController :NXTraySetLoginUrlViewDelegate {
    func onTapButton(companyStateOn:Bool?,userInputedURL:String!,cookies:String!,urlRequest:URLRequest!, isPersonal: Bool)
    {
        self.setLoginUrlView?.isHidden = true
        NXClient.getCurrentClient().logInViewAfterRouter(view: self.contentView, cookies: cookies, urlRequest: urlRequest, isPersonal: isPersonal) {[weak self] (error) in
            self?.setLoginUrlView?.isHidden = false
            if error != nil{
                return
            }
            
            self?.setLoginUrlView?.delegate = nil
            self?.setLoginUrlView?.removeFromSuperview()
            self?.contentView.subviews.removeAll()
            
            let tenant = NXClient.getCurrentClient().getTenant().0!
            let user = NXClient.getCurrentClient().getUser().0!
            NXClientUser.shared.setLoginUser(tenant: tenant, user: user)
            NXCommonUtils.saveLoginState(loginState: loginStateType.company.rawValue)
            
            if companyStateOn != nil {
                if companyStateOn! {
                    NXCacheManager.saveRecentRouter(router: userInputedURL)
                }
            }
            
            self?.delegate?.setUpPopoverAppearanceToVibrantLight(flag: true)
            self?.mainView = .manage
        }
        
        delegate?.showPopover()
    }
    
    func changePopoverAppearanceToVibrantLight(flag:Bool){
         delegate?.setUpPopoverAppearanceToVibrantLight(flag: flag)
    }
}
