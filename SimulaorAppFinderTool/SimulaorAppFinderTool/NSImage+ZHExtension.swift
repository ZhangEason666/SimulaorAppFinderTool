//
//  NSImage+ZHExtension.swift
//  SimulaorFinder
//
//  Created by 张衡 on 2018/1/10.
//  Copyright © 2018年 张衡. All rights reserved.
//

import Cocoa

extension NSImage {
    
    
    
    /// 返回圆角
    public func roundCorners(image: NSImage, toSize: NSSize) -> NSImage {
        
        guard let existingImg = self.scaleImage(image: image, toSize: toSize) else {
            
            return image
        }
        let existingImage = existingImg
        let existingSize = existingImage.size
        let newSize = NSMakeSize(existingSize.width, existingSize.height)
        
        let composedImage = NSImage(size: newSize)
        composedImage.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        
        let imageFrame = NSRectFromCGRect(CGRect(x: 0, y: 0, width: existingSize.width, height: existingSize.height))
        
        let clipPath = NSBezierPath(roundedRect: imageFrame, xRadius: 3, yRadius: 3)
        clipPath.windingRule = .evenOddWindingRule
        clipPath.addClip()
        
        existingImage.draw(at: NSPoint.zero, from: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), operation: NSCompositingOperation.sourceOver, fraction: 1)
        
        composedImage.unlockFocus()
        
        return composedImage
    }
    
    /// 按照给定的size压缩图片
    public func scaleImage(image: NSImage, toSize: NSSize) -> NSImage? {
        let sourceImage = image
        
        if sourceImage.isValid == true {
            let smallImage = NSImage(size: toSize)
            smallImage.lockFocus()
            sourceImage.size = toSize
            
            NSGraphicsContext.current?.imageInterpolation = .high

            sourceImage.draw(at: NSPoint.zero, from: NSRect(x: 0, y: 0, width: toSize.width, height: toSize.height), operation: NSCompositingOperation.copy, fraction: 1.0)
            smallImage.unlockFocus()
            
            
          return sourceImage
        }
        
        return nil
        
    }





















}

