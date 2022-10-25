//
//  NXLoginViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 24/04/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa
import WebKit
import SDML

class NXLoginViewController: NSViewController {

    fileprivate struct Constant {
        static let messageHandleName = "fetchLoginResult"
        static let title = NXConstant.kTitle
    }
    
    @IBOutlet weak var webView: WKWebView!
    
    lazy var onceCode: Void = {
        let message = NSLocalizedString(NSLocalizedString("ERROR_LOGIN_WEBVIEW_LOAD_FAILED", comment: ""), comment:"")
        NSAlert.showAlert(withMessage: message, dismissClosure: {_ in
            DispatchQueue.main.async {
                self.presentingViewController?.dismiss(self)
                self.view.removeFromSuperview()
            }
        })
    }()
    
    private var returnBlock: ((Error?) -> ())?
    private var type = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do view setup here.
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        injectJS()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.view.window?.title = Constant.title
        self.view.window?.styleMask = [.closable,.titled]

        self.view.window?.delegate = self
        
    }
 
    deinit {
        YMLog("deinit")
    }

    func login(type: Bool, completion: @escaping (Error?) -> ()) {
        
        prepare(type: type, completion: completion)
        
        self.view.addSubview(NXLoadingView.sharedInstance)
            
        NXClient.getCurrentClient().getLoginRequest() { [weak self] result, error in
            guard let result = result, error == nil else {
                self?.returnBlock?(error)
                return
            }

            self?.loadWeb(cookie: result.0, urlRequest: result.1)
        }
    }
    
    func loginAfterRouter(type: Bool, cookie: String, request: URLRequest, completion: @escaping (Error?) -> ()) {
        
        prepare(type: type, completion: completion)
        
        self.view.addSubview(NXLoadingView.sharedInstance)
        
        self.loadWeb(cookie: cookie, urlRequest: request)
    }
    
    func register(completion: @escaping (Error?) -> ()) {
        
        prepare(type: false, completion: completion)
        
        self.view.addSubview(NXLoadingView.sharedInstance)
        NXClient.getCurrentClient().getRegisterURLRequest() { [weak self] result, error in
            guard let result = result, error == nil else {
                self?.returnBlock?(error)
                return
            }
            
            self?.loadWeb(cookie: result.0, urlRequest: result.1)
        }
    }
    
    func unbind() {
        self.returnBlock = nil
    }
    
    private func prepare(type: Bool, completion: @escaping (Error?) -> ()) {
        self.type = type
        self.returnBlock = completion
    }
    
    private func loadWeb(cookie: String, urlRequest: URLRequest) {
        deleteCookies { [weak self] in
            let cookieScript = WKUserScript(source: cookie, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
            self?.webView.configuration.userContentController.addUserScript(cookieScript)
            self?.webView.load(urlRequest)
        }
    }
    
    private func deleteCookies(completion: @escaping () -> ()) {
        self.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies() { [weak self] cookies in
            let group = DispatchGroup()
            for cookie in cookies {
                group.enter()
                self?.webView.configuration.websiteDataStore.httpCookieStore.delete(cookie) {
                    group.leave()
                }
            }
            
            group.notify(queue: DispatchQueue.main) {
                completion()
            }
        }
    }

    
    fileprivate func injectJS() {
        let source = "var s_ajaxListener = new Object();s_ajaxListener.tempOpen = XMLHttpRequest.prototype.open;XMLHttpRequest.prototype.open = function() {this.addEventListener('readystatechange', function() {var result = eval(\"(\" + this.responseText + \")\");alert('2');if(result.statusCode == 200 && result.message == \"Authorized\") {var temp = this.responseText;window.webkit.messageHandlers.fetchLoginResult.postMessage(temp);}}, false);s_ajaxListener.tempOpen.apply(this, arguments);}"
        let script = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)
        
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Constant.messageHandleName)
        webView.configuration.userContentController.add(self, name: Constant.messageHandleName)
    }
}

extension NXLoginViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Constant.messageHandleName)
        webView.configuration.userContentController.removeAllUserScripts()
        guard let str = message.body as? String else {
            self.returnBlock?(NSError())
            return
        }
        
        deleteCookies {
            NXClient.getCurrentClient().setLoginResult(type: self.type, result: str) { (error) in
                let router = (NXClient.getCurrentClient().getTenant().0?.routerURL)!
                NXCacheManager.saveLastTenant(router: router, tenant: "")
                
                self.returnBlock?(nil)
            }
        }
        
    }
}

extension NXLoginViewController: NSWindowDelegate {
    
    func windowWillClose(_ notification: Notification) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: Constant.messageHandleName)
        webView.configuration.userContentController.removeAllUserScripts()
        unbind()
    }
}

extension NXLoginViewController: WKNavigationDelegate {
     func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
    {
        NXLoadingView.sharedInstance.removeFromSuperview()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error)
    {
        YMLog("LoginVC:\(error)")
         _ = onceCode
    }
}

extension NXLoginViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            NSWorkspace.shared.open(url)
        }
        
        return nil
    }
}
