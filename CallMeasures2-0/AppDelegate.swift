//
//  AppDelegate.swift
//  CallMeasures2-0
//
//  Created by Volker Runkel on 30.04.20.
//  Copyright © 2020 ecoObs GmbH. All rights reserved.
//

import Cocoa

enum WindowFunctions : Int {
    case rectangle
    case hanning
    case hamming
    case bartlet
    case blackman
    case flattop
    case seventermharris
}

struct FFTSettings {
    var fftSize: Int
    var overlap: Float
    var window: WindowFunctions
}

public struct RGBAPixel {
    var r:UInt8 = 0
    var g:UInt8 = 0
    var b:UInt8 = 0
    var a:UInt8 = 0
    
    mutating func setRedInverted(value: UInt8) {
        self.r = value
        self.g = 255
        self.b = 255
    }
    
    mutating func setGreenInverted(value: UInt8) {
        self.r = 255
        self.g = value
        self.b = 255
    }
    
    mutating func setBlueInverted(value: UInt8) {
        self.r = 0
        self.g = 0
        self.b = value
    }
    
    mutating func setRed(value: UInt8) {
        self.r = 255
        self.g = value
        self.b = value
    }
    
    mutating func setGreen(value: UInt8) {
        self.r = value
        self.g = 255
        self.b = value
    }
    
    mutating func setBlue(value: UInt8) {
        self.r = value
        self.g = value
        self.b = 255
    }
    
    mutating func setRGB(red: UInt8, green: UInt8, blue: UInt8) {
        self.r = red
        self.g = green
        self.b = blue
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
        
    @IBOutlet weak var measuresPanel: NSPanel!
    @IBOutlet weak var measuresTable: NSTableView!
    @IBOutlet weak var derivedMeasuresPanel: NSPanel!
    @IBOutlet weak var derivedMeasuresTable: NSTableView!
    
    @IBOutlet weak var steigungenPanel: NSPanel!
    @IBOutlet weak var steigungenTable: NSTableView!
    @IBOutlet weak var steigungsSwitch: NSSegmentedControl!
    var useAvgSteigung: Bool = false
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var soundOverView: BCWaveOverviewForm!
    @IBOutlet weak var soundDetailView: DetailWaveView!
    @IBOutlet weak var measuresView: CallMeasuresView!
    
    @objc var debug: Bool = false {
        didSet {
            if self.debug {
                self.debuggingController = DebugController(windowNibName: "DebugController")
                self.debuggingController?.delegate = self
                self.debuggingController?.showWindow(nil)
            }
        }
    }
    var debuggingController: DebugController?
    
    var mySoundContainer: BCSoundContainer!
    var waveOverviewData: Array<Float> = []
    var soundURL: URL?
    
    var callFinder: BCCallFinderManager?
    
    var bcCallsArray: NSArray?
    var callMeasures: Array<CallMeasurements>?
    var callToDraw = 0
    
    func setDefaults() {
        let ud = UserDefaults.standard
        
        ud.set("-36 dB", forKey: kCallFinderGeneralThresholdUI)
        
        ud.set((1.5625/100.0), forKey: kCallFinderGeneralzfthreshold)
        
        ud.set(15, forKey: kCallFinderMinCallInt)
        
        ud.set(20, forKey: kCallFinderGeneralQuality)
        
        if nil == UserDefaults.standard.object(forKey: "zcmse") {
            UserDefaults.standard.set(2.0,forKey: "zcmse")
        }
        /*if nil = UserDefaults.standard.object(forKey: "zcwindowsize") {
         zcwindowsize = (UserDefaults.standard.double(forKey: "zcwindowsize") / 1000.0) * Double(sampleFactor)
         }
         else {
         zcwindowsize = (400.0/1000.0) * Double(sampleFactor)
         }
         
         if nil != UserDefaults.standard.object(forKey: "srwindowsize") {
         srwindowsize = (UserDefaults.standard.double(forKey:"srwindowsize") / 1000.0) * Double(sampleFactor)
         }
         else {
         srwindowsize = (200/1000.0) * Double(sampleFactor)
         }*/
        
        if nil == UserDefaults.standard.object(forKey: "zcwindowsize") {
            UserDefaults.standard.set(300, forKey: "zcwindowsize") // RICHTIG ? 400 / 1000
        }
        
        if nil == UserDefaults.standard.object(forKey: "srwindowsize") {
            UserDefaults.standard.set(200, forKey: "srwindowsize") // RICHTIG ? 200 / 1000
        }
        
        if nil == UserDefaults.standard.object(forKey: "smooth") {
            UserDefaults.standard.set(2.0, forKey: "smooth")
        }
        
        if nil == UserDefaults.standard.object(forKey: "samplehi") {
            UserDefaults.standard.set(200, forKey: "samplehi")
        }
        
        if nil == UserDefaults.standard.object(forKey: "zfthreshold") {
            UserDefaults.standard.set(/*0.04*/ 1.5625, forKey:"zfthreshold")
        }
        
        if nil == UserDefaults.standard.object(forKey: "mincalldist") {
            UserDefaults.standard.set(15, forKey: "mincalldist")
        }
        /*else {
            mincalldist = 50*sampleFactor // *500 variabel, angepasst an samplerate
        }*/
        
        if nil == UserDefaults.standard.object(forKey: "mincalllength") {
            UserDefaults.standard.set(0.75, forKey: "mincalllength")
        }
        
        if nil == UserDefaults.standard.object(forKey: "backmse") {
            UserDefaults.standard.set(0.16, forKey: "backmse")
        }
        
        if nil == UserDefaults.standard.object(forKey: "formse") {
            UserDefaults.standard.set(0.06, forKey:"formse")
        }
        
        if nil == UserDefaults.standard.object(forKey: "srahead") {
            UserDefaults.standard.set(8, forKey: "srahead")
        }
        
        if nil == UserDefaults.standard.object(forKey: "mincallint") {
            UserDefaults.standard.set(1.1*500, forKey: "mincallint")
        }
        //else {
        //    mincallint = 0.2*Double(sampleFactor); // *500 variabel, angepasst an samplerate
        //}
        
        if nil == UserDefaults.standard.object(forKey: "hystThres") {
           UserDefaults.standard.set(0.4, forKey: "hystThres")// / 100.0
        }
        //else {
        //    hystThres = 0.5
        //}
        
        if nil == UserDefaults.standard.object(forKey:"useHyst") {
            UserDefaults.standard.set(true, forKey:"useHyst")
        }
        
        if nil == UserDefaults.standard.object(forKey: "ampThres") {
            UserDefaults.standard.set(0.003, forKey: "ampThres") /// 100.0
        }
        //else {
        //    ampThres = 0.04
        //}
        
    }
    
    @IBAction func setMeasurementMaxMS(_ sender: NSSegmentedControl) {
        switch sender.indexOfSelectedItem {
        case 0: self.measuresView.msMax = 7
        case 1: self.measuresView.msMax = 18
        case 2: self.measuresView.msMax = 36
        default: self.measuresView.msMax = 18
        }
        self.measuresView.callLayer.setNeedsDisplay()
        self.measuresView.calcSona()
    }
    
    func renderSoundoverView() {
        DispatchQueue.global().async(execute: {
            [weak self = self] in
            let fftAnalyzer = FFTAnalyzer()
            let sampleCount = self!.mySoundContainer.sampleCount
            var overlap: Float = 0.0
            if (sampleCount > 300000) { overlap = -0.25 }
            if (sampleCount > 600000) { overlap = -0.5 }
            if (sampleCount > 1200000) { overlap = -0.75 }
            if (sampleCount > 6000000) { overlap = -1 }
            
            let sonaImage = fftAnalyzer.sonagramImage(fromSamples: self!.mySoundContainer.soundData, startSample: 0, numberOfSamples:sampleCount, Overlap: overlap, Window:5)
            DispatchQueue.main.async() {
                self!.soundOverView.sonaLayer.contents = sonaImage
            }
        })
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        self.setDefaults()
        self.soundOverView.delegate = self
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @IBAction func openFile(_ sender: Any?) {
        
        let op = NSOpenPanel()
        op.allowedFileTypes = ["raw"]
        
        if op.runModal() != .OK {
            return
        }
        self.soundURL = op.url
        do {
            self.mySoundContainer = try BCSoundContainer(with: op.url!)
            
            if self.mySoundContainer.sampleCount > 0 {
                self.waveOverviewData = mySoundContainer.minMaxArrayLessMemory(stepSize: 500, start: 0)
                self.soundOverView.soundLayer.setNeedsDisplay()
                self.renderSoundoverView()
            }
        }
            
        catch AudioError.TooManyChannels {
            let channelError: NSError! = NSError(domain: "bcAnalyze", code: 0, userInfo: [NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString("Too many audio channels. bcAnalyze supports mono and stereo files only.", comment: "error description when too many channels")])
            NSApp.presentError(channelError)
        }
        catch AudioError.SecurityScopeExhausted {
            let securityError: NSError! = NSError(domain: "bcAnalyze", code: 0, userInfo: [NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString("Couldn't access file due to exhausted security scope. Please restart the application.", comment: "Couldn't access file due to exhausted security scope. Please restart the application.")])
            NSApp.presentError(securityError)
        }
        catch AudioError.EmptyFile {
            let securityError: NSError! = NSError(domain: "bcAnalyze", code: 0, userInfo: [NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString("Sound file contains no audio samples. Empty soundfiles can't be loaded.", comment: "Sound file contains no audio samples. Empty soundfiles can't be loaded.")])
            NSApp.presentError(securityError)
        }
        catch AudioError.FileFormat {
            let channelError: NSError! = NSError(domain: "bcAnalyze", code: 0, userInfo: [NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString("Can't interpret file format. bcAnalyze doesn't support the file format.", comment: "error description when other error sopening audio file")])
            NSApp.presentError(channelError)
        }
        catch {
            let outError: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
            NSApp.presentError(outError)
        }
    }
        
    @IBAction func findNextCall(_ sender: Any?) {
        
        if self.soundURL == nil {
            return
        }
        self.callToDraw = 0
        var searchStart = 0
        if self.callMeasures?.count ?? 0 > 0 {
            searchStart = Int(self.callMeasures!.last!.callData["Startsample"]!) + Int(self.callMeasures!.last!.callData["Sizesample"]!) + 20*500
        }
        
        self.callFinder = BCCallFinderManager()
        if self.debug {
            self.callFinder?.debugDelegate = self.debuggingController
        } else {
            self.debuggingController?.close()
            self.debuggingController = nil
        }
        DispatchQueue.global().async {
            
            let _ = self.callFinder!.findCalls(for: self.soundURL!, exportFiles: true, threshold: nil, quality: 2.0, start: searchStart)
            self.bcCallsArray = self.callFinder!.bcCallsArray
            
            //self.bcCallsArray!.write(to: self.soundURL!.measurementFileURL()!, atomically: true)
            self.callMeasures = self.callFinder!.callMeasures
            
            DispatchQueue.main.async {
                self.soundOverView.callLayerData = Array()
                
                if self.bcCallsArray?.count ?? 0 > 0 {
                    for aCall in self.bcCallsArray! {
                        if let aCallDict = aCall as? NSDictionary {
                            let startsample = (aCallDict["Startsample"] as! NSNumber).intValue
                            let sizeInSamples = (aCallDict["Sizesample"] as! NSNumber).intValue
                            self.soundOverView.callLayerData.append((Float(startsample), Float(sizeInSamples)))
                        }
                    }
                    self.soundOverView.callLayer.setNeedsDisplay()
                    self.soundOverView.callLayer.setNeedsDisplay()
                    self.soundDetailView.callLayer.setNeedsDisplay()
                    self.measuresView.callLayer.setNeedsDisplay()
                    self.measuresView.calcSona()
                }
                
                self.measuresPanel.orderFront(nil)
                self.measuresTable.reloadData()
                
                self.derivedMeasuresPanel.orderFront(nil)
                self.derivedMeasuresTable.reloadData()
                
                self.steigungenPanel.orderFront(nil)
                self.steigungenTable.reloadData()
            }
        }
        
    }
    
    @IBAction func switchSteigungen(_ sender: NSSegmentedControl) {
        self.useAvgSteigung.toggle()
        self.steigungenTable.reloadData()
    }
    
    @IBAction func nextCall(_ sender: Any?) {
        if self.bcCallsArray == nil {
            return
        }
        self.callToDraw += 1
        if self.callToDraw >= self.bcCallsArray!.count {
            self.callToDraw = 0
        }
        self.soundDetailView.callLayer.setNeedsDisplay()
        self.soundOverView.callLayer.setNeedsDisplay()
        self.measuresView.callLayer.setNeedsDisplay()
        self.measuresView.calcSona()
    }
    
    @IBAction func prevCall(_ sender: Any?) {
        if self.bcCallsArray == nil {
            return
        }
        self.callToDraw -= 1
        if self.callToDraw < 0 {
            self.callToDraw = self.bcCallsArray!.count - 1
        }
        self.soundDetailView.callLayer.setNeedsDisplay()
        self.soundOverView.callLayer.setNeedsDisplay()
        self.measuresView.callLayer.setNeedsDisplay()
        self.measuresView.calcSona()
    }
}

extension AppDelegate: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.measuresTable {
            return self.callMeasures?[self.callToDraw].callData.count ?? 0
        }
        else if tableView == self.derivedMeasuresTable {
            return self.callMeasures?[self.callToDraw].derivedMeasures?.count ?? 0
        }
        else if tableView == self.steigungenTable {
            if self.useAvgSteigung {
                return self.callMeasures?[self.callToDraw].steigungsMittel?.count ?? 0
            }
            return self.callMeasures?[self.callToDraw].steigungen?.count ?? 0
        }
        return 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableView == self.measuresTable {
            
            let rowData = self.callMeasures!.last!.callData
            
            
            switch tableColumn!.identifier.rawValue {
            case "labelColumn":
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("stringCell"), owner: nil) as? NSTableCellView {
                    cell.textField?.stringValue = Array(rowData.keys).sorted()[row]
                    return cell
                }
                
            case "valueColumn":
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("floatCell"), owner: nil) as? NSTableCellView {
                    cell.textField?.floatValue = rowData[Array(rowData.keys).sorted()[row]] ?? 0.0
                    return cell
                }
                
                
            default:
                return nil
            }
        }
        else if tableView == self.derivedMeasuresTable {
            
            let rowData = self.callMeasures![self.callToDraw].derivedMeasures!
            
            
            switch tableColumn!.identifier.rawValue {
            case "labelColumn":
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("stringCell"), owner: nil) as? NSTableCellView {
                    cell.textField?.stringValue = Array(rowData.keys).sorted()[row]
                    return cell
                }
                
            case "valueColumn":
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("floatCell"), owner: nil) as? NSTableCellView {
                    cell.textField?.floatValue = rowData[Array(rowData.keys).sorted()[row]] ?? 0.0
                    return cell
                }
                
                
            default:
                return nil
            }
        }
        else if tableView == self.steigungenTable {
            
            var rowData = self.callMeasures![self.callToDraw].steigungen!
            if self.useAvgSteigung {
                rowData = self.callMeasures![self.callToDraw].steigungsMittel!
            }
            
            switch tableColumn!.identifier.rawValue {
            case "labelColumn":
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("stringCell"), owner: nil) as? NSTableCellView {
                    cell.textField?.stringValue = "\(row)"
                    return cell
                }
                
            case "valueColumn":
                if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("floatCell"), owner: nil) as? NSTableCellView {
                    cell.textField?.floatValue = rowData[row]
                    return cell
                }
                
                
            default:
                return nil
            }
        }
        return nil
    }
    
}

