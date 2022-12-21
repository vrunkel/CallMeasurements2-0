//
//  BCWaveOverviewForm.swift
//  bcAnalyze3
//
//  Created by Volker Runkel on 20.10.14.
//  Copyright (c) 2014 ecoObs GmbH. All rights reserved.
//

import Cocoa
import Quartz
import QuartzCore

// MouseMoved needs improvement: change cursor ONLY if necessary (bool flag!)

class BCWaveOverviewForm: NSView, CALayerDelegate {

    var soundLayer: CALayer!
    var sonaLayer: CALayer!
    var timeLayer: CALayer!
    var backBottom = CALayer()
    var backTop = CALayer()
    
    var callLayer: CALayer!
    var callLayerData: Array<(Float, Float)> = Array()
    
    override var wantsUpdateLayer: Bool
    {
        return true
    }
        
    weak var delegate: AppDelegate! {
        didSet {
            if delegate == nil { return }
            
            self.soundLayer.setNeedsDisplay()
            self.timeLayer.setNeedsDisplay()
        }
    }
    
    override var isOpaque: Bool { get { return true } }
    
    deinit {
        Swift.print(" wave overview deinitialized")
    }
    
    override func updateConstraints() {
        if #available(OSX 10.14, *) {
            self.backBottom.backgroundColor = NSColor(named: "OverviewBottomColor")!.cgColor
            self.backTop.backgroundColor = NSColor(named: "OverviewTopColor")!.cgColor
        } else {
            // Fallback on earlier versions
            self.backBottom.backgroundColor = CGColor(red: 0.951, green: 0.978, blue: 0.999, alpha: 1.000)
            self.backTop.backgroundColor = CGColor(red: 0.887, green: 0.966, blue: 1.000, alpha: 1.000)
        }
        super.updateConstraints()
        DispatchQueue.main.async {
            self.soundLayer.setNeedsDisplay()
        }
    }
    
    override func updateLayer() {
        //Swift.print("update layer")
        if #available(OSX 10.14, *) {
            self.backBottom.backgroundColor = NSColor(named: "OverviewBottomColor")!.cgColor
            self.backTop.backgroundColor = NSColor(named: "OverviewTopColor")!.cgColor
        } else {
            // Fallback on earlier versions
            self.backBottom.backgroundColor = CGColor(red: 0.951, green: 0.978, blue: 0.999, alpha: 1.000)
            self.backTop.backgroundColor = CGColor(red: 0.887, green: 0.966, blue: 1.000, alpha: 1.000)
        }
        super.updateLayer()
    }
    
    override func viewDidMoveToWindow() {
        //self.updateTrackingAreas()
                
        let myLayer = CALayer()
        myLayer.frame = self.bounds
        myLayer.masksToBounds = true
        myLayer.delegate = self
        myLayer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        self.layer = myLayer
        self.wantsLayer = true;
        
        self.backBottom.frame = self.bounds
        self.backBottom.frame.size.height = (self.frame.size.height - 63.0) / 2.0
        self.backBottom.autoresizingMask = CAAutoresizingMask.layerWidthSizable
        //self.backBottom.backgroundColor = CGColor(red: 0.951, green: 0.978, blue: 0.999, alpha: 1.000)
        self.backBottom.needsDisplayOnBoundsChange = false
        myLayer.addSublayer(self.backBottom)
        self.backBottom.setNeedsDisplay()
        
        self.backTop.frame = self.bounds
        self.backTop.frame.size.height = (self.frame.size.height - 63.0) / 2.0
        self.backTop.frame.origin.y = (self.frame.size.height - 63.0) / 2.0
        //self.backTop.backgroundColor = CGColor(red: 0.887, green: 0.966, blue: 1.000, alpha: 1.000)
        self.backTop.autoresizingMask = CAAutoresizingMask.layerWidthSizable
        self.backTop.needsDisplayOnBoundsChange = true
        myLayer.addSublayer(self.backTop)
        self.backTop.setNeedsDisplay()
        
        soundLayer = CALayer()
        soundLayer.frame = self.bounds
        soundLayer.frame.size.height = self.frame.size.height - 63.0
        //soundLayer.backgroundColor = CGColorCreateGenericGray(1, 1)
        soundLayer.borderColor = CGColor(gray: 0, alpha: 1)
        soundLayer.borderWidth = 1.0
        soundLayer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        soundLayer.needsDisplayOnBoundsChange = false
        soundLayer.delegate = self
        myLayer.addSublayer(soundLayer)
        soundLayer.setNeedsDisplay()
        
        sonaLayer = CALayer()
        sonaLayer.frame = self.bounds
        sonaLayer.frame.size.height = 128
        sonaLayer.frame.origin.y = self.frame.size.height - 64.0
        sonaLayer.backgroundColor = CGColor(gray: 1, alpha: 1)
        sonaLayer.masksToBounds = true
        sonaLayer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        sonaLayer.needsDisplayOnBoundsChange = false
        sonaLayer.transform = CATransform3DMakeRotation(CGFloat(Double.pi), 1.0, 0.0, 0.0)
        myLayer.addSublayer(sonaLayer)
        
        timeLayer = CALayer()
        timeLayer.frame = self.bounds
        timeLayer.frame.size.height = 10.0
        timeLayer.autoresizingMask = CAAutoresizingMask.layerWidthSizable
        timeLayer.needsDisplayOnBoundsChange = false
        timeLayer.opacity = 0.25
        timeLayer.delegate = self
        myLayer.addSublayer(timeLayer)
        timeLayer.setNeedsDisplay()
        
        self.callLayer = CALayer()
        self.callLayer.frame = self.bounds
        self.callLayer.autoresizingMask = CAAutoresizingMask.layerWidthSizable
        self.callLayer.needsDisplayOnBoundsChange = false
        self.callLayer.opacity = 0.25
        self.callLayer.delegate = self
        myLayer.addSublayer(self.callLayer)
        self.callLayer.setNeedsDisplay()
        
        let borderLayer = CALayer()
        borderLayer.frame = self.bounds
        borderLayer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        borderLayer.needsDisplayOnBoundsChange = false
        borderLayer.borderColor = CGColor(gray: 0, alpha: 1)
        borderLayer.borderWidth = 1.0
        myLayer.addSublayer(borderLayer)
        
    }
    
    // MARK: -Drawing and related
    
    func draw(_ layer: CALayer, in ctx: CGContext) {
        if delegate == nil {return}
        let width = layer.frame.size.width
        let halfSize = layer.frame.size.height/2.0
        
        let dataCount = self.delegate.waveOverviewData.count
        if dataCount==0 { return}
        
        if layer == soundLayer {
            
            //var xRes: Int! = dataCount / Int(width)
            var xRes: Float! = Float(width) / Float(dataCount)
            var step = 1
            while xRes < 0.25 {
                xRes = xRes*2.0
                step *= 2
            }
            xRes = xRes/Float(step)
            
            if #available(OSX 10.14, *) {
                let saved = NSAppearance.current
                NSAppearance.current = self.effectiveAppearance
                ctx.setStrokeColor(NSColor.textColor.cgColor)
                NSAppearance.current = saved
            } else {
                ctx.setStrokeColor(NSColor.textColor.cgColor)
            }
            //ctx.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 1)
            
            ctx.beginPath()
            var xform = CGAffineTransform(translationX: 0, y: halfSize)
            xform = xform.scaledBy(x: 1, y: halfSize)
            let path = CGMutablePath()
            path.move(to: CGPoint(x:0, y: 0), transform: xform)
            
            //var idx = 0
            for idx in 0..<dataCount {
                //let y: Float = sqrt(self.delegate.waveOverviewData[idx].max)
                let y: Float = self.delegate.waveOverviewData[idx]
                let x = (Float(idx)*xRes)
                path.addLine(to: CGPoint(x:CGFloat(x), y:CGFloat(y)), transform: xform)
                path.addLine(to: CGPoint(x:CGFloat(x), y:CGFloat(-y)), transform: xform)
            }
            
            ctx.addPath(path)
            ctx.strokePath()
        }
        
        if layer == self.callLayer {
            if self.callLayerData.isEmpty {
                return
            }
            var xRes: Float! = Float(width) / Float(self.delegate.mySoundContainer.header!.sampleCount)
            var step = 1
            while xRes < 0.25 {
                xRes = xRes*2.0
                step *= 2
            }
            xRes = xRes/Float(step)
            
            for (index,aCallTuple) in self.callLayerData.enumerated() {
                if index == self.delegate.callToDraw {
                    ctx.setStrokeColor(NSColor.red.cgColor)
                }
                else {
                     ctx.setStrokeColor(NSColor.textColor.cgColor)
                }
                ctx.stroke(CGRect(x: CGFloat(xRes*aCallTuple.0), y: 0, width: CGFloat(xRes*aCallTuple.1), height: self.frame.size.height - 63.0))
            }
            
        }
        
        if layer == timeLayer {
            var createLabels = false
            if let sublayers = layer.sublayers {
                if sublayers.count == 0 { createLabels = true }
            }
            else {
                createLabels = true
            }
            
            let maxTime = Int(1000*(Float(self.delegate.mySoundContainer.sampleCount) / Float(self.delegate.mySoundContainer.header!.samplerate) ))
            // Milliseconds!
            let xRes: Float = Float(self.frame.size.width) / (1000.0 * Float(self.delegate.mySoundContainer.sampleCount) / Float(self.delegate.mySoundContainer.header!.samplerate) )
            // Pixel pro Millisekunde
            ctx.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 1)
            ctx.beginPath()
            let path = CGMutablePath()
            var i = 0
            var interval = 50
            while maxTime / interval > 50 {
                interval += 50
            }
            while i < maxTime {
                var height: CGFloat = 10.0
                if i % 250 != 0 { height = 5.0 }
                let markerRect = self.backingAlignedRect(CGRect(x: CGFloat(Float(i)*xRes),y: 0.0, width: 1.0, height: height), options: AlignmentOptions.alignAllEdgesNearest)
                path.move(to: CGPoint(x: markerRect.origin.x, y:markerRect.origin.y ))
                path.addLine(to: CGPoint(x: markerRect.origin.x, y:markerRect.size.height ))
                
                if (createLabels && height > 5.0) {
                    let labelLayer = CATextLayer()
                    labelLayer.fontSize = 8.0
                    labelLayer.foregroundColor = CGColor(gray: 0, alpha: 1)
                    labelLayer.frame = CGRect(x: markerRect.origin.x+1.0, y: 6.0, width: 30.0, height: 10.0)
                    labelLayer.string = "\(i)"
                    layer.addSublayer(labelLayer)
                }
                
                i += interval
            }
            ctx.addPath(path)
            ctx.strokePath()
        }
    }
    
}
