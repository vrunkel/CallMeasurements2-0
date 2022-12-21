//
//  DebugController.swift
//  CallMeasures2-0
//
//  Created by Volker Runkel on 28.11.22.
//  Copyright © 2022 ecoObs GmbH. All rights reserved.
//

import Cocoa

class DebugController: NSWindowController {
    
    weak var delegate: AppDelegate!
    
    var marker: Array<Float>? { // start, stop of marker like for example zcwindowsize
        didSet {
            self.markerLayer.setNeedsDisplay()
        }
    }
    var startSample: Int?
    var sizeSamples: Int? {
        didSet {
            if self.sizeSamples != nil {
                DispatchQueue.main.async {
                    self.waveView!.frame.size.width = CGFloat(self.sizeSamples!-self.startSample!)
                }
            }
        }
    }
    var tempresults_time: Array<Float> = Array()
    var tempresults_wave: Array<Float> = Array() {
        didSet {
            DispatchQueue.main.async {
                self.firstStepPanel.makeKeyAndOrderFront(nil)
                self.firstStepTable.reloadData()
                self.waveLayer.setNeedsDisplay()
            }
        }
    }
    var xtValues = Array<Float>()
    var regressionParams = Array<Float>()
    var regressionMSEPerWindow = Array<Float>()
    
    var fontRef : CTFont?
    var attrDict : Dictionary<String, Any>? //= [kCTFontAttributeName as String: fontRef, kCTForegroundColorAttributeName as String:NSColor.white.cgColor] as [String : Any]
    
    @IBOutlet weak var debugFirstStep: NSButton!
    @IBOutlet weak var debugRegression: NSButton!
    @IBOutlet weak var debugShowRegressionOutsideMSE: NSButton!
    @IBOutlet weak var debugRegressionSpeed: NSSegmentedControl!
    var debugRegressionPause: Bool = false
    @IBOutlet weak var debugCallStartRegression: NSButton!
    var callStartEndRegression = Array<(Int, Int)>()
    @IBOutlet weak var callStartHideRegressionSteps: NSButton!
    
    @IBOutlet weak var debugShowzcData: NSButton!
    
    @IBOutlet var firstStepPanel: NSPanel!
    @IBOutlet weak var firstStepTable: NSTableView!
    
    @IBOutlet var regressionPanel: NSPanel!
    @IBOutlet weak var regressionView: NSView!
    let regressionDataLayer = CALayer()
    
    @IBOutlet var wavePanel: NSPanel!
    @IBOutlet weak var waveScrollView: NSScrollView!
    var waveView: NSView?
    let waveLayer = CALayer()
    let measurementRegressionLayer = CALayer()
    var markerLayer = CALayer()
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.fontRef = CTFontCreateWithName("Helvetica" as CFString, 10.0, nil)
        self.attrDict = [kCTFontAttributeName as String: fontRef!, kCTForegroundColorAttributeName as String:NSColor.systemRed.cgColor] as [String : Any]

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        self.waveView = NSView(frame: self.waveScrollView.bounds)
        self.waveScrollView.documentView = self.waveView
        
        let layer = CALayer()
        layer.frame = self.waveView!.bounds
        layer.autoresizingMask = .layerWidthSizable
        layer.backgroundColor = CGColor.white
        self.waveView!.layer = layer
        self.waveView!.wantsLayer = true
        
        self.waveLayer.frame = layer.frame
        self.waveLayer.delegate = self
        self.waveLayer.autoresizingMask = .layerWidthSizable
        layer.addSublayer(self.waveLayer)
        
        self.measurementRegressionLayer.frame = layer.frame
        self.measurementRegressionLayer.delegate = self
        self.measurementRegressionLayer.autoresizingMask = .layerWidthSizable
        layer.addSublayer(self.measurementRegressionLayer)
        
        self.markerLayer = CALayer()
        self.markerLayer.frame = layer.frame
        self.markerLayer.autoresizingMask = .layerWidthSizable
        self.markerLayer.delegate = self
        layer.addSublayer(self.markerLayer)
        
        let regLayer = CALayer()
        regLayer.frame = self.waveView!.bounds
        regLayer.autoresizingMask = .layerWidthSizable
        regLayer.backgroundColor = CGColor.white
        regLayer.borderColor = CGColor.black
        regLayer.borderWidth = 1.0
        self.regressionView!.layer = regLayer
        self.regressionView!.wantsLayer = true
        
        self.regressionDataLayer.frame = layer.frame
        self.regressionDataLayer.delegate = self
        self.regressionDataLayer.autoresizingMask = .layerWidthSizable
        regLayer.addSublayer(self.regressionDataLayer)
        
    }
    
    @IBAction func continueGroup(_ sender: Any) {
        callFinderGroup.leave()
        if self.debugRegressionPause {
            self.debugRegressionPause = false
        }
    }
    
    @IBAction func pauseLoop(_ sender: NSButton) {
        self.debugRegressionPause = true
    }
    
    @IBAction func showWavePanel(_ sender: Any) {
        self.wavePanel.orderFront(nil)
        self.waveLayer.setNeedsDisplay()
    }
    
}

extension DebugController: CALayerDelegate {
    
    func draw(_ layer: CALayer, in ctx: CGContext) {
        if layer == self.waveLayer {
            guard let startSample = self.startSample, let size = self.sizeSamples, let delegate = self.delegate else {
                return
            }
            if self.tempresults_wave.first == 0 { // drawing regression data / call measurements
                let baseSample = self.tempresults_time[1]
                let maxkHzFactor = Double(NSHeight(layer.frame) / 200.0)
                
                for (index, aFrequency) in self.tempresults_wave.enumerated() {
                    if index == 0 {
                        continue
                    }
                    let x = Double(10 + (self.tempresults_time[index] - baseSample))
                    let y = Double(aFrequency) * maxkHzFactor
                    ctx.strokeEllipse(in: CGRect(x: x, y: y, width: 1.0, height: 1.0))
                }
                
                return
            }
            var idx = 0
            let yScale = NSHeight(layer.frame) / 2
            let offset = NSHeight(layer.frame) / 2
            ctx.beginPath()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 0))
            for aSample in delegate.mySoundContainer.soundData![startSample ..< size] {
                path.addLine(to: CGPoint(x: CGFloat(idx), y: offset + CGFloat(aSample) * yScale))
                idx += 1
            }
            ctx.addPath(path)
            ctx.strokePath()
        }
        if layer == self.measurementRegressionLayer {
            let baseSample = self.tempresults_time[1]
            let maxkHzFactor = NSHeight(layer.frame) / 200.0
            
            if self.callStartEndRegression.count > 0 {
                for aCallFragment in self.callStartEndRegression {
                    if aCallFragment.1 >= self.tempresults_time.count { continue }
                    ctx.stroke(CGRect(x: CGFloat(self.tempresults_time[aCallFragment.0]-baseSample), y: 0.01, width: CGFloat(self.tempresults_time[aCallFragment.1]-self.tempresults_time[aCallFragment.0]), height: 0.98 * NSHeight(layer.frame)))
                }
                return
            }
            
            // (a+(Double(zcTimeData[k]-zero)*b)))
            let x1 = (self.tempresults_time[Int(self.regressionMSEPerWindow.first!)] - baseSample)
            let x2 = (self.tempresults_time[Int(self.regressionMSEPerWindow[1])] - baseSample)
            let y1 = self.regressionMSEPerWindow[2] + ((0 /*self.tempresults_time[Int(self.regressionMSEPerWindow[0])] - baseSample*/) * self.regressionMSEPerWindow[3])
            let y2 = self.regressionMSEPerWindow[2] + ((self.tempresults_time[Int(self.regressionMSEPerWindow[1])] - self.tempresults_time[Int(self.regressionMSEPerWindow[0])]) * self.regressionMSEPerWindow[3])
            
            var formse = 0.06
            if nil != UserDefaults.standard.object(forKey: "formse") {
                formse = UserDefaults.standard.double(forKey: "formse")
            }
            
            if self.regressionMSEPerWindow[4] <= Float(formse) {
                ctx.setStrokeColor(NSColor.systemGreen.cgColor)
            }
            else {
                ctx.setStrokeColor(NSColor.systemRed.cgColor)
            }
            ctx.beginPath()
            ctx.move(to: CGPoint(x: CGFloat(x1), y: CGFloat(y1) * maxkHzFactor))
            ctx.addLine(to: CGPoint(x: CGFloat(x2), y: CGFloat(y2) * maxkHzFactor))
            ctx.closePath()
            ctx.strokePath()
        }
        if layer == self.markerLayer {
            if self.marker == nil {
                return
            }
            ctx.setStrokeColor(NSColor.red.cgColor)
            if self.tempresults_wave.first == 0 {
                ctx.stroke(CGRect(x: 10 + CGFloat(self.marker!.first!-self.tempresults_time[1]), y: NSHeight(layer.frame)*0.1, width: CGFloat(1), height: NSHeight(layer.frame)*0.8))
                
                if self.regressionMSEPerWindow.count > self.firstStepTable.selectedRow {
                    let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(kCFAllocatorDefault, "mse = \(self.regressionMSEPerWindow[self.firstStepTable.selectedRow])" as CFString, self.attrDict! as CFDictionary))
                    ctx.textPosition = CGPoint(x: CGFloat(self.marker!.first!-self.tempresults_time[2]), y: 10)
                    CTLineDraw(line, ctx)
                }
                
                return
            }
            ctx.stroke(CGRect(x: CGFloat(self.marker!.first!-Float(self.startSample!)), y: NSHeight(layer.frame)*0.1, width: CGFloat(self.marker!.last!), height: NSHeight(layer.frame)*0.8))
            
        }
        if layer == self.regressionDataLayer && self.debugRegression.state == .on {
            let baseSample = self.tempresults_time.first!
            let maxkHzFactor = Double(NSHeight(layer.frame) / 200.0)
            let time_correct = 1.0 / Double(self.delegate.mySoundContainer.header!.samplerate)
            
            var mid = 0.0
            var count = 0
            
            for (index, aRegValue) in self.tempresults_wave.enumerated() {
                if self.tempresults_time[index]  == 0 {
                    break
                }
                let x = Double(10 + (self.tempresults_time[index] - baseSample))
                let y = Double(aRegValue) * maxkHzFactor
                ctx.strokeEllipse(in: CGRect(x: x, y: y, width: 3.0, height: 3.0))
                mid = x
                count += 1
            }
            
            let x = mid / Double(2)
            
            ctx.setStrokeColor(NSColor.systemTeal.cgColor)
            ctx.setFillColor(NSColor.systemTeal.cgColor)
            let y = Double(self.xtValues.last!) * maxkHzFactor
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: 3.0, height: 3.0))
            ctx.strokeEllipse(in: CGRect(x: x, y: y, width: 3.0, height: 3.0))
            var zcmse = Float(2.0)
            if nil != UserDefaults.standard.object(forKey: "zcmse") {
                zcmse = UserDefaults.standard.float(forKey: "zcmse")
            }
            
            if self.regressionParams.last!.isNaN {
                return
            }
            
            if self.regressionParams.last! > zcmse {
                ctx.setStrokeColor(NSColor.systemRed.cgColor)
            } else {
                ctx.setStrokeColor(NSColor.systemTeal.cgColor)
            }
            
            ctx.beginPath()
            let y1 = (self.regressionParams.first! + (Float(0)*self.regressionParams[1]))
            let y2 = (self.regressionParams.first! + (Float((x*2)-10)*self.regressionParams[1]))
            ctx.move(to: CGPoint(x: CGFloat(10), y: 0.001 * CGFloat(1.0/Double(y1*Float(time_correct))) * CGFloat(maxkHzFactor)))
            ctx.addLine(to: CGPoint(x: CGFloat((x*2)), y: 0.001 * CGFloat(1.0/Double(y2*Float(time_correct))) * CGFloat(maxkHzFactor)))
            ctx.strokePath()
            
            let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(kCFAllocatorDefault, "mse = \(self.regressionParams.last!)" as CFString, self.attrDict! as CFDictionary))
            ctx.textPosition = CGPoint(x: 10, y: 150*maxkHzFactor)
            CTLineDraw(line, ctx)
        }
    }
    
}

extension DebugController: NSTableViewDelegate, NSTableViewDataSource {
    
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return tempresults_time.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            
            
            switch tableColumn!.identifier.rawValue {
            case "waveColumn":
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("floatView"), owner: nil) as? NSTableCellView {
                    if self.tempresults_wave.count <= row {
                        cell.textField?.stringValue = "---"
                    } else {
                        cell.textField?.floatValue = self.tempresults_wave[row]
                    }
                    return cell
                }
                
            case "timeColumn":
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("floatView"), owner: nil) as? NSTableCellView {
                    cell.textField?.floatValue = self.tempresults_time[row]
                    return cell
                }
                
                
            default:
                return nil
            }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if self.firstStepTable.selectedRow == self.tempresults_time.count - 1 {return}
        
        if self.tempresults_wave.first! == 0 {
            if self.firstStepTable.selectedRow == 0 { return }
            self.marker = [self.tempresults_time[self.firstStepTable.selectedRow], 1]
            self.waveView!.scroll(NSPoint(x: Double(self.tempresults_time[self.firstStepTable.selectedRow]) - Double(self.tempresults_time[1]+100), y: 0.0))
            return
        }
        
        self.marker = [self.tempresults_time[self.firstStepTable.selectedRow], self.tempresults_time[self.firstStepTable.selectedRow+1]-self.tempresults_time[self.firstStepTable.selectedRow]]
        self.waveView!.scroll(NSPoint(x: Double(self.tempresults_time[self.firstStepTable.selectedRow]) - Double(self.startSample!+100), y: 0.0))
    }
    
}
