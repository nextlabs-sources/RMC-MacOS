//
//  NXProgressIndicatorView.swift
//  SkyDrmUITest
//
//  Created by nextlabs on 09/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXMySpaceIndicatorView: NSView {

    @IBOutlet weak var usedLabel: NSTextField!
    @IBOutlet weak var freeLabel: NSTextField!
    @IBOutlet weak var myDriveLabel: NSTextField!
    @IBOutlet weak var myVaultLabel: NSTextField!
    private var myDrive: CGFloat = 0
    private var myVault: CGFloat = 0
    private var total: CGFloat = 0
    
    private let indicatorheight: CGFloat = 10
    private let indicatorWidth: CGFloat = 10
    
    private let borderColor = NSColor(red: 212/255, green: 212/255, blue: 223/255, alpha: 1.0)
    private let mydriveColor = NSColor(red: 52/255, green: 153/255, blue: 76/255, alpha: 1.0)
    private let myvaultColor = NSColor(red: 79/255, green: 79/255, blue: 79/255, alpha: 1.0)
    private let gap = CGFloat(1)
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawProgressInternal()
    }
    func drawProgress(myDrive: CGFloat, myVault: CGFloat, total: CGFloat) {
        self.myDrive = myDrive
        self.myVault = myVault
        self.total = total
        draw(frame)
    }
    
    private func drawProgressInternal(){
        
        // draw whole
        let totalRect = CGRect(x: 0, y: frame.height - indicatorheight, width: frame.width, height: indicatorheight)
        let context = NSGraphicsContext.current()?.cgContext
        drawRoundedRect(rect: totalRect, inContext: context,
                        radius: totalRect.height / 2,
                        borderColor: borderColor.cgColor,
                        fillColor: NSColor.white.cgColor)
        guard total != 0,
            myDrive + myVault <= total else {
                return
        }
        //draw mydrive 
        let myDriveWidth = myDrive * frame.width / total
        var myDrvieClipRect = CGRect()
        if myDriveWidth > gap && myDriveWidth != frame.width{
            myDrvieClipRect = CGRect(x: 0, y: frame.height - indicatorheight, width: myDriveWidth - gap, height: indicatorheight)
        }
        else if myDriveWidth == frame.width {
            myDrvieClipRect = CGRect(x: 0, y: frame.height - indicatorheight, width: myDriveWidth, height: indicatorheight)
        }
        context?.saveGState()
        context?.clip(to: myDrvieClipRect)
        drawRoundedRect(rect: totalRect, inContext: context, radius: totalRect.height / 2, borderColor: nil, fillColor: mydriveColor.cgColor)
        context?.restoreGState()
        
        //draw myVault
        let myVaultWidth = myVault * frame.width / total
        let myVaultClipRect = CGRect(x: myDriveWidth, y: frame.height - indicatorheight, width: myVaultWidth , height: indicatorheight)
        context?.saveGState()
        context?.clip(to: myVaultClipRect)
        drawRoundedRect(rect: totalRect, inContext: context, radius: totalRect.height / 2, borderColor: nil, fillColor: myvaultColor.cgColor)
        context?.restoreGState()

        //Label
        let usedStr = String(format: "%.2f", myDrive + myVault)
        usedLabel.stringValue = "\(usedStr) MB used"
        let freeStr = String(format: "%.2f", total - myDrive - myVault)
        freeLabel.stringValue = "\(freeStr) MB free"
        let myDriveStr = String(format: "%.2f", myDrive)
        let myVaultStr = String(format: "%.2f", myVault)
        myDriveLabel.stringValue = "MyDrive - \(myDriveStr) MB"
        myVaultLabel.stringValue = "MyVault - \(myVaultStr) MB"
        
        //draw block
        let myDriveBlockRect = CGRect(x: 0, y: 0, width: indicatorheight, height: indicatorheight)
        drawRoundedRect(rect: myDriveBlockRect, inContext: context, radius: indicatorheight/5, borderColor: nil, fillColor: mydriveColor.cgColor)
        let myVaultBlockRect = CGRect(x: myVaultLabel.frame.minX - indicatorWidth - 10, y: 0, width: indicatorWidth, height: indicatorheight)
        drawRoundedRect(rect: myVaultBlockRect, inContext: context, radius: indicatorheight/5, borderColor: nil, fillColor: myvaultColor.cgColor)
        
        //dotted line
        let lineY = (usedLabel.frame.minY - myDriveLabel.frame.maxY) / 2 + myDriveLabel.frame.maxY
        let startLine = CGPoint(x: totalRect.width/4, y: lineY)
        let endLine = CGPoint(x: totalRect.width*3/4, y: lineY)
        drawDashLine(start: startLine, end: endLine, context: context, color: myvaultColor.cgColor)
        
    }
    
    private func drawRoundedRect(rect: CGRect, inContext context: CGContext?,
                                 radius: CGFloat, borderColor: CGColor?, fillColor: CGColor) {
        // 1
        let path = CGMutablePath()
        
        // 2
        path.move( to: CGPoint(x:  rect.midX, y:rect.minY ))
        path.addArc( tangent1End: CGPoint(x: rect.maxX, y: rect.minY ),
                     tangent2End: CGPoint(x: rect.maxX, y: rect.maxY), radius: radius)
        path.addArc( tangent1End: CGPoint(x: rect.maxX, y: rect.maxY ),
                     tangent2End: CGPoint(x: rect.minX, y: rect.maxY), radius: radius)
        path.addArc( tangent1End: CGPoint(x: rect.minX, y: rect.maxY ),
                     tangent2End: CGPoint(x: rect.minX, y: rect.minY), radius: radius)
        path.addArc( tangent1End: CGPoint(x: rect.minX, y: rect.minY ),
                     tangent2End: CGPoint(x: rect.maxX, y: rect.minY), radius: radius)
        path.closeSubpath()
        
        // 3
        if borderColor != nil {
            context?.setLineWidth(1.0)
            context?.setStrokeColor(borderColor!)
        }
        context?.setFillColor(fillColor)
        
        // 4
        context?.addPath(path)
        context?.drawPath(using: .fillStroke)
    }
    private func drawDashLine(start: CGPoint, end: CGPoint, context: CGContext?, color: CGColor) {
        context?.saveGState()
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)
        context?.addPath(path)
        
        context?.setStrokeColor(color)
        context?.setLineWidth(1.0)
        context?.setLineDash(phase: 0, lengths: [5,5])
        context?.strokePath()
        
    }
}
