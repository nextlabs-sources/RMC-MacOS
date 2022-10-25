//
//  NXExpiryRangeView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 27/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXExpiryRangeView: NSView {

    @IBOutlet weak var dateRangeLabel: NSTextField!
    @IBOutlet weak var totalDaysLabel: NSTextField!
    @IBOutlet weak var startStepPicker: NSDatePicker!
    @IBOutlet weak var endStepPicker: NSDatePicker!
    
    @IBOutlet weak var box: NSBox!
    
    @IBOutlet weak var startGraphicPicker: NSDatePicker!
    @IBOutlet weak var endGraphicPicker: NSDatePicker!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    var startDate = Date()
    var endDate = Date()
    
    func initialize(startDate: Date, endDate: Date) {
        let now = Date()
        self.startDate = startDate > now ? startDate : now
        self.endDate = endDate > now ? endDate : Calendar.current.endOfDay(for: now)
        
        updateUI()
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if self.window == nil {
            return
        }
        
        box.wantsLayer = true
        box.layer?.backgroundColor = NSColor(colorWithHex: "#F2F2F2")!.cgColor
        
        startGraphicPicker.minDate = Date()
        startStepPicker.minDate = Date()
        endGraphicPicker.minDate = Date()
        endStepPicker.minDate = Date()
        
        let now = Date()
        var c = DateComponents()
        c.month = 1
        let to = Calendar.current.date(byAdding: c, to: now) ?? Date()
        let end = Calendar.current.endOfDay(for: to)
        initialize(startDate: now, endDate: end)
    }
    
    @IBAction func onStartPicker(_ sender: Any) {
        startDate = startStepPicker.dateValue
        if endDate < startDate {
            endDate = Calendar.current.endOfDay(for: startDate)
        }
        
        updateUI()
    }
    
    @IBAction func onEndPicker(_ sender: Any) {
        let date = startStepPicker.dateValue
        endDate = Calendar.current.endOfDay(for: date)
        
        updateUI()
    }
    
    @IBAction func changeStartGrapic(_ sender: Any) {
        startDate = startGraphicPicker.dateValue
        if endDate < startDate {
            endDate = Calendar.current.endOfDay(for: startDate)
        }
        
        updateUI()
    }
    
    @IBAction func changeEndGraphic(_ sender: Any) {
        let date = endGraphicPicker.dateValue
        endDate = Calendar.current.endOfDay(for: date)
        
        updateUI()
    }
    
    fileprivate func updateUI() {
        updatePicker()
        updateLabel()
    }
    
    func updatePicker() {
        startStepPicker.dateValue = startDate
        startGraphicPicker.dateValue = startDate
        endStepPicker.minDate = startDate
        endStepPicker.dateValue = endDate
        endGraphicPicker.minDate = startDate
        endGraphicPicker.dateValue = endDate
    }
    
    func updateLabel() {
        let from = startStepPicker.dateValue
        let to = endStepPicker.dateValue
        let toStr = date2String(date: to)
        let fromStr = date2String(date: from)
        dateRangeLabel.stringValue = fromStr + " to " + toStr
        
        let dayInterval = Calendar.current.dateComponents([.day], from: from, to: to)
        var days = dayInterval.day ?? 0
        days += 1
        let unit = days == 1 ? "day" : "days"
        totalDaysLabel.stringValue = "\(days) " + unit
    }
    
    fileprivate func date2String(date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .none
        return df.string(from: date)
    }
}
