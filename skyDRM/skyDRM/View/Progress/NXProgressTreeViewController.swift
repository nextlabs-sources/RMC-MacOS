//
//  TreeViewController.swift
//  TreeViewDemo
//
//  Created by pchen on 27/02/2017.
//  Copyright © 2017 pchen. All rights reserved.
//

import Cocoa

struct RunningFile {
    
    enum RunningFileStatus {
        case running
        case finish
        case fail
    }
    var status: RunningFileStatus = .running
    var progress: Double = 0.0
    
    enum ActionType {
        case download
        case upload
    }
    let type: ActionType
    
    let name: String
    let id: Int
    
    init(name: String, type: ActionType, id: Int) {
        self.name = name
        self.type = type
        self.id = id
    }
}

protocol NXProgressTreeViewControllerDelegate : NSObjectProtocol {
    func itemCancel(id: Int)
}

class NXProgressTreeViewController: NSViewController {
    
    struct Constant {
        static let tableCellIdentifier = "TableCell"
        static let headerViewHeight: CGFloat = 21
        static let cellViewHeight: CGFloat = 40
        static let maxContentHeight: CGFloat = 40 * 3
    }
    
    fileprivate var isExpanded: Bool = true
    
    fileprivate var doing = [RunningFile]()
    
    fileprivate var parentWindow: NSWindow?
    
    fileprivate var topleftPt = NSZeroPoint
    
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var titleText: NSTextField!
    
    @IBOutlet weak var expandBtn: NSButton!
    
    @IBOutlet weak var closeBtn: NSButton!
    
    @IBOutlet weak var headerView: NSStackView!
    
    weak var delegate: NXProgressTreeViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        tableView.selectionHighlightStyle = .none
        parentWindow = NSApplication.shared.keyWindow
        
        titleText.textColor = NSColor.white
        updateTitleString()
        expandBtn.isHidden = true
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor.black.cgColor
        
        if self.doing.count == 1 {
            self.expandBtn.isHidden = true
        }
        else {
            self.expandBtn.isHidden = false
        }
        addMaskView()
        adjustWindow()
    }
    
    fileprivate func adjustWindow() {
        guard let window = view.window else {
            return
        }
        
        window.styleMask = .borderless
        
        
        setWindowOrigin()
        resizeWindow()
        self.topleftPt = NSMakePoint(window.frame.minX, window.frame.maxY)
    }
    
    fileprivate func addMaskView() {
        if let contentView = parentWindow?.contentView {
            contentView.addSubview(MaskView.sharedInstance)
        }
    }
    
    fileprivate func removeMaskView() {
        MaskView.sharedInstance.removeFromSuperview()
    }
    
    fileprivate func setWindowOrigin() {
        guard let window = view.window else {
            return
        }
        
        if let parentWindow = parentWindow {
            let x = parentWindow.frame.origin.x + (parentWindow.frame.size.width - window.frame.size.width)/2
            let y = parentWindow.frame.origin.y + (parentWindow.frame.size.height - window.frame.size.height)/2
            
            window.setFrameOrigin(CGPoint(x: x, y: y))
        }
        
    }
    
    fileprivate func resizeWindow() {
        guard let window = view.window else {
            return
        }

        if !isExpanded {
            let size = CGSize(width: view.frame.width, height: Constant.headerViewHeight)
            let origin = window.frame.origin
            window.setContentSize(size)
            
            window.setFrameOrigin(origin)
            return
        }

        var contentHeight = Constant.cellViewHeight * CGFloat(getDoingCount())
        contentHeight = (contentHeight < Constant.maxContentHeight) ? contentHeight: Constant.maxContentHeight
        let height = contentHeight + Constant.headerViewHeight
        let contentSize = CGSize(width: view.frame.width, height: height)
        window.setContentSize(contentSize)
    }
    
    fileprivate func updateTitleString() {
        let iCount = getDoingCount()
        let fileDescription = iCount == 1 ? "file" : "files"
        self.titleText.stringValue = "\(getActionTypeDesc()) \(iCount) \(fileDescription)"
    }
    
    fileprivate func getDoingCount() -> Int {
        let iCount = self.doing.count
        return iCount
    }
    
    fileprivate func getActionTypeDesc() -> String {
        var actionTypeDesc = ""
        
        for item in doing {
            if item.type == .download {
                actionTypeDesc = "Downloading"
            } else {
                actionTypeDesc = "Uploading"
            }
            break
        }
        
        return actionTypeDesc
    }
    
    fileprivate func refreshWindowUI() {
        if self.getDoingCount() == 0 {
            self.closeView()
        } else {
            self.updateTitleString()
            var height: CGFloat = 0
            var tableHeight = Constant.cellViewHeight * CGFloat(getDoingCount())
            tableHeight = (tableHeight < Constant.maxContentHeight) ? tableHeight: Constant.maxContentHeight
            if isExpanded {
                height = Constant.headerViewHeight + tableHeight
            }
            else {
                height = Constant.headerViewHeight
            }
            NSAnimationContext.runAnimationGroup({_ in
                if let window = self.view.window {
                    self.view.window?.animator().setFrame(NSMakeRect(self.topleftPt.x, self.topleftPt.y - height, window.frame.width, height), display: false)
                }
            }, completionHandler: nil)
        }
    }
    
    fileprivate func closeView() {
        self.presentingViewController?.dismiss(self)
        removeMaskView()
    }
    
    func setDoing(doing: [RunningFile]) {
        self.doing = doing
    }
    
    func updateProgress(id: Int, progress: Double) {
        DispatchQueue.main.async {
            for (index, item) in self.doing.enumerated() {
                if item.id == id {
                    self.doing[index].progress = progress
                    guard let tableView = self.tableView,
                        let cellView = tableView.view(atColumn: 0, row: index, makeIfNecessary: false) as? NXProgressTableCellView else {
                        return
                    }
                    self.makeTableCellRunning(cell: cellView, progress: progress)
                    break
                }
            }
        }
    }
    
    func setStatus(id: Int, status: RunningFile.RunningFileStatus) {
        DispatchQueue.main.async {
            for (index, item) in self.doing.enumerated() {
                if item.id == id {
                    guard let tableView = self.tableView,
                        let cellView = tableView.view(atColumn: 0, row: index, makeIfNecessary: false) as? NXProgressTableCellView else {
                        return
                    }
                    if status == .finish {
                        self.doing.remove(at: index)
                        self.makeTableCellFinish(cell: cellView)
                    } else if status == .fail {
                        self.doing[index].status = status
                        self.makeTableFail(cell: cellView)
                    }
                    self.refreshWindowUI()
                    break
                }
            }
        }
    }
    
    @IBAction func expand(_ sender: Any) {
        isExpanded = !isExpanded
        
        if isExpanded == true {
            expandBtn.image = NSImage(named:"arrow-down")
        } else {
            expandBtn.image = NSImage(named:"arrow-up")
        }
        refreshWindowUI()
    }
    
    @IBAction func close(_ sender: Any) {
        cancelAll()
        closeView()
    }
    
    @IBAction func cancel(_ sender: Any) {
        guard let cell = getClickCell(sender) else {
            return
        }
        
        let row = tableView.row(for: cell)
        cancel(row: row)
        refreshWindowUI()
    }
    
    fileprivate func getClickCell(_ sender: Any) -> NSTableCellView? {
        guard let clickedView = sender as? NSView else {
            return nil
        }
        
        var currentCell: NXProgressTableCellView?
        
        let maxCycle = 7
        
        var view: NSView? = clickedView
        for _ in 0..<maxCycle {
            
            if let cell = view as? NXProgressTableCellView {
                currentCell = cell
                break
            }
            
            if view == nil {
                break
            }
            
            view = view?.superview
        }
        
        return currentCell
    }
    
    fileprivate func cancel(row: Int) {
        self.delegate?.itemCancel(id: doing[row].id)
        doing.remove(at: row)
        tableView.removeRows(at: IndexSet(integer: row), withAnimation: NSTableView.AnimationOptions.slideLeft)
    }
    
    fileprivate func cancelAll() {
        for item in doing {
            if item.status == .running {
                self.delegate?.itemCancel(id: item.id)
            }
        }
    }
    fileprivate func makeTableCellRunning(cell: NXProgressTableCellView, progress: Double) {
        cell.progressIndicator.doubleValue = progress
        cell.percentageText.stringValue = "\(Int(100 * progress))%"
    }
    fileprivate func makeTableCellFinish(cell: NXProgressTableCellView) {
        let index = tableView.row(for: cell)
        if index != -1 {
            tableView.removeRows(at: IndexSet(integer: index), withAnimation: NSTableView.AnimationOptions.slideRight)
        }
    }
    fileprivate func makeTableFail(cell: NXProgressTableCellView) {
        cell.percentageText.stringValue = "Fail"
        cell.cancelBtn.isEnabled = false
    }
}

extension NXProgressTreeViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return getDoingCount()
    }
}

extension NXProgressTreeViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.tableCellIdentifier), owner: self)
        guard let tableCell = view as? NXProgressTableCellView else {
            return nil
        }
        
        let item = doing[row]
        tableCell.nameText.stringValue = item.name
        makeTableCellRunning(cell: tableCell, progress: item.progress)
        
        return tableCell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return Constant.cellViewHeight
    }
}

