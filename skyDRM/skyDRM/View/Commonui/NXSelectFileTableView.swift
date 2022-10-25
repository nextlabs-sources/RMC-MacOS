//
//  NXSelectFileTableView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/19.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXSelectFileTableViewDelegate: NSObjectProtocol {
    func onClick(file: NXFileBase?)
    func onSelectChange(bSelected: Bool)
}

@IBDesignable class NXSelectFileTableView: NSView {

    @IBOutlet weak var pathControl: NXPathControl!
    @IBOutlet weak var fileTableView: NSTableView!
    @IBOutlet weak var emptyImage: NSImageView!
    @IBOutlet weak var emptyLabel: NSTextField!
    @IBOutlet weak var scrollView: NSScrollView!
    weak var delegate: NXSelectFileTableViewDelegate?
    var files = [NXFileBase]() {
        didSet {
            if files.count == 0 {
                scrollView.isHidden = true
                emptyImage.isHidden = false
                emptyLabel.isHidden = false
            }
            else {
                scrollView.isHidden = false
                emptyImage.isHidden = true
                emptyLabel.isHidden = true
                files = sortFiles(files: files)
                self.fileTableView.reloadData()
            }
            selectedFile = nil
        }
    }
    var rootName = "" {
        didSet {
            pathFolders.removeAll()
            pathControl.url = packupURL(fullPath: "")
            
        }
    }
    fileprivate var pathFolders = [NXFileBase]()
    var selectedFile: NXFileBase? {
        didSet {
            if let _ = selectedFile {
                delegate?.onSelectChange(bSelected: true)
            }
            else {
                delegate?.onSelectChange(bSelected: false)
            }
        }
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(fileTableView)
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let _ = superview else {
            return
        }
        wantsLayer = true
        layer?.backgroundColor = NSColor.white.cgColor
        pathControl.textColor = NSColor(colorWithHex: "#2F80ED", alpha: 1.0)!
        
        fileTableView.delegate = self
        fileTableView.dataSource = self
        emptyImage.isHidden = true
        emptyLabel.isHidden = true
    }
    @IBAction func onImageClick(_ sender: Any) {
        guard let button = sender as? NSButton,
            let id = button.identifier?.rawValue,
            let selected = Int(id) else {
            return
        }
        
        guard 0 ..< files.count ~= selected else {
            return
        }
        let file = files[selected]
        pathFolders.append(file)
        pathControl.url = packupURL(fullPath: file.fullPath)
        delegate?.onClick(file: file)
    }
    
    @IBAction func onDoubleClick(_ sender: Any) {
        guard fileTableView.selectedRow < files.count,
            fileTableView.selectedRow != -1 else {
            return
        }
        let file = files[fileTableView.selectedRow]
        pathFolders.append(file)
        
        pathControl.url = packupURL(fullPath: file.fullPath)
        delegate?.onClick(file: file)
    }

    @IBAction func onPathClick(_ sender: Any) {
        guard let clickPath = pathControl.clickedPathComponentCell()?.url?.path,
            let fullPath = pathControl.url?.path else {
            return
        }
        let leftPath = String(clickPath[clickPath.index(clickPath.startIndex, offsetBy: 1)...])
        guard leftPath != fullPath else {
            return
        }
        var fullFolderPath = ""
        if !leftPath.isEmpty {
            fullFolderPath = String(leftPath[leftPath.index(leftPath.startIndex, offsetBy: rootName.count)...])
        }
        fullFolderPath.append("/")
        removeFromPathFolders(fullPath: fullFolderPath)
        if let file = pathFolders.last {
            pathControl.url = packupURL(fullPath: file.fullPath)
            delegate?.onClick(file: file)
        }
        else {
            pathControl.url = packupURL(fullPath: "")
            delegate?.onClick(file: nil)
        }
    }
    fileprivate func packupURL(fullPath: String) -> URL? {
        let path = "/" + rootName + fullPath
        if #available(OSX 10.12, *) {
            if let encodePath = path.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) {
                return URL(string: encodePath)
            }
        }
        else {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    fileprivate func createIconFileNXFileBase(file: NXFileBase) -> NSImage? {
        if file is NXFolder {
            return NSImage(named: "folder_black")
        } else {
            return NSImage(named:  NXCommonUtils.getFileTypeIcon(fileName: file.name.lowercased()))
        }
    }
    fileprivate func findFile(servicePath: String) -> NXFileBase? {
        let result = files.filter({return $0.fullServicePath == servicePath})
        if result.count == 0 {
            return nil
        }
        else {
            return result[0]
        }
    }
    fileprivate func removeFromPathFolders(fullPath: String) {
        for (index, file) in pathFolders.enumerated() {
            if file.fullPath == fullPath {
                let removeCount: Int = pathFolders.count - index - 1
                if removeCount > 0 {
                    pathFolders.removeLast(removeCount)
                }
                return
            }
        }
        pathFolders.removeAll()
    }
    fileprivate func sortFiles(files: [NXFileBase]) -> [NXFileBase] {
        var fileArray = [NXFileBase]()
        var folderArray = [NXFileBase]()
        for file in files {
            if file is NXFolder {
                folderArray.append(file)
            }
            else {
                fileArray.append(file)
            }
        }
        folderArray.sort(by: {return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending})
        fileArray.sort(by: {return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending})
        var result = folderArray
        result.append(contentsOf: fileArray)
        return result
    }
}

extension NXSelectFileTableView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return files.count
    }
}
extension NXSelectFileTableView: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < files.count else {
            return nil
        }
        guard let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "fileCell"), owner: self) as? NSTableCellView,
            let button = view.viewWithTag(2) as? NXMouseEventButton,
            let text = view.viewWithTag(1) as? NSTextField else {
            return nil
        }
        button.image = createIconFileNXFileBase(file: files[row])
        button.identifier = NSUserInterfaceItemIdentifier(rawValue: "\(row)")
        text.stringValue = files[row].name
        return view
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard fileTableView.selectedRow < files.count else {
            return
        }
        if fileTableView.selectedRow == -1 {
            selectedFile = nil
        }
        else {
            selectedFile = files[fileTableView.selectedRow]
            if selectedFile is NXFolder {
                selectedFile = nil
            }
        }
    }
}

