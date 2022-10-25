//
//  NXExpiryRelativeView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 27/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXExpiryRelativeView: NSView {
    @IBOutlet weak var yearLabel: NXNumberTextField!
    @IBOutlet weak var monthLabel: NXNumberTextField!
    @IBOutlet weak var dayLabel: NXNumberTextField!
    @IBOutlet weak var weekLabel: NXNumberTextField!
    @IBOutlet weak var totalDaysLabel: NSTextField!
    @IBOutlet weak var dataRangeLabel: NSTextField!
    @IBOutlet weak var warningLabel: NSTextField!
    @IBOutlet weak var box: NSBox!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    fileprivate var year: Int = 0
    fileprivate var month: Int = 1
    fileprivate var week: Int = 0
    fileprivate var day: Int = 0
    
    // Input and output.
    var _endDate = Date()
    var endDate: Date {
        get {
            return Calendar.current.endOfDay(for: _endDate)
        }
        set {
            _endDate = newValue
            var calender = NSCalendar.current
            calender.timeZone = TimeZone(identifier:"UTC")!
            let now = Date()
            var dateComponents:DateComponents? = calender.dateComponents([.year, .month,.weekOfMonth,.day], from: now, to: newValue)

            self.year = (dateComponents?.year)!
            self.month = (dateComponents?.month)!
            self.week = (dateComponents?.weekOfMonth)!
            self.day = (dateComponents?.day)! + 1
            
            updateUI()
            
        }
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        guard let _ = self.window else {
            return
        }
        
        yearLabel.delegate = self
        monthLabel.delegate = self
        weekLabel.delegate = self
        dayLabel.delegate = self
        
        warningLabel.isHidden = true
        box.wantsLayer = true
        box.layer?.backgroundColor = NSColor(colorWithHex: "#F2F2F2")!.cgColor
        
        updateUI()
    }
    
    fileprivate func updateUI(year: Int, month: Int, week: Int, day: Int) {
        var c = DateComponents()
        c.year = year
        c.month = month
        c.day = day - 1
        c.weekOfMonth = week
        let now = Date()
        let to = Calendar.current.date(byAdding: c, to: now) ?? Date()
        self._endDate = to
        
        let fromStr = date2String(date: now)
        let toStr: String
        if now < to {
            toStr = date2String(date: to)
        } else {
            toStr = date2String(date: now)
        }
        dataRangeLabel.stringValue = fromStr + " to " + toStr
        
        let dayInterval = Calendar.current.dateComponents([.day], from: now, to: to)
        var days = dayInterval.day ?? 0
        days += 1
        let unit = days > 1 ? "days" : "day"
        totalDaysLabel.stringValue = "\(days) " + unit
    }
    
    fileprivate func date2String(date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .none
        return df.string(from: date)
    }
    
    fileprivate func updateUI() {
        yearLabel.stringValue = String(self.year)
        monthLabel.stringValue = String(self.month)
        weekLabel.stringValue = String(self.week)
        dayLabel.stringValue = String(self.day)
        updateUI(year: self.year, month: self.month, week: self.week, day: self.day)
    }
}

extension NXExpiryRelativeView: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        year = Int(yearLabel.stringValue)!
        month = Int(monthLabel.stringValue)!
        week = Int(weekLabel.stringValue)!
        day = Int(dayLabel.stringValue)!
        
        updateUI(year: year, month: month, week: week, day: day)
        
        if year != 0 || month != 0 || week != 0 || day != 0 {
            warningLabel.isHidden = true
        }
        else {
            NXCommonUtils.showWarningLabel(label: warningLabel, str: NSLocalizedString("EXPIRY_RELATIVE_INVALID", comment: ""))
        }
    }
}

extension Calendar {
    func endOfDay(for date: Date) -> Date {
        let start = self.startOfDay(for: date)
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return self.date(byAdding: components, to: start)!
    }
}
