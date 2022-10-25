//
//  NXPageControl.swift
//  NXPageControl
//
//  Created by pchen on 23/01/2017.
//  Copyright © 2017 pchen. All rights reserved.
//

import Cocoa

// MARK: - MoveDorection
// direction

private enum MoveDirection {
    case left
    case right
    func toBool() -> Bool {
        switch self{
        case .left:
            return true
        case .right:
            return false
        }
    }
}

// MARK: - RubberPageControlConfig
// style config(default)

public struct PageControlConfig {
    var smallBubbleSize: CGFloat = 9
    var mainBubbleSize: CGFloat = 21
    var bubbleXOffsetSpace: CGFloat = 12
    var bubbleYOffsetSpace: CGFloat = 8
    var animationDuration: CFTimeInterval = 0.2
    var smallBubbleMoveRadius: CGFloat {return smallBubbleSize + bubbleXOffsetSpace}
    var backgroundColor: NSColor = NSColor(red: 0.357, green: 0.196, blue: 0.337, alpha: 0)
    var smallBubbleColor: NSColor = NSColor(red: 224.0/255, green: 224.0/255, blue: 224.0/255, alpha: 1)
    var mainBubbleColor: NSColor = NSColor.black
    var lineWidth: CGFloat = 3
}

open class PageControl: NSControl {

    open var numberOfPage: Int = 4 {
        didSet {
            if oldValue != numberOfPage {
                resetRubberIndicator()
            }
        }
    }
    
    /// current page
    fileprivate var _currentIndex = 0
    
    open var currentIndex: Int {
        get {
            return _currentIndex
        }
        set(newIndex) {
            changeIndexToValue(newIndex)
        }
    }
    
    /// event closure
    open var valueChange: ((Int) -> Void)?
    
    // style config
    open var styleConfig: PageControlConfig {
        didSet {
            resetRubberIndicator()
        }
    }
    
    open var isSupportClick: Bool = false
    
    /// init
    
    public init(frame: CGRect, count: Int, config: PageControlConfig) {
        numberOfPage = count
        styleConfig = config
        super.init(frame: frame)
        styleConfig = config
        self.setUpView()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        styleConfig = PageControlConfig()
        super.init(coder: aDecoder)
        self.setUpView()
    }
    
    // click gesture
    fileprivate var clickGesture: NSClickGestureRecognizer?
    
    /// all layers
    fileprivate var smallBubbles = [BubbleCell]()
    
    fileprivate var outsideMainBubble = CAShapeLayer()
    fileprivate var insideMainBubble = CAShapeLayer()
    
    fileprivate var backLineLayer = CAShapeLayer()
    
    /// bubble scale
    fileprivate let bubbleScale: CGFloat = 1/3.0
    
    /// for calculate
    fileprivate var xPointBegin: CGFloat = 0
    fileprivate var xPointEnd:   CGFloat = 0
    fileprivate var yPointBegin: CGFloat = 0
    fileprivate var yPointEnd:   CGFloat = 0
    
    
    fileprivate func setUpView() {
        
        if self.layer == nil {
            self.wantsLayer = true
            self.layer = CALayer()
        }
        
        let w = CGFloat(numberOfPage) * styleConfig.smallBubbleSize + CGFloat(numberOfPage + 1) * styleConfig.bubbleXOffsetSpace
        let h = styleConfig.smallBubbleSize + styleConfig.bubbleYOffsetSpace * 2
        let x = (bounds.width - w)/2
        let y = (bounds.height - h)/2
        
        if w > bounds.width || h > bounds.height {
            debugPrint("Draw UI control out off rect")
        }
        
        xPointBegin  = x
        xPointEnd    = x + w
        yPointBegin  = y
        yPointEnd    = y + h
        
        // Background line
        
        let lineFrame = CGRect(x: x, y: y, width: w, height: h)
        backLineLayer.path = NSBezierPath(roundedRect: lineFrame, xRadius: h/2, yRadius: h/2).cgPath
        backLineLayer.fillColor = styleConfig.backgroundColor.cgColor
        backLineLayer.zPosition = -1
        self.layer?.addSublayer(backLineLayer)
        
        // main bubble
        
        let center = CGPoint(x: x + styleConfig.bubbleXOffsetSpace + styleConfig.smallBubbleSize/2, y: y + styleConfig.bubbleYOffsetSpace + styleConfig.smallBubbleSize/2)
        let insideFrame = CGRect(x: center.x - styleConfig.smallBubbleSize/2, y: center.y - styleConfig.smallBubbleSize/2, width: styleConfig.smallBubbleSize, height: styleConfig.smallBubbleSize)
        let insideBound = CGRect(origin: CGPoint.zero, size: insideFrame.size)
        let outsideFrame = CGRect(x: center.x - styleConfig.mainBubbleSize/2, y: center.y - styleConfig.mainBubbleSize/2, width: styleConfig.mainBubbleSize, height: styleConfig.mainBubbleSize)
        let outsideBound = CGRect(origin: CGPoint.zero, size: outsideFrame.size)
        
        outsideMainBubble.path = NSBezierPath(ovalIn: outsideBound).cgPath
        outsideMainBubble.fillColor = nil
        outsideMainBubble.strokeColor = styleConfig.mainBubbleColor.cgColor
        outsideMainBubble.lineWidth = styleConfig.lineWidth
        outsideMainBubble.zPosition = 100
        outsideMainBubble.frame = outsideFrame
        self.layer?.addSublayer(outsideMainBubble)
        
        insideMainBubble.path      = NSBezierPath(ovalIn: insideBound).cgPath
        insideMainBubble.fillColor = styleConfig.mainBubbleColor.cgColor
        insideMainBubble.zPosition = 100
        insideMainBubble.frame = insideFrame
        self.layer?.addSublayer(insideMainBubble)
        
        // small bubble
        let bubbleOffset = styleConfig.smallBubbleSize + styleConfig.bubbleXOffsetSpace
        var bubbleFrame  = CGRect(x: x + styleConfig.bubbleXOffsetSpace + bubbleOffset, y: y + styleConfig.bubbleYOffsetSpace, width: styleConfig.smallBubbleSize, height: styleConfig.smallBubbleSize)
        for _ in 0 ..< (numberOfPage - 1) {
            let smallBubble       = BubbleCell(style: styleConfig)
            smallBubble.frame     = bubbleFrame
            self.layer?.addSublayer(smallBubble)
            smallBubbles.append(smallBubble)
            bubbleFrame.origin.x  += bubbleOffset
            smallBubble.zPosition = 1
        }
        
        /// add click gesture
        if clickGesture == nil {
            let click = NSClickGestureRecognizer(target: self, action: #selector(PageControl.clickBubble(_:)))
            addGestureRecognizer(click)
            clickGesture = click
        }
    }
    
    /// reset page control
    fileprivate func resetRubberIndicator() {
        changeIndexToValue(0)
        smallBubbles.forEach { $0.removeFromSuperlayer() }
        smallBubbles.removeAll()
        setUpView()
    }
    
    @objc fileprivate func clickBubble(_ ges: NSClickGestureRecognizer) {
        
        if !isSupportClick {
            return
        }
        
        let point = ges.location(in: self)
        if point.y > yPointBegin && point.y < yPointEnd && point.x > xPointBegin && point.x < xPointEnd {
            let index = Int(point.x - xPointBegin) / Int(styleConfig.smallBubbleMoveRadius)
            changeIndexToValue(index)
            valueChange?(currentIndex)
        }
    }
    
    // index change
    fileprivate func changeIndexToValue(_ toIndex: Int) {
        
        var index = toIndex
        if index >= numberOfPage { index = numberOfPage - 1 }
        if index < 0 { index = 0 }
        if index == currentIndex { return }
        
        let smallBubbleDirection = (index > currentIndex) ? MoveDirection.left : MoveDirection.right
        let range = (index > currentIndex) ? (currentIndex + 1)...index : index...(currentIndex-1)
        for index in range {
            let smallBubbleIndex = (smallBubbleDirection.toBool()) ? (index - 1) : (index)
            let smallBubble = smallBubbles[smallBubbleIndex]
            smallBubble.positionChange(smallBubbleDirection)
        }

        mainBubblePositionChange(toIndex: index)
        
        _currentIndex = index
    }
    
    // 大球动画
    fileprivate func mainBubblePositionChange(toIndex index: Int){
        
        insideMainBubble.frame = CGRect(x: xPointBegin + styleConfig.bubbleXOffsetSpace + styleConfig.smallBubbleMoveRadius * CGFloat(index), y: yPointBegin + styleConfig.bubbleYOffsetSpace, width: styleConfig.smallBubbleSize, height: styleConfig.smallBubbleSize)
        outsideMainBubble.frame = insideMainBubble.frame.insetBy(dx: -(styleConfig.mainBubbleSize - styleConfig.smallBubbleSize)/2, dy: -(styleConfig.mainBubbleSize - styleConfig.smallBubbleSize)/2)
    }
}

// MARK: - Small Bubble

private class BubbleCell: CAShapeLayer {
    
    fileprivate var bubbleLayer = CAShapeLayer()
    fileprivate var styleConfig: PageControlConfig
    
    init(style: PageControlConfig) {
        styleConfig = style
        super.init()
        setupLayer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        styleConfig = PageControlConfig()
        super.init(coder: aDecoder)
        setupLayer()
    }
    
    override init(layer: Any) {
        styleConfig = PageControlConfig()
        super.init(layer: layer)
    }
    
    fileprivate func setupLayer() {
        
        let bubbleBound = CGRect(x: 0, y: 0, width: styleConfig.smallBubbleSize, height: styleConfig.smallBubbleSize)
        bubbleLayer.path        = NSBezierPath(ovalIn: bubbleBound).cgPath
        bubbleLayer.fillColor   = styleConfig.smallBubbleColor.cgColor
        
        self.addSublayer(bubbleLayer)
    }
    
    func positionChange(_ direction: MoveDirection){
        
        var point = self.position
        point.x += styleConfig.smallBubbleMoveRadius * CGFloat(direction.toBool() ? -1 : 1)
        self.position = point

    }
}
