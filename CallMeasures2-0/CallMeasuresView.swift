//
//  CallMeasuresView.swift
//  CallMeasures2-0
//
//  Created by Volker Runkel on 02.05.20.
//  Copyright © 2020 ecoObs GmbH. All rights reserved.
//

import Cocoa

class CallMeasuresView: NSView, CALayerDelegate {
    
    @IBOutlet weak var delegate: AppDelegate!
    
    private let axisLayer = CALayer()
    let callLayer = CALayer()
    private var sonaLayer = CALayer()
    
    private var kHzMax: CGFloat = 191.0
    var msMax: CGFloat = 18.0 {
        didSet {
            self.callLayer.setNeedsDisplay()
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
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
        
        var rect = self.bounds
        rect.size.height = 512
        rect.origin.y = 0
        self.sonaLayer.frame = rect
        self.sonaLayer.transform = CATransform3DMakeRotation(CGFloat(Double.pi), 1.0, 0.0, 0.0)
        self.sonaLayer.masksToBounds = true
        self.sonaLayer.contentsGravity = .topLeft
        //self.sonaLayer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        self.sonaLayer.needsDisplayOnBoundsChange = true
        self.sonaLayer.zPosition = 0
        self.sonaLayer.opacity = 0.2
        myLayer.addSublayer(sonaLayer)
        
        self.callLayer.frame = self.bounds
        //self.callLayer.backgroundColor = CGColor(gray: 1, alpha: 1)
        self.callLayer.borderColor = CGColor(gray: 0, alpha: 1)
        self.callLayer.borderWidth = 1.0
        self.callLayer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        self.callLayer.needsDisplayOnBoundsChange = false
        self.callLayer.delegate = self
        myLayer.addSublayer(self.callLayer)
        self.callLayer.setNeedsDisplay()
        
        self.axisLayer.frame = self.bounds
        self.axisLayer.delegate = self
        self.axisLayer.name = "AxisLayer"
        self.axisLayer.borderWidth = 1.0
        self.axisLayer.zPosition = 10
        self.axisLayer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        self.axisLayer.needsDisplayOnBoundsChange = true
        myLayer.addSublayer(axisLayer)
        self.axisLayer.setNeedsDisplay()
                
    }
    
    func calcSona() {
        guard let call = self.delegate.callMeasures?[self.delegate.callToDraw] else {
            return
        }
        
        var overlap: Float = 96.875
        var startSample = call.callData["Startsample"]!
        if self.msMax == 7 {
            overlap = 98.828125
            startSample -= Float(self.delegate.mySoundContainer.header!.samplerate) * 0.0039
        }
        else {
            startSample -= Float(self.delegate.mySoundContainer.header!.samplerate) * 0.004
        }
        let window = WindowFunctions.seventermharris
        
        /*switch self.msMax {
        case 9 :
            startSample -= Float(self.delegate.mySoundContainer.header!.samplerate) * 0.00275
        case 13 :
            startSample -= Float(self.delegate.mySoundContainer.header!.samplerate) * 0.003
            overlap = 98.828125
        case 25:
            startSample -= Float(self.delegate.mySoundContainer.header!.samplerate) * 0.0029
            overlap = 97.8515625
        default:
            startSample -= Float(self.delegate.mySoundContainer.header!.samplerate) * 0.003
        }*/
        
        
        
        let fftParameters = FFTSettings(fftSize: 1024, overlap: overlap / 100.0, window: window)
        
        if startSample < 0 {
            startSample = 0
        }
        
        var sizeSamples = call.callData["Sizesample"]!
        sizeSamples += Float(self.delegate.mySoundContainer.header!.samplerate) * 0.03
        if sizeSamples >= Float(self.delegate.mySoundContainer.header!.sampleCount) {
            sizeSamples = Float(self.delegate.mySoundContainer.header!.sampleCount) - startSample
        }
        
        if let sonaImage = self.delegate.mySoundContainer.sonagramImage(from: Int(startSample), size: Int(sizeSamples), fftParameters: fftParameters) {
            self.sonaLayer.contents = sonaImage
        }
        
        /*Swift.print(resultSize)
        Swift.print(NSWidth(self.frame))
        Swift.print("----")*/
    }
    
    func draw(_ layer: CALayer, in ctx: CGContext) {
        
        guard var call = self.delegate.callMeasures?[self.delegate.callToDraw] else {
            return
        }
        
        let pixelPerHz =  NSHeight(self.frame) / self.kHzMax
        let pixelPerMS = NSWidth(self.frame) / self.msMax
        if layer == self.axisLayer {
            let fontRef: CTFont
            let attrDict: Dictionary<String,AnyObject>
            
            fontRef = CTFontCreateWithName("Helvetica" as CFString, 10.0, nil)
            attrDict = [kCTFontAttributeName as String: fontRef, kCTForegroundColorAttributeName as String:CGColor(gray: 0,alpha: 1), ]
            
            let steps: CGFloat = 10 * pixelPerHz
            
            ctx.beginPath()
            
            for index in 1..<15 {
                let y = floor(CGFloat(index)*steps)+0.5
                ctx.move(to: CGPoint(x:0, y:y))
                ctx.addLine(to: CGPoint(x:NSWidth(self.frame), y:y))
                let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(kCFAllocatorDefault, "\(Int(CGFloat(index*10)))" as CFString, attrDict as CFDictionary))
                ctx.textPosition = CGPoint(x: 2, y: CGFloat(index)*steps+2)
                CTLineDraw(line, ctx);
            }
            ctx.setStrokeColor(NSColor.gray.cgColor)
            ctx.setLineWidth(0.5)
            ctx.strokePath()
        }
        if layer == self.callLayer {
            
            let overlayColor: NSColor = NSColor.gray
            
            ctx.setStrokeColor(overlayColor.cgColor)
            
            let offset = CGFloat(3) //(self.msMax-4-CGFloat(call.callData["Size"]!))
            let callSize = offset + CGFloat(call.callData["Size"]!)
            
            ctx.stroke(NSMakeRect((offset)*pixelPerMS,CGFloat(call.callData["SFreq"]!)*pixelPerHz,3,3))
            ctx.stroke(NSMakeRect(callSize*pixelPerMS,CGFloat(call.callData["EFreq"]!)*pixelPerHz,3,3))
            
            var index = 1
            while call.callData["Freq\(index)"] != nil {
                ctx.stroke(NSMakeRect((offset+(CGFloat(index)/10))*pixelPerMS,CGFloat(call.callData["Freq\(index)"]!)*pixelPerHz,3,3))
                if self.delegate.debug {
                    Swift.print("\(index) : \(call.callData["Freq\(index)"]!)")
                }
                index += 1
            }
            
            ctx.setStrokeColor(NSColor.red.cgColor)
            ctx.setLineWidth(1.5)
            
            let _ = call.avgSteig
            
            let _ = call.medSteig
            
            if let kneeFreq = call.kneeFreq, let kneePos = call.kneePos {
                ctx.beginPath()
                let kneeCenterX = (offset + CGFloat(kneePos) * 0.1) * pixelPerMS
                ctx.move(to: CGPoint(x: offset + kneeCenterX - 3, y:CGFloat(kneeFreq)*pixelPerHz))
                ctx.addLine(to: CGPoint(x: offset + kneeCenterX + 3, y:CGFloat(kneeFreq)*pixelPerHz))
                ctx.move(to: CGPoint(x: offset + kneeCenterX, y:CGFloat(kneeFreq)*pixelPerHz-3))
                ctx.addLine(to: CGPoint(x: offset + kneeCenterX, y:CGFloat(kneeFreq)*pixelPerHz+3))
                ctx.closePath()
                ctx.strokePath()
            }
            
            ctx.setStrokeColor(NSColor.orange.cgColor)
            
            if let myoFreq = call.myoFreq, let myoPos = call.myoPos {
                let myoCenterX = (offset + CGFloat(myoPos) * 0.1) * pixelPerMS
                ctx.strokeEllipse(in: CGRect(x: offset + myoCenterX-3, y: (CGFloat(myoFreq)*pixelPerHz)-3, width: 6, height: 6))
            }
            
            ctx.setStrokeColor(NSColor.blue.cgColor)
            if let medianFreq = call.medianFreq {
                ctx.beginPath()
                ctx.move(to: CGPoint(x: offset * pixelPerMS, y:CGFloat(medianFreq)*pixelPerHz))
                ctx.addLine(to: CGPoint(x: callSize * pixelPerMS, y:CGFloat(medianFreq)*pixelPerHz))
                ctx.closePath()
                ctx.strokePath()
            }
            
            ctx.setStrokeColor(NSColor.green.cgColor)
            
            if let middleFreq = call.middleFreq {
                ctx.beginPath()
                ctx.move(to: CGPoint(x:  offset * pixelPerMS, y:CGFloat(middleFreq)*pixelPerHz))
                ctx.addLine(to: CGPoint(x: callSize * pixelPerMS, y:CGFloat(middleFreq)*pixelPerHz))
                ctx.closePath()
                ctx.strokePath()
            }
            if call.dqcf! >= 1 && call.dfm! >= 1 {
                call.callType = 2
            }
            else if call.dqcf! < 1 && call.dfm! >= 1 {
                call.callType = 3
            }
            else if call.dqcf! >= 1 && call.dfm! < 1 {
                call.callType = 1
            }
        }
        
    }
    
}
