//
//  DetailWaveView.swift
//  CallMeasures2-0
//
//  Created by Volker Runkel on 01.05.20.
//  Copyright © 2020 ecoObs GmbH. All rights reserved.
//

import Cocoa

class DetailWaveView: NSView, CALayerDelegate {

    @IBOutlet weak var delegate: AppDelegate!
    var callLayer = CALayer()
    
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
        
        self.callLayer.frame = self.bounds
        self.callLayer.backgroundColor = CGColor(gray: 1, alpha: 1)
        self.callLayer.borderColor = CGColor(gray: 0, alpha: 1)
        self.callLayer.borderWidth = 1.0
        self.callLayer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        self.callLayer.needsDisplayOnBoundsChange = false
        self.callLayer.delegate = self
        myLayer.addSublayer(self.callLayer)
        self.callLayer.setNeedsDisplay()
        
    }
    
    func draw(_ layer: CALayer, in ctx: CGContext) {
        
        guard let call = self.delegate.bcCallsArray?[self.delegate.callToDraw] else {
            return
        }
        
        var callStart = ((call as! NSDictionary)["Startsample"] as! NSNumber).intValue
        var offset = 250
        callStart -= 250
        if callStart < 0 {
            callStart = 0
            offset = 0
        }
        let callDuration = ((call as! NSDictionary)["Sizesample"] as! NSNumber).intValue
        var tail = 250
        
        if callStart+callDuration+tail >= self.delegate.mySoundContainer.sampleCount {
            tail = 0
        }
        
        let soundData = self.delegate.mySoundContainer.soundData!
        let yRes = Float(NSHeight(self.frame) / 2)
        let xRes = NSWidth(self.frame) / CGFloat(callDuration+tail+offset)
        
        var max : Float = 0.0
        for i in stride(from: callStart, to: callStart+callDuration+tail+offset, by: 1) {
            if abs(soundData[i]) > max {
                max = abs(soundData[i])
            }
        }
                
        ctx.beginPath()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        for i in stride(from: callStart, to: callStart+callDuration+tail+offset, by: 1) {
            path.addLine(to: CGPoint(x: CGFloat(i-callStart) * xRes, y: CGFloat(yRes + yRes*(soundData[i]/max))))
        }
        
        ctx.addPath(path)
        ctx.strokePath()
        
        ctx.stroke(CGRect(x: CGFloat(offset) * xRes, y: 0.0, width: CGFloat(callDuration) * xRes, height: NSHeight(self.frame)))
        
    }
        
}
