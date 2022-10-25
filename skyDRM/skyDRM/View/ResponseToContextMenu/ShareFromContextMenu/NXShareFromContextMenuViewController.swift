//
//  NXShareFromContextMenuViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 15/05/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXShareFromContextMenuViewController: NSViewController {

    fileprivate struct Constant {
        static let serialQueueName = "com.nxrmc.skyDRM.NXShareFromContextMenuViewController"
        static let protectViewContrllerXibName = "NXProtectViewController"
    }
    
    fileprivate var data = SerialArray<(Bool, String)>(with: Constant.serialQueueName)
    
    fileprivate var isWorking = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func addTask(with paths: [(Bool, String)]) {
        addData(with: paths)
        startWork()
    }

    fileprivate func closeWindow() {
        self.data.removeAll()
        isWorking = false
        
        DispatchQueue.main.async {
            self.view.window?.close()
        }
        
    }
    
}

extension NXShareFromContextMenuViewController {
    
    fileprivate func addData(with paths: [(Bool, String)]) {
        for path in paths {
            self.data.append(element: path)
        }
        
    }
    
    fileprivate func startWork() {
        if !isWorking && !self.data.isEmpty(){
            isWorking = true
            processFirstTask()
        }
    }
    
    fileprivate func processFirstTask() {
        guard let data = self.data.getFirst() else {
            closeWindow()
            return
        }
        
        if data.0 {
            shareFile(with: data.1)
        } else {
            protectFile(with: data.1)
        }
        
    }
    
    fileprivate func processNextTask() {
        self.data.removeFirst()
        processFirstTask()
    }
    
    fileprivate func shareFile(with localPath: String) {
        do {
            let attr : NSDictionary? = try FileManager.default.attributesOfItem(atPath: localPath) as NSDictionary?
            if attr?.fileSize() == 0 {
                NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_SHARE_PROTECT_EMPTY_FILE", comment: ""), informativeText: "", dismissClosure: { (type) in
                   self.processNextTask()
                })
                return
            }
        } catch {
            
        }
        
        let file = NXFile()
        file.localPath = localPath
        file.name = URL(fileURLWithPath: localPath, isDirectory: false).lastPathComponent
        shareFile(with: file)
    }
    
    fileprivate func shareFile(with file: NXFileBase) {
        let protectViewController = NXProtectViewController(nibName:  Constant.protectViewContrllerXibName, bundle: nil)
         let viewControllera = protectViewController
        viewControllera.delegate = self
        viewControllera.file = file
        viewControllera.fileProtectType = NXFileProtectType.share
        
        self.presentAsModalWindow(viewControllera)
        viewControllera.doWorkWithoutDownload()
    }
    
    fileprivate func protectFile(with localPath: String) {
        do {
            let attr : NSDictionary? = try FileManager.default.attributesOfItem(atPath: localPath) as NSDictionary?
            if attr?.fileSize() == 0 {
                NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_SHARE_PROTECT_EMPTY_FILE", comment: ""), informativeText: "", dismissClosure: { (type) in
                    self.processNextTask()
                })
                return
            }
        } catch {
            
        }
        
        let file = NXFile()
        file.localPath = localPath
        file.name = URL(fileURLWithPath: localPath, isDirectory: false).lastPathComponent
        protectFile(with: file)
    }
    
    fileprivate func protectFile(with file: NXFileBase) {
        let protectViewController = NXProtectViewController(nibName: Constant.protectViewContrllerXibName, bundle: nil)
         let viewControllerb = protectViewController
        viewControllerb.delegate = self
        viewControllerb.file = file
        viewControllerb.fileProtectType = NXFileProtectType.protect
        
        self.presentAsModalWindow(viewControllerb)
        viewControllerb.doWorkWithoutDownload()
    }
}

extension NXShareFromContextMenuViewController: NXProtectViewControllerDelegate {
    func close() {
        processNextTask()
    }
}
