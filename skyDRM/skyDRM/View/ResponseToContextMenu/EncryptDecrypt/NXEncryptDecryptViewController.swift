//
//  NXEncryptDecryptViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 26/04/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXEncryptDecryptViewController: NSViewController {
        // Do view setup here.
    fileprivate struct Constant {
        static let serialQueueName = "com.nxrmc.skyDRM.NXEncryptDecryptWindowController"
        static let rightsViewNibName = "NXRightsSelectViewController"
    }
    
    fileprivate var data = SerialArray<(isEncrypt: Bool, filePaths: [String])>(with: Constant.serialQueueName)
    
    fileprivate var isWorking = false
    
    var waitingView: NSView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        waitingView = NXCommonUtils.createWaitingView(superView: self.view)
        waitingView.isHidden = true
    }
    
    func addPendingTasks(en_DecryptFilePaths: [[String]]) {
        for paths in en_DecryptFilePaths {
            addFilePath(paths)
        }
        startWork()
    }
    
    func addTask(paths: [String]) {
        addFilePath(paths)
        startWork()
    }
    
    fileprivate func addFilePath(_ filePaths: [String]) {
        
        guard let client = NXLoginUser.sharedInstance.nxlClient else {
            return
        }
        // only support file
        let filePaths = filePaths.filter() { $0.last! != "/" }
        let needDecrypts = filePaths.filter() { client.isNXLFile(URL(fileURLWithPath: $0)) }
        let needEncrypts = filePaths.filter() { !needDecrypts.contains($0) }
        
        if !needEncrypts.isEmpty {
            self.data.append(element: (isEncrypt: true, filePaths: needEncrypts))
        }
        if !needDecrypts.isEmpty {
            self.data.append(element: (isEncrypt: false, filePaths: needDecrypts))
        }
    }

    fileprivate func closeWindow() {
        self.data.removeAll()
        isWorking = false
        
        DispatchQueue.main.async {
            self.view.window?.close()
        }
        
    }
    
    fileprivate func createOpenPanel() -> NSOpenPanel {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.worksWhenModal = true
        openPanel.treatsFilePackagesAsDirectories = true
        
        return openPanel
    }
    
    deinit {
        print("dealloc")
    }
}

// MARK: encrypt and decrypt

extension NXEncryptDecryptViewController {
    
    fileprivate func startWork() {
        if !isWorking && !self.data.isEmpty(){
            isWorking = true
            processFirstTask()
        }
    }
    
    fileprivate func processFirstTask() {
        guard let taskData = self.data.getFirst() else {
            closeWindow()
            return
        }
        if taskData.0 {
            encryptNormalFile(with: taskData.1)
        } else {
            decryptNXLFile(with: taskData.1)
        }
    }
    
    fileprivate func processNextTask() {
        self.data.removeFirst()
        processFirstTask()
    }
    
    fileprivate func encryptNormalFile(with filePaths: [String]) {
        DispatchQueue.main.async {
            self.showRightsWindow(with: filePaths)
        }
        
    }
    
    private func showRightsWindow(with filePaths: [String]) {
         let rightsViewController = NXRightsSelectViewController(nibName:  Constant.rightsViewNibName, bundle: nil) 
        rightsViewController.delegate = self
        rightsViewController.fileName = (filePaths.count == 1) ? filePaths[0]: (filePaths[0] + "...")
        let window = NSWindow(contentViewController: rightsViewController)
        NSApp.runModal(for: window)
    }
    
    fileprivate func decryptNXLFile(with filePaths: [String]) {
        let okCompletion: (URL) -> Void = {
            to in
            self.waitingView.isHidden = false
            self.decryptNXLFile(current: 0, filePaths: filePaths, toFolder: to)
        }
        let otherCompletion: () -> Void = {
            self.processNextTask()
        }
        DispatchQueue.main.async {
            self.showOpenPanel(with: okCompletion, otherCompletion: otherCompletion)
        }
        
    }
    
    fileprivate func showOpenPanel(with okCompletion: @escaping (URL) -> Void, otherCompletion: @escaping () -> Void) {
        let openPanel = createOpenPanel()
        openPanel.beginSheetModal(for: self.view.window!) { result in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let to = openPanel.url else {
                    return
                }
                okCompletion(to)
                
            } else {
                otherCompletion()
            }
        }
    }
    
    fileprivate func encryptNormalFile(current: Int, filePaths: [String], toFolder: URL, rights: NXLRights) {
        guard let client = NXLoginUser.sharedInstance.nxlClient else {
            return
        }
        
        if current >= filePaths.count {
            waitingView.isHidden = true
            processNextTask()
            return
        }
        
        let from = URL(fileURLWithPath: filePaths[current], isDirectory: false)
        let originName = from.lastPathComponent
        let targetName = originName + ".nxl"
        let targetPath = NXCommonUtils.getLocalPath(with: targetName, folderPath: toFolder.path)
        let to = URL(fileURLWithPath: targetPath, isDirectory: false)
        client.encrypt(toNXLFile: from, destPath: to, overwrite: true, permissions: rights) {
            filePath, error in
            
            if NXCommonUtils.getLoginFinishTicketCount() < NXCommonUtils.getLoginTicketCount() {
                self.closeWindow()
                return
            }
            
            if let error = error {
                Swift.print("error:\(error)")
                DispatchQueue.main.async{
                     NXToastWindow.sharedInstance?.toast(NSLocalizedString("ENCRYPT_FAILED_MESSAGE", comment: ""))
                }
            } else {
                DispatchQueue.main.async {
                    NXToastWindow.sharedInstance?.toast(NSLocalizedString("ENCRYPT_SUCCESS_MESSAGE", comment: ""))
                }
            }
            
            let next = current + 1
            self.encryptNormalFile(current: next, filePaths: filePaths, toFolder: toFolder, rights: rights)
        }
    }
    
    fileprivate func decryptNXLFile(current: Int, filePaths: [String], toFolder: URL) {
        guard let client = NXLoginUser.sharedInstance.nxlClient else {
            return
        }
        
        if current >= filePaths.count {
            processNextTask()
            return
        }
        
        let from = URL(fileURLWithPath: filePaths[current], isDirectory: false)
        let to = toFolder.appendingPathComponent(from.deletingPathExtension().lastPathComponent, isDirectory: false)
        client.decryptNXLFile(from, destPath: to, overwrite: true) {
            filePath, rights, error in
            if NXCommonUtils.getLoginFinishTicketCount() < NXCommonUtils.getLoginTicketCount() {
                self.closeWindow()
                return
            }
            
            if let error = error {
                Swift.print("error:\(error)")
                DispatchQueue.main.async {
                    NXToastWindow.sharedInstance?.toast(NSLocalizedString("DECRYPT_FAILED_MESSAGE", comment: ""))
                }
                
            } else {
                DispatchQueue.main.async {
                    NXToastWindow.sharedInstance?.toast(NSLocalizedString("DECRYPT_SUCCESS_MESSAGE", comment: ""))
                }
            }
            
            let next = current + 1
            self.decryptNXLFile(current: next, filePaths: filePaths, toFolder: toFolder)
        }
    }
}

// MARK: Rights View Delegate

extension NXEncryptDecryptViewController: NXRightsSelectViewControllerDelegate {
    func selectFinish(with rights: NXLRights?) {
        let okCompletion: (URL) -> Void = {
            to in
            if let filePaths = self.data.getFirst()?.1, let rights = rights {
                self.waitingView.isHidden = false
                self.encryptNormalFile(current: 0, filePaths: filePaths, toFolder: to, rights: rights)
            }
        }
        let otherCompletion: () -> Void = {
            self.processNextTask()
        }
        DispatchQueue.main.async {
            self.showOpenPanel(with: okCompletion, otherCompletion: otherCompletion)
        }
    }
    
    func cancel() {
        self.processNextTask()
    }
    
}
