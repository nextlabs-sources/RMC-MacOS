//
//  NXCreateFolderPopViewController.swift
//  skyDRM
//
//  Created by xx-huang on 28/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXCreateFolderPopViewController: NSViewController, NSTextFieldDelegate {
    
    @IBOutlet weak var nameOfNewFolderLabel: NSTextField!
    @IBOutlet weak var newFolderNameTextField: NSTextField!
    @IBOutlet weak var createButton: NSButton!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var warnTextField: NSTextField!
    
    weak var createFolderDelegate: NXCreateFolderPopViewDelegate? = nil

    fileprivate struct Constant {
        static let maxLength = 40
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do view setup here.
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        newFolderNameTextField.delegate = self
        self.title = "New Folder"
        createButton.isEnabled = false
        
        warnTextField.stringValue = ""
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.styleMask = NSWindow.StyleMask([.borderless,.titled])
    }
    
     func controlTextDidChange(_ notification: Notification) {
        
        let isStandard = isFolderNameStandard()
        if isStandard {
            createButton.isEnabled = true
        } else {
            createButton.isEnabled = false
        }
    }

    func isFolderNameStandard() -> Bool {
        
        let str = newFolderNameTextField.stringValue
        
        guard !str.isEmpty else {
            return false
        }
        
        guard str.count <= Constant.maxLength else {
            let lastIndex = str.index(str.startIndex, offsetBy: Constant.maxLength)
            newFolderNameTextField.stringValue = String(str[..<lastIndex])
            return true
        }
        
        let isStandard: Bool = {
            let specialCharacters = "^[\\u00C0-\\u1FFF\\u2C00-\\uD7FF\\w \\x22\\x23\\x27\\x2C\\x2D]+$"
            let predicate = NSPredicate(format: "SELF MATCHES %@", specialCharacters)
            return predicate.evaluate(with: newFolderNameTextField.stringValue)
        }()
        
        if isStandard {
            warnTextField.stringValue = ""
        } else {
            warnTextField.stringValue = NSLocalizedString("INCLOUDE_SPECIALCHARACTER_WARNING", comment: "")
        }
        
        return isStandard
    }
    
    @IBAction func createButtonClicked(_ sender: Any) {
        
        self.presentingViewController?.dismiss(self)
        if newFolderNameTextField.stringValue.isEmpty {
             createFolderDelegate?.createFolderPopViewFinished(type: .createButtonClicked, newFolderName: "")
        }
        else
        {
             createFolderDelegate?.createFolderPopViewFinished(type: .createButtonClicked, newFolderName: newFolderNameTextField.stringValue)
        }
       
    }

    @IBAction func cancelButtonClicked(_ sender: Any) {
        
        self.presentingViewController?.dismiss(self)
        
        createFolderDelegate?.createFolderPopViewFinished(type: .cancelButtonClicked, newFolderName: "")
       
    }
    
    @IBAction func endInput(_ sender: Any) {
        let isStandard = isFolderNameStandard()
        if isStandard {
            self.presentingViewController?.dismiss(self)
            if newFolderNameTextField.stringValue.isEmpty {
                createFolderDelegate?.createFolderPopViewFinished(type: .createButtonClicked, newFolderName: "")
            }
            else{
                createFolderDelegate?.createFolderPopViewFinished(type: .createButtonClicked, newFolderName: newFolderNameTextField.stringValue)
            }
        }
    }
}
