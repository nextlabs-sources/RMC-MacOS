//
//  NXTextAttachmentCell.swift
//  SkyDrmUITest
//
//  Created by Walt (Shuiping) Li on 21/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa


class NXTextAttachmentCell: NSTextAttachmentCell {
    override func cellFrame(for textContainer: NSTextContainer, proposedLineFragment lineFrag: NSRect, glyphPosition position: NSPoint, characterIndex charIndex: Int) -> NSRect {
        let size = scaleImage(lineHeight: lineFrag.size.height)
        return NSMakeRect(0, (size.height - lineFrag.size.height)/2, size.width, size.height)
    }
    override func trackMouse(with theEvent: NSEvent, in cellFrame: NSRect, of controlView: NSView?, untilMouseUp flag: Bool) -> Bool {
        return super.trackMouse(with: theEvent, in: cellFrame, of: controlView, untilMouseUp: flag)
    }
    private func scaleImage(lineHeight: CGFloat) -> NSSize {
        var factor: CGFloat = 1.0
        guard let image = image else {
            return NSZeroSize
        }
        let imageSize = image.size
        if lineHeight < imageSize.height {
            factor = lineHeight * 0.8 / imageSize.height
        }
        return NSMakeSize(imageSize.width * factor, imageSize.height * factor)
    }
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView?) {
        if let image = image {
            image.draw(in: cellFrame, from: NSZeroRect, operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: nil)
        }
    }
}

