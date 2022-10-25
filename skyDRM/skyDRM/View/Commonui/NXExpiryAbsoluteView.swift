//
//  NXExpiryAbsoluteView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 27/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXExpiryAbsoluteView: NSView {
    @IBOutlet weak var rangeDateLabel: NSTextField!
    @IBOutlet weak var totalDaysLabel: NSTextField!
    @IBOutlet weak var graphPicker: NSDatePicker!
    @IBOutlet weak var textualPicker: NSDatePicker!
    @IBOutlet weak var box: NSBox!
    
    fileprivate let now = Date()
    
    var _endDate = Date()
    var endDate: Date {
        get {
            return Calendar.current.endOfDay(for: _endDate)
        }
        set {
            _endDate = newValue
            
            updateUIWithValue()
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        box.wantsLayer = true
        box.layer?.backgroundColor = NSColor(colorWithHex: "#F2F2F2")!.cgColor
        
        graphPicker.dateValue = now
        textualPicker.dateValue = now
        graphPicker.minDate = now
        textualPicker.minDate = now
        updateUI()
    }
    @IBAction func onTextualPicker(_ sender: Any) {
        graphPicker.dateValue = textualPicker.dateValue
        updateUI()
        _endDate = textualPicker.dateValue
    }
    @IBAction func onGraphPicker(_ sender: Any) {
        textualPicker.dateValue = graphPicker.dateValue
        updateUI()
        _endDate = textualPicker.dateValue
    }
    fileprivate func updateUIWithValue() {
        graphPicker.dateValue = endDate
        textualPicker.dateValue = endDate
        updateUI()
    }
    fileprivate func updateUI() {
        let to = graphPicker.dateValue
        rangeDateLabel.stringValue = "Until " + date2String(date: to)
        
        let dayInterval = Calendar.current.dateComponents([.day], from: now, to: to)
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
