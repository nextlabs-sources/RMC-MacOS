//
//  NXImageUtils.swift
//  skyDRM
//
//  Created by Kevin on 2017/2/7.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

public extension NSImage {
    func imageRotatedByDegreess(degrees:CGFloat) -> NSImage {
        
        var imageBounds = NSZeroRect ; imageBounds.size = self.size
        let pathBounds = NSBezierPath(rect: imageBounds)
        var transform = NSAffineTransform()
        transform.rotate(byDegrees: degrees)
        pathBounds.transform(using: transform as AffineTransform)
        let rotatedBounds:NSRect = NSMakeRect(NSZeroPoint.x, NSZeroPoint.y , self.size.width, self.size.height )
        let rotatedImage = NSImage(size: rotatedBounds.size)
        
        //Center the image within the rotated bounds
        imageBounds.origin.x = NSMidX(rotatedBounds) - (NSWidth(imageBounds) / 2)
        imageBounds.origin.y  = NSMidY(rotatedBounds) - (NSHeight(imageBounds) / 2)
        
        // Start a new transform
        transform = NSAffineTransform()
        // Move coordinate system to the center (since we want to rotate around the center)
        transform.translateX(by: +(NSWidth(rotatedBounds) / 2 ), yBy: +(NSHeight(rotatedBounds) / 2))
        transform.rotate(byDegrees: degrees)
        // Move the coordinate system bak to normal
        transform.translateX(by: -(NSWidth(rotatedBounds) / 2 ), yBy: -(NSHeight(rotatedBounds) / 2))
        // Draw the original image, rotated, into the new image
        rotatedImage.lockFocus()
        transform.concat()
        self.draw(in: imageBounds, from: NSZeroRect, operation: NSCompositingOperation.copy, fraction: 1.0)
        rotatedImage.unlockFocus()
        
        return rotatedImage
    }
}
extension NSImage {
    convenience init?(base64String: String?) {
        guard let str = base64String,
            let data = Data(base64Encoded: str, options: .ignoreUnknownCharacters) else {
            return nil
        }
        self.init(data: data)
    }
    class func zipImage(image: NSImage, fileSize: CGFloat) -> Data? {
        var compression:CGFloat = 0.9
        var compressedData: Data?
        var newImage = image
        repeat {
            guard let cgImage = newImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                return nil
            }
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            
            guard let data = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [NSBitmapImageRep.PropertyKey.compressionFactor: compression]) else {
                return nil
            }
            newImage = NSImage.compressImage(image: newImage, newWidth: newImage.size.width * compression)
            compressedData = data
            compression = compression * 0.90
        }
        while CGFloat((compressedData?.count)!) > fileSize
        return compressedData
    }
    class func compressImage(image: NSImage, newWidth: CGFloat) -> NSImage {
        let imageW = image.size.width
        let imageH = image.size.height
        let height = image.size.height / (image.size.width / newWidth)
        
        let widthScale = imageW/newWidth
        let heightScale = imageH/height
        
        let newImageW = widthScale > heightScale ? imageW/heightScale : newWidth
        let newImageH = widthScale > heightScale ? height : imageH/heightScale
        let newImage = NSImage(size: NSMakeSize(newImageW, newImageH))
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = NSImageInterpolation.low
        image.draw(in: NSMakeRect(0, 0, newImageW, newImageH))
        newImage.unlockFocus()
        return newImage
    }
    var base64String:String? {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        
        guard let data = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [NSBitmapImageRep.PropertyKey.compressionFactor: 1.0]) else {
            Swift.print("Couldn't create JPEG")
            return nil
        }
        
        return data.base64EncodedString(options: [.lineLength64Characters])
    }
}

