//
//  CallPreview.swift
//  RufbestimmungTestApp
//
//  Created by Volker Runkel on 02.11.23.
//

import Cocoa

class CallPreview: NSView, CALayerDelegate {
    
    private var dataLayer = CALayer()
    private var numberLayer = CALayer()
    private var callData: Array<CallMeasurements>?

    private let pixelPerMS: CGFloat = 3
    private let pixelPerHz: CGFloat = 2.5
    
    var selectedCall: Int = -1 {
        didSet {
            if let sublayers = self.dataLayer.sublayers {
                for sublayer in sublayers {
                    sublayer.setNeedsDisplay()
                }
            }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    func setupView() {
        let layer : CALayer = CALayer()
        layer.frame = self.frame
        layer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        self.layer = layer
        self.wantsLayer = true
        layer.borderWidth = 1.0
        
        self.dataLayer.frame = layer.frame
        self.dataLayer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        self.dataLayer.needsDisplayOnBoundsChange = true
        layer.addSublayer(dataLayer)
        
        self.numberLayer.frame = layer.frame
        self.numberLayer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        self.numberLayer.needsDisplayOnBoundsChange = true
        layer.addSublayer(numberLayer)
    }
    
    func updateCalls(_ callData: Array<CallMeasurements>) {
        var callIndex = 0
        var pos: CGFloat = 1
        for aCall in callData {
            let callLayer = CALayer()
            callLayer.frame = CGRect(x: pos*pixelPerMS, y: 0, width: pixelPerMS * CGFloat(aCall.callData["Size"]!), height: NSHeight(self.dataLayer.frame))
            callLayer.name = "\(callIndex)"
            callLayer.delegate = self
            callLayer.needsDisplayOnBoundsChange = true
            callLayer.autoresizingMask = [.layerHeightSizable]
            self.dataLayer.addSublayer(callLayer)
            callLayer.setNeedsDisplay()
            callIndex += 1
                        
            let callNumberLayer = CATextLayer()
            callNumberLayer.frame = CGRect(x: pos*pixelPerMS + 1, y: 0, width: 20, height: 20)
            callNumberLayer.foregroundColor = CGColor(gray: 0.5, alpha: 1)
            callNumberLayer.fontSize = 10
            callNumberLayer.string = "\(callIndex)"
            self.numberLayer.addSublayer(callNumberLayer)
            
            pos += pixelPerMS * CGFloat(aCall.callData["Size"]!)
            pos += 1
        }
        self.callData = callData
    }
    
    func draw(_ layer: CALayer, in ctx: CGContext) {

        if let name = layer.name, let arrayIndex = Int(name) {
            if arrayIndex >= (self.callData?.count ?? -1) {
                return
            }
            
            if selectedCall == arrayIndex {
                ctx.saveGState()
                ctx.setStrokeColor(NSColor.systemRed.cgColor)
                ctx.setLineWidth(2)
            }
            
            let call = self.callData![arrayIndex]
            ctx.stroke(NSMakeRect(0,CGFloat(call.callData["SFreq"]!)*pixelPerHz,1,1))
            //ctx.stroke(NSMakeRect(callSize*msFactor,CGFloat(call.callData["EFreq"]!)*freqFactor,1,1))
            
            var index = 1
            while call.callData["Freq\(index)"] != nil {
                ctx.stroke(NSMakeRect((CGFloat(index)/10)*pixelPerMS,CGFloat(call.callData["Freq\(index)"]!)*pixelPerHz,1,1))
                index += 1
            }
            if selectedCall == arrayIndex {
                ctx.restoreGState()
            }
        }
    }
    
}

class SingleCallView: NSView, CALayerDelegate {
    
    private var dataLayer = CALayer()
    var callData: CallMeasurements?
    
    var callParameters: Dictionary<String, Float>? {
        didSet {
            if callParameters != nil {
                if callParameters!["Dur"] ?? 0 < 8 {
                    pixelPerMS = 48
                }
                else if callParameters!["Dur"] ?? 0 < 12 {
                    pixelPerMS = 24
                } else {
                    pixelPerMS = 12
                }
                if callParameters!["Sfreq"] ?? 0 < 75 {
                    pixelPerHz = 4
                } else {
                    pixelPerHz = 2
                }
            }
        }
    }
    private var callMeasureLayer = CALayer()
    var selectedKey: String? {
        didSet {
            callMeasureLayer.setNeedsDisplay()
        }
    }

    private var pixelPerMS: CGFloat = 9
    private var pixelPerHz: CGFloat = 2
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    func setupView() {
        let layer : CALayer = CALayer()
        layer.frame = self.frame
        layer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        self.layer = layer
        self.wantsLayer = true
        layer.borderWidth = 1.0
        
        self.dataLayer.frame = layer.frame
        self.dataLayer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        self.dataLayer.needsDisplayOnBoundsChange = true
        self.dataLayer.delegate = self
        layer.addSublayer(dataLayer)
        
        self.callMeasureLayer.frame = layer.frame
        self.callMeasureLayer.autoresizingMask = [CAAutoresizingMask.layerWidthSizable, CAAutoresizingMask.layerHeightSizable]
        self.callMeasureLayer.needsDisplayOnBoundsChange = true
        self.callMeasureLayer.delegate = self
        layer.addSublayer(callMeasureLayer)
    }
    
    func draw(_ layer: CALayer, in ctx: CGContext) {
        let offset = CGFloat(10)
        
        if layer == dataLayer, let callData = callData {
            ctx.stroke(NSMakeRect(offset + 0,CGFloat(callData.callData["SFreq"]!)*pixelPerHz,1,1))
            //ctx.stroke(NSMakeRect(callSize*msFactor,CGFloat(call.callData["EFreq"]!)*freqFactor,1,1))
            
            var index = 1
            while callData.callData["Freq\(index)"] != nil {
                ctx.stroke(NSMakeRect(offset + (CGFloat(index)/10)*pixelPerMS,CGFloat(callData.callData["Freq\(index)"]!)*pixelPerHz,1,1))
                index += 1
            }
            
            /*ctx.beginPath()
            let size = callData.callData["Size"]! - 1
            ctx.setStrokeColor(CGColor.init(gray: 0.3, alpha: 0.3))
            ctx.move(to: CGPoint(x: offset + CGFloat(size)*pixelPerMS, y: 0))
            ctx.addLine(to: CGPoint(x: offset + CGFloat(size)*pixelPerMS, y: layer.frame.size.height))
            ctx.closePath()
            ctx.strokePath()
             */
        }
        if layer == callMeasureLayer, let callParameters = callParameters, let selectedKey = selectedKey, var callData = callData {
            
            if selectedKey == "Fmk" || selectedKey == "Rmk" {
                ctx.setStrokeColor(NSColor.systemPurple.cgColor)
                ctx.beginPath()
                let y = CGFloat(callParameters["Fmk"]!)*pixelPerHz
                ctx.move(to: CGPoint(x: 0, y:y))
                ctx.addLine(to: CGPoint(x: layer.frame.size.width, y:y))
                ctx.closePath()
                ctx.strokePath()
                
                let fontRef = CTFontCreateWithName("Helvetica" as CFString, 11.0, nil)
                var attrDict = [kCTFontAttributeName as String: fontRef, kCTForegroundColorAttributeName as String:NSColor.systemPurple.cgColor] as [String : Any]
                
                var line = CTLineCreateWithAttributedString(CFAttributedStringCreate(kCFAllocatorDefault, ("Fmk" as CFString), attrDict as CFDictionary))
                ctx.textPosition = CGPoint(x: NSWidth(layer.frame)-42, y: y+2)
                CTLineDraw(line, ctx)
                
                var xpos: Float = 0.0
                var rValue: Float = 0.0 // kHz / ms
                var ypos: Float = 0.0
                let size = callParameters["Dur"]!
                let pos = callData.myoPosD!
                xpos = pos*size + 0.05
                ypos = callData.myoFreq!
                rValue = callData.myoR! / 0.1
                                
                ctx.setStrokeColor(NSColor.systemMint.cgColor)
                ctx.beginPath()
                let x = CGFloat(xpos)*pixelPerMS + offset
                //ctx.translateBy(x: -(x + offset), y: 200)
                ctx.move(to: CGPoint(x: x, y:CGFloat(ypos)*pixelPerHz))
                ctx.addLine(to: CGPoint(x:offset + (300*pixelPerMS), y:CGFloat(ypos+(rValue*300))*pixelPerHz))
                ctx.move(to: CGPoint(x: x, y:CGFloat(ypos)*pixelPerHz))
                ctx.addLine(to: CGPoint(x:offset - (300*pixelPerMS), y:CGFloat(ypos+(rValue*(-300)))*pixelPerHz))
                ctx.closePath()
                ctx.strokePath()
                
                attrDict = [kCTFontAttributeName as String: fontRef, kCTForegroundColorAttributeName as String:NSColor.systemMint.cgColor] as [String : Any]
                line = CTLineCreateWithAttributedString(CFAttributedStringCreate(kCFAllocatorDefault, ("Rmk" as CFString), attrDict as CFDictionary))
                ctx.textPosition = CGPoint(x: 2, y: CGFloat(5 + ypos+(rValue*(-xpos)))*pixelPerHz)
                if CGFloat(5 + ypos+(rValue*(-xpos)))*pixelPerHz > NSHeight(layer.frame) {
                    ctx.textPosition = CGPoint(x: 2, y: NSHeight(layer.frame) - 15)
                }
                CTLineDraw(line, ctx)
                
            }
            else if selectedKey == "Fknee" || selectedKey == "Rknee" {
                ctx.setStrokeColor(NSColor.systemPurple.cgColor)
                ctx.beginPath()
                let y = CGFloat(callParameters["Fknee"]!)*pixelPerHz
                ctx.move(to: CGPoint(x: 0, y:y))
                ctx.addLine(to: CGPoint(x: layer.frame.size.width, y:y))
                ctx.closePath()
                ctx.strokePath()
                
                let fontRef = CTFontCreateWithName("Helvetica" as CFString, 11.0, nil)
                var attrDict = [kCTFontAttributeName as String: fontRef, kCTForegroundColorAttributeName as String:NSColor.systemPurple.cgColor] as [String : Any]
                
                var line = CTLineCreateWithAttributedString(CFAttributedStringCreate(kCFAllocatorDefault, ("Fknee" as CFString), attrDict as CFDictionary))
                ctx.textPosition = CGPoint(x: NSWidth(layer.frame)-42, y: y+2)
                CTLineDraw(line, ctx)
                
                var xpos: Float = 0.0
                var rValue: Float = 0.0 // kHz / ms
                var ypos: Float = 0.0
                let size = callParameters["Dur"]!
                
                let pos = callData.kneePosD!
                xpos = pos*size + 0.05
                ypos = callData.kneeFreq!
                rValue = callData.kneeR! / 0.1
                
                ctx.setStrokeColor(NSColor.systemMint.cgColor)
                ctx.beginPath()
                let x = CGFloat(xpos)*pixelPerMS + offset
                ctx.move(to: CGPoint(x: x, y:CGFloat(ypos)*pixelPerHz))
                ctx.addLine(to: CGPoint(x:offset + (300*pixelPerMS), y:CGFloat(ypos+(rValue*300))*pixelPerHz))
                ctx.move(to: CGPoint(x: x, y:CGFloat(ypos)*pixelPerHz))
                ctx.addLine(to: CGPoint(x:offset - (300*pixelPerMS), y:CGFloat(ypos+(rValue*(-300)))*pixelPerHz))
                ctx.closePath()
                ctx.strokePath()
                
                attrDict = [kCTFontAttributeName as String: fontRef, kCTForegroundColorAttributeName as String:NSColor.systemMint.cgColor] as [String : Any]
                line = CTLineCreateWithAttributedString(CFAttributedStringCreate(kCFAllocatorDefault, ("Rknee" as CFString), attrDict as CFDictionary))
                ctx.textPosition = CGPoint(x: 2, y: CGFloat(5 + ypos+(rValue*(-xpos)))*pixelPerHz)
                if CGFloat(5 + ypos+(rValue*(-xpos)))*pixelPerHz > NSHeight(layer.frame) {
                    ctx.textPosition = CGPoint(x: 2, y: NSHeight(layer.frame) - 15)
                }
                CTLineDraw(line, ctx)
            }
            else if selectedKey == "Fmidt" || selectedKey == "Rmidt" {
                ctx.setStrokeColor(NSColor.systemPurple.cgColor)
                ctx.beginPath()
                let y = CGFloat(callParameters["Fmidt"]!)*pixelPerHz
                ctx.move(to: CGPoint(x: 0, y:y))
                ctx.addLine(to: CGPoint(x: layer.frame.size.width, y:y))
                ctx.closePath()
                ctx.strokePath()
                
                let fontRef = CTFontCreateWithName("Helvetica" as CFString, 11.0, nil)
                var attrDict = [kCTFontAttributeName as String: fontRef, kCTForegroundColorAttributeName as String:NSColor.systemPurple.cgColor] as [String : Any]
                
                var line = CTLineCreateWithAttributedString(CFAttributedStringCreate(kCFAllocatorDefault, ("Fmidt" as CFString), attrDict as CFDictionary))
                ctx.textPosition = CGPoint(x: NSWidth(layer.frame)-42, y: y+2)
                CTLineDraw(line, ctx)
                
                var xpos: Float = 0.0
                var rValue: Float = 0.0 // kHz / ms
                var ypos: Float = 0.0
                let size = callParameters["Dur"]!
                
                xpos = (size*0.5) + 0.05
                ypos = callParameters["Fmidt"]!
                rValue = callParameters["Rmidt"]! / 0.1
                
                ctx.setStrokeColor(NSColor.systemMint.cgColor)
                ctx.beginPath()
                let x = CGFloat(xpos)*pixelPerMS + offset
                ctx.move(to: CGPoint(x: x, y:CGFloat(ypos)*pixelPerHz))
                ctx.addLine(to: CGPoint(x:offset + (300*pixelPerMS) , y:CGFloat(ypos+(rValue*300))*pixelPerHz))
                ctx.move(to: CGPoint(x: x, y:CGFloat(ypos)*pixelPerHz))
                ctx.addLine(to: CGPoint(x:offset - (300*pixelPerMS) , y:CGFloat(ypos+(rValue*(-300)))*pixelPerHz))
                ctx.closePath()
                ctx.strokePath()
                
                attrDict = [kCTFontAttributeName as String: fontRef, kCTForegroundColorAttributeName as String:NSColor.systemMint.cgColor] as [String : Any]
                line = CTLineCreateWithAttributedString(CFAttributedStringCreate(kCFAllocatorDefault, ("Rmidt" as CFString), attrDict as CFDictionary))
                ctx.textPosition = CGPoint(x: 2, y: 2 + CGFloat(5 + ypos+(rValue*(-xpos)))*pixelPerHz)
                CTLineDraw(line, ctx)
            }
            else if selectedKey == "Flastms" || selectedKey == "Rlastms" {
                ctx.setStrokeColor(NSColor.systemPurple.cgColor)
                ctx.beginPath()
                let y = CGFloat(callParameters["Flastms"]!)*pixelPerHz
                ctx.move(to: CGPoint(x: 0, y:y))
                ctx.addLine(to: CGPoint(x: layer.frame.size.width, y:y))
                ctx.closePath()
                ctx.strokePath()
                
                let fontRef = CTFontCreateWithName("Helvetica" as CFString, 11.0, nil)
                var attrDict = [kCTFontAttributeName as String: fontRef, kCTForegroundColorAttributeName as String:NSColor.systemPurple.cgColor] as [String : Any]
                
                var line = CTLineCreateWithAttributedString(CFAttributedStringCreate(kCFAllocatorDefault, (selectedKey as CFString), attrDict as CFDictionary))
                ctx.textPosition = CGPoint(x: NSWidth(layer.frame)-42, y: y+2)
                CTLineDraw(line, ctx)
                
                var xpos: Float = 0.0
                var rValue: Float = 0.0 // kHz / ms
                var ypos: Float = 0.0
                let size = callParameters["Dur"]!
                
                xpos = (size-1.0)
                ypos = callParameters["Flastms"]!
                rValue = callParameters["Rlastms"]!
                
                ctx.setStrokeColor(NSColor.systemMint.cgColor)
                ctx.beginPath()
                let x = CGFloat(xpos)*pixelPerMS + offset
                ctx.move(to: CGPoint(x: x, y:CGFloat(ypos)*pixelPerHz))
                ctx.addLine(to: CGPoint(x:offset + (300*pixelPerMS) , y:CGFloat(ypos+(rValue*300))*pixelPerHz))
                ctx.move(to: CGPoint(x: x, y:CGFloat(ypos)*pixelPerHz))
                ctx.addLine(to: CGPoint(x:offset - (300*pixelPerMS) , y:CGFloat(ypos+(rValue*(-300)))*pixelPerHz))
                ctx.closePath()
                ctx.strokePath()
                
                attrDict = [kCTFontAttributeName as String: fontRef, kCTForegroundColorAttributeName as String:NSColor.systemMint.cgColor] as [String : Any]
                line = CTLineCreateWithAttributedString(CFAttributedStringCreate(kCFAllocatorDefault, ("Rlastms" as CFString), attrDict as CFDictionary))
                ctx.textPosition = CGPoint(x: 2, y: 2 + CGFloat(5 + ypos+(rValue*(-xpos)))*pixelPerHz)
                CTLineDraw(line, ctx)
            }
            else {
                if selectedKey.starts(with:"F") || selectedKey.contains("freq") {
                    ctx.setStrokeColor(NSColor.systemPurple.cgColor)
                    ctx.beginPath()
                    let y = CGFloat(callParameters[selectedKey]!)*pixelPerHz
                    ctx.move(to: CGPoint(x: 0, y:y))
                    ctx.addLine(to: CGPoint(x: layer.frame.size.width, y:y))
                    ctx.closePath()
                    ctx.strokePath()
                    
                    let fontRef = CTFontCreateWithName("Helvetica" as CFString, 11.0, nil)
                    let attrDict = [kCTFontAttributeName as String: fontRef, kCTForegroundColorAttributeName as String:NSColor.systemPurple.cgColor] as [String : Any]
                    
                    let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(kCFAllocatorDefault, (selectedKey as CFString), attrDict as CFDictionary))
                    ctx.textPosition = CGPoint(x: NSWidth(layer.frame)-42, y: y+2)
                    CTLineDraw(line, ctx)
                }
                
                else if selectedKey.contains("R") {
                    var xpos: Float = 0.0
                    var rValue: Float = 0.0 // kHz / ms
                    var ypos: Float = 0.0
                    let size = callParameters["Dur"]!
                    if selectedKey == "Rmidt" {
                        xpos = size * 0.5
                        ypos = callData.Fmidt!
                        rValue = callData.Rmitte
                    }
                    
                    ctx.setStrokeColor(NSColor.systemMint.cgColor)
                    ctx.beginPath()
                    let x = CGFloat(xpos)*pixelPerMS
                    ctx.translateBy(x: -(x + offset), y: 300)
                    ctx.move(to: CGPoint(x: x, y:CGFloat(ypos)*pixelPerHz))
                    ctx.addLine(to: CGPoint(x:offset + x + 300 , y:CGFloat(ypos+(rValue*300))*pixelPerHz))
                    ctx.closePath()
                    ctx.strokePath()
                }
                else if selectedKey.contains("Alpha") {
                    print("Winkel :)")
                }
                else if selectedKey.contains("X") {
                    return
                }
            }
        }
    }
    
    func saveImage() {
        let sp = NSSavePanel()
        sp.title = NSLocalizedString("Save to image", comment:"Save to image")
        sp.canCreateDirectories = true
        sp.isExtensionHidden = false
        sp.allowedContentTypes = [.pdf]
        sp.allowsOtherFileTypes = false
        sp.nameFieldStringValue = self.selectedKey ?? "No key selected"
        if sp.runModal() == NSApplication.ModalResponse.OK, let url = sp.url {
            let width: CGFloat = NSWidth(self.bounds)
            let height: CGFloat = NSHeight(self.bounds)
            
            let pdfData = NSMutableData()
            let pdfConsumer = CGDataConsumer(data: pdfData)
            var mediaBox = CGRect(x: 0, y: 0, width: width, height: height)
            let pdfContext = CGContext(consumer: pdfConsumer!, mediaBox: &mediaBox, nil)
            
            pdfContext?.beginPage(mediaBox: &mediaBox)
            self.layer?.render(in: pdfContext!)
            
            pdfContext?.endPage()
            pdfContext?.closePDF()
            
            do {
                try pdfData.write(to: url)
            }
            catch let error as NSError {
                NSApp.presentError(error)
            }
            catch {
                Swift.print("critical error in \((#file, #line, #function))")
            }
        }
    }
    
}
