//
//  BCCallFinder.swift
//  bcAnalyze3
//
//  Created by Volker Runkel on 12.12.16.
//  Copyright (c) 2016 ecoObs GmbH. All rights reserved.
//

import Cocoa
import ecoObsCallFinderFramework

protocol CallFinderDelegate {
    // protocol definition goes here
    var mySoundContainer: BCSoundContainer! { get set }
    var callFinderRawData: Array<Array<Float>> { get set } // stores start, c, fc, fi of each call finding loop with positive result
    var debugDelegate: DebugController? { get set }
}

class BCCallFinderManager: CallFinderDelegate {
    
    var mySoundContainer: BCSoundContainer!
    var callFinderRawData: Array<Array<Float>> = Array()
    
    var debugDelegate: DebugController?
    
    var fileURL: URL?
    
    var bcCallsArray: NSArray?
    var batIdentData: String?
    
    var callMeasures: Array<CallMeasurements>?
    var callBlocks: Array<Int>?
    var errorOccurred: Bool = false
    
    func exportbatIdentData(calls : Array<CallMeasurements>) {
        var exportString = "Datei\tArt\tRuf\tDur\tSfreq\tEfreq\tStime\tNMod\tFMod\tFRmin\tRmin\ttRmin\tRlastms\tFlastms"
        
        for index in 10..<60 {
            exportString += "\tX\(index)"
        }
        
        for index in stride(from: 60, to: 150, by: 2) {
            exportString += "\tX\(index)"
        }
        
        let nF = NumberFormatter()
        nF.minimumFractionDigits = 1
        nF.maximumFractionDigits = 7
        nF.minimumIntegerDigits = 1
        
        nF.decimalSeparator = "."
        nF.groupingSeparator = ","
        
        for aCall in calls {
            if aCall.identData != nil {
                exportString += "\n\(self.fileURL!.lastPathComponent)"
                exportString += "\t\(aCall.species)"
                exportString += "\t\(aCall.callNumber)"
                let callSize = aCall.callData["Size"]!
                exportString += "\t"
                exportString += nF.string(from:NSNumber(value:callSize))!
                let sFreq = aCall.callData["SFreq"]!
                exportString += "\t"
                exportString += nF.string(from:NSNumber(value:sFreq))!
                let eFreq = aCall.callData["EFreq"]!
                exportString += "\t"
                exportString += nF.string(from:NSNumber(value:eFreq))!
                let start = aCall.callData["Start"]!
                exportString += "\t"
                exportString += nF.string(from:NSNumber(value:start))!
                let nmod = aCall.identData!["NMod"]!
                exportString += "\t"
                exportString += nF.string(from:NSNumber(value:nmod))!
                let fmod = aCall.identData!["FMod"]!
                exportString += "\t"
                exportString += nF.string(from:NSNumber(value:fmod))!
                let frmin = aCall.identData!["FRmin"]!
                exportString += "\t"
                exportString += nF.string(from:NSNumber(value:frmin))!
                let rmin = aCall.identData!["Rmin"]!
                exportString += "\t"
                exportString += nF.string(from:NSNumber(value:rmin))!
                let trmin = aCall.identData!["tRmin"]!
                exportString += "\t"
                exportString += nF.string(from:NSNumber(value:trmin))!
                let rlastms = aCall.identData!["Rlastms"]!
                exportString += "\t"
                exportString += nF.string(from:NSNumber(value:rlastms))!
                let flastms = aCall.identData!["Flastms"]!
                exportString += "\t"
                exportString += nF.string(from:NSNumber(value:flastms))!
                
                for index in 10..<60 {
                    guard let value = aCall.identData!["X\(index)"] else {
                        exportString += "\t0"
                        continue
                    }
                    exportString += "\t"
                    exportString += nF.string(from:NSNumber(value:value))!
                }
                
                for index in stride(from: 60, to: 150, by: 2) {
                    guard let value = aCall.identData!["X\(index)"] else {
                        exportString += "\t0"
                        continue
                    }
                    exportString += "\t"
                    exportString += nF.string(from:NSNumber(value:value))!
                }
                
            }
        }
        self.batIdentData = exportString
    }
    
    func findCalls(for recording: URL, exportFiles: Bool = true, threshold: Double?, quality: Double = 20, start: Int = 0) -> Int {
        self.fileURL = recording
        do {
            self.mySoundContainer = try BCSoundContainer(with: self.fileURL!)
            
            let callFinder = BCCallFinder()
            callFinder.samplerate = (self.mySoundContainer!.header!.samplerate*self.mySoundContainer!.header!.timeExpansion)
            //callFinder.delayFactor = self.delayFactor
            callFinder.delegate = self
            if threshold != nil {
                callFinder.zfthreshold = threshold!
            }
            callFinder.smooth = quality
            
            let startSample = start
            
            var bcCalls = callFinder.measuresFromData(startSample: startSample, numberOfSamples: (self.mySoundContainer!.header?.sampleCount)!)
            self.callMeasures = bcCalls
            if !bcCalls.isEmpty, exportFiles {
                
                let csvExporter = CallCSVExporter()
                csvExporter.generateCallMeasurements(inArray: &bcCalls)
                
                let bcCallsContent = NSMutableArray()
                for aCall in bcCalls {
                    let callDictionary = aCall.bcCallsRepresentation
                    bcCallsContent.add(callDictionary)
                }
                self.bcCallsArray = bcCallsContent
                self.exportbatIdentData(calls: bcCalls)
            }
            return bcCalls.count
        }
        catch {
            Swift.print("Error finding calls " + "\(error)")
            self.errorOccurred = true
            return 0
        }
    }
    
    func thresholdForInteger(inValue: Int) -> Double {
        switch inValue {
        case 18, -18: return (12.5/100.0)
        case 24, -24: return (6.25/100.0)
        case 27, -27: return (4.25/100.0)
        case 30, -30: return (3.125/100.0)
        case 34, -34: return (2.0/100.0)
        case 36, -36: return (1.5625/100.0)
        case 42, -42: return (0.78125/100.0)
        case 48, -48: return (0.390625/100.0)
        case 54, -54: return (0.1953125/100)
        case 60, -60: return (0.097656/100.0)
        case 66, -66: return (0.048828125/100.0)
        default: return (4.25/100.0)
        }
    }
    
}

class BCCallFinder {
    
    var startSample: Int = 0
    var singleCall = true
    
    var delegate: CallFinderDelegate!
    var debugFirstStep: Bool = false
    var debugRegression: Bool = false
    var debugRegressionSpeed: Double = 0.1
    var debugRegressionShowOutsideMSE = false
    var debugShowzcData = false
    var debugCallStart = false
    var debugCallStartSkipRegressionDisplay = false
    
    var zcmse = 0.0
    var zcwindowsize = 100.0
    var srwindowsize = 200.0
    
    public var smooth = 2.0
    var samplehi = 200
    public var zfthreshold = 0.0
    
    var mincalldist = 15
    var mincalllength = 0.0
    
    var backmse = 100.0
    var formse = 100.0
    var mincallint = 15.0
    var srahead = 30
    
    var zeroThres = 1.0
    var hystThres = 2.0
    var useHyst = false
    var ampThres = 500.0
    
    var samplerate: Int = 500000 {
        didSet {
            if (samplerate > 0) {
                sampleFactor = (samplerate*delayFactor)/1000
                time_correct = 1.0 / Double(sampleFactor)
            }
        }
    }
    var sampleFactor = 500	// how many samples per millisecond, important for calculations
    var time_correct = 0.002 // milliseconds per sample, important for calculations
    var delayFactor: Int = 1 {
        didSet {
            if delayFactor > 0 {
                sampleFactor = (samplerate*delayFactor)/1000
                time_correct = 1.0 / Double(sampleFactor)
            }
        }
    }
    
    var sampleCount = 0
    
    //var rawSoundData: Array<Float>! // we need to store a reference only here somehow!
    var offset: Float = 0.0
    var dataArray: Array<CallMeasurements> = Array()
    var zcTimeData: Array<Float>=Array()
    var zcFreqData: Array<Double>=Array()
    
    init() {
        self.setDefaults()
    }
    
    func regression_two(arr:Array<(Float, Float)>, numberOfSamples:Int) -> Double
    {
        //regression vars
        var s_x: Double = 0.0
        var ss_x: Double = 0.0
        var s_f: Double = 0.0
        var s_xf: Double = 0.0
        var r_s = 0.0
        let zero = arr[0].0 - 1
        
        var b: Double
        var a: Double
        var rsquare: Double
        let rgut = zcmse
        
        // sum of x's (we pull down everything towards zero!)
        for k in 0..<numberOfSamples {
            s_x = s_x + Double(arr[k].0-zero)
        }
        
        // sum of squares of x's (we pull down everything towards zero!)
        for k in 0..<numberOfSamples {
            ss_x = ss_x + Double( (arr[k].0-zero)*(arr[k].0-zero))
        }
        
        // sum of frequencies
        for k in 0..<numberOfSamples {
            s_f = s_f + Double(arr[k].1)
        }
        
        // sum of x*frequencies
        for k in 0..<numberOfSamples {
            s_xf = s_xf + Double( (arr[k].0-zero) * arr[k].1 )
        }
        
        let divisor = (s_xf - ((s_x*s_f)/Double(numberOfSamples)))
        let divident = (ss_x-((s_x*s_x)/Double(numberOfSamples)))
        b = Double(divisor / divident)
        a = (s_f - (s_x * b)) / Double(numberOfSamples)
        
        r_s=0
        for k in 0..<numberOfSamples {
            let part1 = Double(arr[k].1) - (a+((Double(arr[k].0-zero)*b)))
            r_s = r_s + (part1 * part1)
        }
        
        rsquare = r_s / Double(numberOfSamples)
        
        if self.delegate.debugDelegate != nil && self.debugRegression {
            self.delegate.debugDelegate!.regressionParams = [Float(a), Float(b), Float(rsquare)]
        }
        
        if (rsquare <= rgut) {
            let x = a + ((Double(arr[0].0) + Double(zcwindowsize)/2 - Double(zero))*b)
            if self.delegate.debugDelegate != nil && self.debugRegression {
                self.delegate.debugDelegate!.regressionMSEPerWindow.append(Float(rsquare))
            }
            return x
        }
        return -1
    }
    
    func regressionFrom(start:Int, end:Int, withA regA:inout Double, withB regB:inout Double) -> Double
    {
        //regression vars
        var s_x = 0.0
        var ss_x = 0.0
        var s_f = 0.0
        var s_xf = 0.0
        var r_s = 0.0
        let zero: Float = zcTimeData[start] - 1
        let n: Int = end-start+1
        
        var b = 0.0
        var a = 0.0
        var rsquare = 0.0
        // sum of x's (we pull down everything towards zero!)
        
        for k in start...end { s_x = s_x + Double(zcTimeData[k]-zero) }
        
        // sum of squares of x's (we pull down everything towards zero!)
        for k in start...end { ss_x = ss_x + (Double(zcTimeData[k]-zero)*Double(zcTimeData[k]-zero)) }
        
        // sum of frequencies
        for k in start...end { s_f = s_f + zcFreqData[k] }
        
        // sum of x*frequencies
        for k in start...end { s_xf = s_xf + ( Double(zcTimeData[k]-zero) * zcFreqData[k] ) }
        
        b = (s_xf - ((s_x*s_f)/Double(n))) / (ss_x-((s_x*s_x)/Double(n)))
        a = (s_f - (s_x*b)) / Double(n)
        
        for k in start...end {
            let part: Double = (zcFreqData[k] - (a+(Double(zcTimeData[k]-zero)*b)))
            r_s = r_s + ( part * part)
        }
        
        rsquare = r_s / Double(n)
        regA = a
        regB = b
        return rsquare
    }
    
    func setDefaults()
    {
        if nil != UserDefaults.standard.object(forKey: "zcwindowsize") {
            zcwindowsize = (UserDefaults.standard.double(forKey: "zcwindowsize") / 1000.0) * Double(sampleFactor)
        }
        else {
            zcwindowsize = (300.0/1000.0) * Double(sampleFactor)
        }
        
        if nil != UserDefaults.standard.object(forKey: "srwindowsize") {
            srwindowsize = (UserDefaults.standard.double(forKey: "srwindowsize") / 1000.0) * Double(sampleFactor)
        }
        else {
            srwindowsize = (200/1000.0) * Double(sampleFactor)
        }
        
        if nil != UserDefaults.standard.object(forKey: "zcmse") {
            zcmse = UserDefaults.standard.double(forKey: "zcmse")
        }
        else {
            zcmse = 2.0
        }
        
        if nil != UserDefaults.standard.object(forKey: kCallFinderGeneralQuality) {
            smooth = UserDefaults.standard.double(forKey: kCallFinderGeneralQuality)
        }
        else {
            smooth = 2.0
        }
        
        if nil != UserDefaults.standard.object(forKey: "samplehi") {
            samplehi = UserDefaults.standard.integer(forKey: "samplehi")
        }
        else {
            samplehi = 200
        }
        
        if nil != UserDefaults.standard.object(forKey: kCallFinderGeneralzfthreshold) {
            zfthreshold = UserDefaults.standard.double(forKey: kCallFinderGeneralzfthreshold)
        }
        else {
            zfthreshold = 0.015625
        }
        
        if nil != UserDefaults.standard.object(forKey: kCallFinderMinCallInt) {
            mincalldist = UserDefaults.standard.integer(forKey: kCallFinderMinCallInt)*sampleFactor
        }
        else {
            mincalldist = 50*sampleFactor
        }
        
        if nil != UserDefaults.standard.object(forKey: "mincalllength") {
            mincalllength = UserDefaults.standard.double(forKey: "mincalllength")
        }
        else {
            mincalllength = 0.75
        }
        
        if nil != UserDefaults.standard.object(forKey: "backmse") {
            backmse = UserDefaults.standard.double(forKey: "backmse")
        }
        else {
            backmse = 0.16
        }
        
        if nil != UserDefaults.standard.object(forKey: "formse") {
            formse = UserDefaults.standard.double(forKey: "formse")
        }
        else {
            formse = 0.06
        }
        
        if nil != UserDefaults.standard.object(forKey: "srahead") {
            srahead = UserDefaults.standard.integer(forKey: "srahead")
        }
        else {
            srahead = 8
        }
        
        if nil != UserDefaults.standard.object(forKey: "mincallint") {
            mincallint = UserDefaults.standard.double(forKey: "mincallint")*Double(sampleFactor)
        }
        else {
            mincallint = 1.1*Double(sampleFactor);
        }
        
        if nil != UserDefaults.standard.object(forKey: "hystThres") {
            hystThres = UserDefaults.standard.double(forKey: "hystThres") / 100.0
        }
        else {
            hystThres = 0.4 // 0.6
        }
        
        if nil != UserDefaults.standard.object(forKey: "useHyst") {
            useHyst = UserDefaults.standard.bool(forKey: "useHyst")
        }
        else {
            useHyst = true
        }
        
        if nil != UserDefaults.standard.object(forKey: "ampThres") {
            ampThres = UserDefaults.standard.double(forKey: "ampThres") / 100.0
        }
        else {
            ampThres = 0.003
        }
    }
    
    func getOffset() -> Float {
        var localOffset = 0.0
        
        var size = sampleCount
        if sampleCount > 500000 {
            size = 500000
        }
        
        var sumResult = 0.0
        
        for index in 0..<size {
            sumResult += Double((delegate.mySoundContainer.soundData?[index])!)
        }
        
        localOffset =  sumResult / Double(size)
        
        return Float(localOffset)
    }
    
    func calculateHysterese() {
        
        var soundSize = sampleCount - 50*sampleFactor
        if soundSize < 0 {
            soundSize = sampleCount
        }
        
        zeroThres = 1.0
        
        if useHyst && soundSize > 500*sampleFactor {
            for i in stride(from: (25*sampleFactor), to: soundSize, by: (soundSize/10)) {
                let max = delegate.mySoundContainer.soundData?[i..<i+1000].max()!
                
                if zeroThres > Double(max!) && max! > Float(0.0) {
                    zeroThres = Double(max!)
                }
            }
            zeroThres = 2*zeroThres*hystThres
        }
        else {
            zeroThres = ampThres
            if zeroThres > zfthreshold { zeroThres = 0.0003 }
        }
        if zeroThres == 0 || zeroThres == 1 { zeroThres = 0.0003 }
        if zeroThres > zfthreshold { zeroThres = 0.0003 }
    }
    
    func measuresFromData(startSample: Int, numberOfSamples:Int, debug: Bool = false) -> Array<CallMeasurements> {
        DispatchQueue.main.async {
            self.debugFirstStep = (self.delegate.debugDelegate?.debugFirstStep.state ?? .off) == .on
            self.debugRegression = (self.delegate.debugDelegate?.debugRegression.state ?? .off) == .on
            self.debugRegressionShowOutsideMSE = (self.delegate.debugDelegate?.debugShowRegressionOutsideMSE.state ?? .off) == .on
            self.debugShowzcData = (self.delegate.debugDelegate?.debugShowzcData.state ?? .off) == .on
            if self.delegate.debugDelegate != nil {
                switch self.delegate.debugDelegate!.debugRegressionSpeed.indexOfSelectedItem {
                case 0: self.debugRegressionSpeed = 0.3
                case 1: self.debugRegressionSpeed = 0.1
                case 2: self.debugRegressionSpeed = 0.02
                default: self.debugRegressionSpeed = 0.1
                }
            }
            self.debugCallStart = (self.delegate.debugDelegate?.debugCallStartRegression.state ?? .off) == .on
            if self.debugCallStart {
                self.debugCallStartSkipRegressionDisplay = (self.delegate.debugDelegate?.callStartHideRegressionSteps.state ?? .off) == .on
            }
            
        }
        
        sampleCount = numberOfSamples
        self.startSample = startSample
                
        offset = Float(self.getOffset())
        
        self.calculateHysterese()
                
        //_ = self.findCalls(debug : debug)

        let callFinder = ecoCallFinder()
        callFinder.samplerate = self.delegate.mySoundContainer.header!.samplerate
        let callPositions = callFinder.findCalls(soundData: &self.delegate.mySoundContainer.soundData, offset: offset, startSample: 0, sampleCount: self.delegate.mySoundContainer.header!.sampleCount, zfthreshold: Float(zfthreshold), smooth: Float(smooth))
        
        // normal searchCalls function for each
        
        for aTuple in callPositions {
            self.searchForCallFrom(starting: aTuple.start, ending: aTuple.end)
        }
        
        self.cleanUpCallData()
        
        return dataArray
    }
        
    func searchForCallFrom(starting:Int, ending:Int, debug: Bool = false)
    {
        
        /*	*****************************************************
         This block takes care of basic zero-crossing analysis
         as well as it does the first step in regression
         and results in a filled temparray which is used later for call extraction !
         ***************************************************** */
        var tempresults_time: Array<Float> = Array()
        var tempresults_wave: Array<Float> = Array()
        zcTimeData.removeAll()
        zcFreqData.removeAll()
        
        /*tempresults_time = (float*) malloc(zcDataSize*sizeof(float));
         if (tempresults_time == NULL) NSLog(@"Malloc problem for time");
         tempresults_wave = (float*) malloc(zcDataSize*sizeof(float));
         if (tempresults_wave == NULL) NSLog(@"Malloc problem for wave");
         */
        var count = 0
        var m = 0, l = 0, n = 0, j = 0
        var xt: Float = 0.0
        
        var sw1: Float = 0.0
        var sw2: Float = 0.0
        
        let size = ending
        
        var pos: Bool = false
        var neg: Bool = false
        var jn: Float = 0.0
        
        for i in starting..<size {
            sw1 = (delegate.mySoundContainer.soundData?[i])!
            sw2 = (delegate.mySoundContainer.soundData?[i+1])!
            
            if (sw1<=Float(zeroThres)) && (sw2>Float(zeroThres)) {
                if (!pos) && (!neg) {
                    jn = Float(i) + (abs(sw1)/(abs(sw1)+abs(sw2)))
                    pos = true
                }
                else if pos && neg {
                    neg = false
                    tempresults_time.append(jn+((Float(i)-jn+(abs(sw1)/(abs(sw1)+abs(sw2))))/2.0)) //[m]=
                    tempresults_wave.append(Float(i)-jn+(abs(sw1)/(abs(sw1)+abs(sw2)))) //[m]=
                    m += 1
                    jn=Float(i)+(abs(sw1)/(abs(sw1)+abs(sw2)))
                }
                else if !pos && neg { pos=true }
            }
            else if sw1 > Float(-1*zeroThres) && sw2 <= Float(-1*zeroThres) {
                if !pos && !neg {
                    jn = Float(i) + (abs(sw1)/(abs(sw1)+abs(sw2)))
                    neg = true
                }
                else if pos && neg {
                    pos = false
                    tempresults_time.append(jn + ( ( Float(i) - jn + (abs(sw1)/(abs(sw1)+abs(sw2))))/2.0)) //[m] =
                    tempresults_wave.append(Float(i)-jn+(abs(sw1)/(abs(sw1)+abs(sw2)))) //[m]=
                    m += 1
                    jn=Float(i)+(abs(sw1)/(abs(sw1)+abs(sw2)))
                }
                else if !neg && pos { neg=true }
            }
        }
                
        /* Debugger */
        
        if self.delegate.debugDelegate != nil && self.debugFirstStep {
            callFinderGroup.enter()
            self.delegate.debugDelegate!.startSample = starting
            self.delegate.debugDelegate!.sizeSamples = ending
            self.delegate.debugDelegate!.tempresults_time = tempresults_time
            self.delegate.debugDelegate!.tempresults_wave = tempresults_wave
            callFinderGroup.wait()
        }
        /* ****************** */
        
        let dataCount = 200
        var temparray: Array<(Float,Float)> = Array(repeating:(0.0, 0.0), count:dataCount)
        m -= 1
        var index = 0
        l = 0
        n = 0
        if tempresults_time.count < 2 {
            return
        }
        j = Int(tempresults_time[0])
        
        while ( index < tempresults_time.count && tempresults_time[index]-Float(j) < Float(zcwindowsize) && index <= m) {
            //temparray.append((Float(tempresults_time[index]),Float(tempresults_wave[index])))
            // NEW - ADD to bcAdmin/bcAnalyze
            temparray[index] = ((Float(tempresults_time[index]),Float(tempresults_wave[index])))
            // NEW - ADD to bcAdmin/bcAnalyze
            l += 1
            index += 1
        }
        
        if (index >= tempresults_time.count) {
            index = tempresults_time.count-1
        }
        
        if tempresults_time[index] - Float(j) > Float(zcwindowsize) {
            index -= 1
            l -= 1
        }
        l += 1
                
        zcTimeData.append(0.0)
        zcFreqData.append(0.0)
        
        /* Debugger */
        if self.delegate.debugDelegate != nil && self.debugRegression {
            self.delegate.debugDelegate!.tempresults_time = temparray.map{$0.0}
            // wavelenghts converted to frequencies
            self.delegate.debugDelegate!.tempresults_wave = temparray.map{Float(1.0/Double($0.1*Float(time_correct)))}
            self.delegate.debugDelegate?.xtValues = Array()
            self.delegate.debugDelegate?.regressionMSEPerWindow = Array()
        }
        /* ****************** */
        
        while index <= m {		// found all data of one window... quality and regression ?
            xt = Float(regression_two(arr: temparray, numberOfSamples:l))
            if xt < 60 && xt>0 { // Woher kommen diese Werte ??? -> sollte sein: entsprechen wellenlängen und damit frequenzen
                count += 1;
                zcTimeData.append(Float(temparray[0].0) + Float(zcwindowsize/2.0))
                zcFreqData.append(1.0/Double(xt*Float(time_correct)))
                
                /* Debugger */
                if self.delegate.debugDelegate != nil && self.debugRegression {
                    callFinderGroup.enter()
                    self.delegate.debugDelegate!.xtValues.append((1.0/(xt*Float(time_correct))))
                    DispatchQueue.main.async { [self] in
                        self.delegate.debugDelegate!.tempresults_time = temparray.map{$0.0}
                        // wavelenghts converted to frequencies
                        self.delegate.debugDelegate!.tempresults_wave = temparray.map{Float(1.0/Double($0.1*Float(self.time_correct)))}
                        self.delegate.debugDelegate!.regressionPanel.orderFront(nil)
                        self.delegate.debugDelegate!.regressionDataLayer.setNeedsDisplay()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.debugRegressionSpeed) {
                        if !self.delegate.debugDelegate!.debugRegressionPause {
                            callFinderGroup.leave()
                        }
                    }
                    callFinderGroup.wait()
                }
                /* ****************** */
                
                //NSLog(@"at i %d w/ 1.MSE: d %.02f ; freq %.02f",i,zcTimeData[count]-zcTimeData[count-1],zcFreqData[count]);
            } else {
                /* Debugger */
                if self.delegate.debugDelegate != nil && self.debugRegression && (self.debugRegressionShowOutsideMSE && zcTimeData.count > 0) {
                    callFinderGroup.enter()
                    self.delegate.debugDelegate!.xtValues.append((1.0/(xt*Float(time_correct))))
                    DispatchQueue.main.async { [self] in
                        self.delegate.debugDelegate!.tempresults_time = temparray.map{$0.0}
                        // wavelenghts converted to frequencies
                        self.delegate.debugDelegate!.tempresults_wave = temparray.map{Float(1.0/Double($0.1*Float(self.time_correct)))}
                        self.delegate.debugDelegate!.regressionPanel.orderFront(nil)
                        self.delegate.debugDelegate!.regressionDataLayer.setNeedsDisplay()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.debugRegressionSpeed) {
                        if !self.delegate.debugDelegate!.debugRegressionPause {
                            callFinderGroup.leave()
                        }
                    }
                    callFinderGroup.wait()
                }
                /* ****************** */
            }
            
            if Int(index) == Int(m) && Float(tempresults_time[index] - tempresults_time[n]) < Float(zcwindowsize*0.75) { break }
            //NSLog(@"i %d",i);
            n += 1
            // STILL NEEDED?! if n >= zcDataSize { break }
            if n >= tempresults_time.count { break }
            j = Int(tempresults_time[n])
            
            while Int(tempresults_time[index]) - j < Int(zcwindowsize) && index < m { index += 1 }
            
            while Int(tempresults_time[index]) - j > Int(zcwindowsize) || index > m { index -= 1 }
            
            //for l=0;l<=(index-n);l++ {
            
            // NEW - ADD to bcAdmin/bcAnalyze
            temparray = Array(repeating:(0.0, 0.0), count:dataCount)
            // NEW - ADD to bcAdmin/bcAnalyze
            
            for inL in 0...(index-n) {
                temparray[inL].0 = tempresults_time[n+inL]
                temparray[inL].1 = tempresults_wave[n+inL]
            }
            l = (index-n)+1
            //NSLog(@"i %d, n %d, l %d und i-n %d und count %d",n,i,l,i-n, count);
        }
        
        zcTimeData[0]=Float(count)
        tempresults_time.removeAll()
        tempresults_wave.removeAll()
        
        /* Debugger */
        
        if self.delegate.debugDelegate != nil && self.debugShowzcData {
            callFinderGroup.enter()
            //self.delegate.debugDelegate!.marker = [0,tempresults_time[index]-Float(j)]
            self.delegate.debugDelegate!.startSample = Int(zcTimeData[1])
            self.delegate.debugDelegate!.sizeSamples = Int(zcTimeData.last!)// - zcTimeData[1])
            self.delegate.debugDelegate!.tempresults_time = zcTimeData.map{Float($0)}
            self.delegate.debugDelegate!.tempresults_wave = zcFreqData.map{Float($0)}
            callFinderGroup.wait()
        }
        /* ****************** */
        
        /*	*********************
         end of zero crossing analysis
         **********************/
        
        
        /*	*****************************************************
         Now we have to find the exact call location and get
         the call measurements. This was formerly known as
         SoundRegression. It will decide what to return to the caller
         ***************************************************** */
        
        m = 0; index = 0; j = 0; l = 0; count = 0;
        
        var start = 1
        var startsample = 0.0
        var callstart = 0.0
        var end = 0
        var startFound = false
        var mse = 0.0
        var regA = 0.0
        var regB = 0.0
        
        var zeroAdjust = 0.0
        var measureCount = 0
        var lastMeasure = 0.0
        var msCallStart = 0.0
        var maxDist: Float = 0.0
        
        // CHANGED - ADD to bcAdmin/bcAnalyze
        var startPoints: Array<Int> = Array()
        var endingPoints: Array<Int> = Array()
        var lengthSamples: Array<Int> = Array()
        // CHANGED - ADD to bcAdmin/bcAnalyze - the following loop needs to be adjusted as well
        var sprung = srahead-1
        
        if zcTimeData.count < 2 {
            return
        }
        
        end = Int(zcTimeData[0])
        startsample = Double(zcTimeData[1])
        index = start+sprung
        
        /* Debugger */
        
        if self.delegate.debugDelegate != nil && self.debugCallStart {
            self.delegate.debugDelegate!.startSample = Int(zcTimeData[1])
            self.delegate.debugDelegate!.sizeSamples = Int(zcTimeData.last!)
            self.delegate.debugDelegate!.tempresults_time = zcTimeData.map{Float($0)}
            self.delegate.debugDelegate!.tempresults_wave = zcFreqData.map{Float($0)}
        }
        /* ****************** */
        
        while (index <= end) {
            
            mse = self.regressionFrom(start: start, end: index, withA: &regA, withB: &regB)
           
            /* Debugger */
            
            if self.delegate.debugDelegate != nil && self.debugCallStart {
                callFinderGroup.enter()
                self.delegate.debugDelegate!.regressionMSEPerWindow = [Float(start), Float(index), Float(regA), Float(regB), Float(mse)]
                if !self.debugCallStartSkipRegressionDisplay {
                    DispatchQueue.main.async {
                        self.delegate.debugDelegate!.measurementRegressionLayer.setNeedsDisplay()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        callFinderGroup.leave()
                    }
                    callFinderGroup.wait()
                }
                else {
                    callFinderGroup.leave()
                }
            }
            /* ****************** */
            
            maxDist = 0.0
            for l in start..<index {
                if Float(zcTimeData[l+1] - zcTimeData[l]) > maxDist {
                    maxDist = zcTimeData[l+1] - zcTimeData[l]
                }
            }
            
            if maxDist <= Float(mincallint) {
                if (mse<=formse) {
                    if (!startFound) {
                        startFound = true
                        startPoints.append(start)
                        callstart=startsample
                    }
                }
                else if (mse>formse) {
                    if (startFound) {
                        startFound = false
                        endingPoints.append(index-1)
                        lengthSamples.append(Int(zcTimeData[index-1]-Float(callstart)))
                    }
                }
            }
                
            else if (startFound && maxDist > Float(mincallint)) {
                startFound = false
                l = start
                while zcTimeData[l+1] - zcTimeData[l] <= Float(mincallint) { l += 1 }
                index=l
                endingPoints.append(index)
                lengthSamples.append(Int(zcTimeData[index]-Float(callstart)))
            }
            
            start += 1
            startsample = Double(zcTimeData[start])
            index=start+sprung
        }
        
        if (startFound && start < end) { // Ende abfangen !!!
            startFound = false
            index = end
            mse = self.regressionFrom(start: start, end: index, withA: &regA, withB: &regB)
            
            /* Debugger */
            
            if self.delegate.debugDelegate != nil && self.debugCallStart {
                callFinderGroup.enter()
                self.delegate.debugDelegate!.regressionMSEPerWindow = [Float(start), Float(index), Float(regA), Float(regB), Float(mse)]
                DispatchQueue.main.async {
                    self.delegate.debugDelegate!.measurementRegressionLayer.setNeedsDisplay()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        callFinderGroup.leave()
                }
                callFinderGroup.wait()
            }
            /* ****************** */
            
            maxDist=0.0
            for inL in start..<index {
                if Float(zcTimeData[inL+1] - zcTimeData[inL]) > maxDist { maxDist = zcTimeData[inL+1] - zcTimeData[inL] }
            }
            l = index
            
            if maxDist <= Float(mincallint) {
                if (mse<=formse) {
                    endingPoints.append(index)
                    lengthSamples.append(Int(zcTimeData[index]-Float(callstart)))
                }
                else if (mse>formse) {
                    index = start-1+sprung
                    endingPoints.append(index)
                    lengthSamples.append(Int(zcTimeData[index]-Float(callstart)))
                }
            }
                
            else if maxDist > Float(mincallint) {
                l = start
                while zcTimeData[l+1] - zcTimeData[l] <= Float(mincallint) { l += 1 }
                index=l
                endingPoints.append(index)
                lengthSamples.append(Int(zcTimeData[index]-Float(callstart)))
            }
        }
        else if (startFound && start == end ) {
            startFound = false
            index = end
            endingPoints.append(index)
            lengthSamples.append(Int(zcTimeData[index]-Float(callstart)))
        }
        
        /* Debugger */
        
        if self.delegate.debugDelegate != nil && self.debugCallStart {
            //callFinderGroup.enter()
            self.delegate.debugDelegate!.callStartEndRegression = Array()
            for (index, aValue) in startPoints.enumerated() {
                self.delegate.debugDelegate!.callStartEndRegression.append((aValue, endingPoints[index]))
            }
            DispatchQueue.main.async {
                self.delegate.debugDelegate!.measurementRegressionLayer.setNeedsDisplay()
            }
            //callFinderGroup.wait()
        }
        /* ****************** */
        
        /*	*********************
         end of sound regression
         **********************/
        // before we start, we lower the "sprung" to get more acurate regeressions
        // 2022 comment: make it adjustable?
        sprung = 4
        
        var tempDict: Dictionary<String,Float> = Dictionary()
        
        //for l in 0..<k {
        for l in 0..<startPoints.count {
            //autoreleasepool {
            if lengthSamples[l]>=250 {
                // NEW - ADD to bcAdmin/bcAnalyze
                tempDict.removeAll()
                // NEW - ADD to bcAdmin/bcAnalyze
                m=startPoints[l]
                startsample = Double(self.zcTimeData[m])
                zeroAdjust = startsample-1
                callstart=startsample-(self.zcwindowsize/2.0)
                msCallStart = self.time_correct*callstart;
                
                index=1;
                while (self.zcTimeData[m+index]-self.zcTimeData[m] <= Float(self.sampleFactor/10)) { index += 1 }
                
                mse = self.regressionFrom(start: m, end: m+index, withA: &regA, withB: &regB)
                
                tempDict["Startsample"] = Float(callstart)
                tempDict["Start"] = Float(self.time_correct*callstart)
                tempDict["SFreq"] = Float(regA+((callstart-zeroAdjust))*regB)
                tempDict["Freq1"] = Float(regA+(((callstart+Double(self.sampleFactor/10))-zeroAdjust))*regB)
                tempDict["Time1"] = Float((self.time_correct*(callstart+Double(self.sampleFactor/10)))-msCallStart)
                tempDict["Freq2"] = Float(regA+((callstart+Double(self.sampleFactor/10)*2) - zeroAdjust)*regB)
                tempDict["Time2"] = Float((self.time_correct*((callstart+Double(self.sampleFactor/10)*2)))-msCallStart)
                
                // wegen 300us Fenster rausgenommen!
                //[tempDict setObject:[NSNumber numberWithFloat:(regA+(((callstart+150)) - zeroAdjust)*regB)] forKey:@"Freq3"];
                //[tempDict setObject:[NSNumber numberWithFloat:(time_correct*((callstart+150)))-msCallStart] forKey:@"Time3"];
                
                measureCount = 2;
                lastMeasure = callstart+Double(self.sampleFactor/10)*2
                
                var realSample = Double(((msCallStart + 0.1*Double(measureCount))*Double(self.sampleFactor)))
                let endAt = Double(self.zcTimeData[endingPoints[l]])
                
                let d10 = Double(self.sampleFactor/10)
                let d20 = Double(self.sampleFactor/20)
                let greaterTimeDataIndex = endingPoints[l]
                while self.zcTimeData[m] < self.zcTimeData[greaterTimeDataIndex] && (realSample+d10) <= (endAt+d20) {
                    if (startsample < realSample+d10) {
                        m += 1
                        startsample = Double(self.zcTimeData[m])
                    }
                    
                    if (startsample >= lastMeasure) {
                        measureCount += 1
                        zeroAdjust = startsample-1
                        realSample = ((msCallStart + 0.1*Double(measureCount))*Double(self.sampleFactor))
                        while (startsample > realSample) {
                            m -= 1
                            if m<0 {
                                m = 0
                                break
                            }
                            startsample=Double(self.zcTimeData[m])
                        }
                        zeroAdjust = startsample-1
                        if (m+sprung > endingPoints[l]) {
                            //mse = [self regressionFrom:endingPoints[l]-sprung to:endingPoints[l] withA:&regA withB:&regB];
                            mse = self.regressionFrom(start: endingPoints[l]-sprung, end: endingPoints[l], withA: &regA, withB: &regB)
                            zeroAdjust = Double(self.zcTimeData[endingPoints[l]-sprung])-1
                        }
                        else {
                            if realSample > Double(self.zcTimeData[m+sprung]) {
                                index=0
                                while (m+sprung+index < self.zcTimeData.count-1 && realSample > Double(self.zcTimeData[m+sprung+index]) && index < endingPoints[l]) {index += 1}
                                //mse = [self regressionFrom:m to:m+sprung+i withA:&regA withB:&regB];
                                mse = self.regressionFrom(start: m, end: m+sprung+index, withA: &regA, withB: &regB)
                            }
                            //mse = [self regressionFrom:m to:m+sprung withA:&regA withB:&regB];
                            mse = self.regressionFrom(start: m, end: m+sprung, withA: &regA, withB: &regB)
                        }
                        tempDict["Freq\(measureCount)"] = Float(regA+(realSample - zeroAdjust)*regB)
                        tempDict["Time\(measureCount)"] = Float((self.time_correct*(realSample))-msCallStart)
                        
                        if debug {
                            Swift.print("\(measureCount) :: \(Float(regA+(realSample - zeroAdjust)*regB))")
                        }
                            
                        //[tempDict setObject:[NSNumber numberWithFloat:(regA+(realSample - zeroAdjust)*regB)] forKey:[NSString stringWithFormat:@"Freq%d",measureCount]];
                        //[tempDict setObject:[NSNumber numberWithFloat:(time_correct*(realSample))-msCallStart] forKey:[NSString stringWithFormat:@"Time%d",measureCount]];
                        lastMeasure = realSample
                    }
                }
                
                realSample = realSample+d10
                measureCount += 1
                zeroAdjust = Double(self.zcTimeData[m])-1
                if (m+sprung > endingPoints[l]) {
                    /* älterer kommentar! i=1;
                     while (zcTimeData[l]-zcTimeData[l-i] <= (sampleFactor/10)) i++;
                     if (i>2) i--;
                     mse = [self regressionFrom:endingPoints[l]-i to:endingPoints[l] withA:&regA withB:&regB];
                     zeroAdjust = zcTimeData[endingPoints[l]-i]-1;*/
                    
                    //mse = [self regressionFrom:endingPoints[l]-sprung to:endingPoints[l] withA:&regA withB:&regB];
                    mse = self.regressionFrom(start: endingPoints[l]-sprung, end: endingPoints[l], withA: &regA, withB: &regB)
                    zeroAdjust = Double(self.zcTimeData[endingPoints[l]-sprung])-1
                }
                else {
                    //mse = [self regressionFrom:m to:m+sprung withA:&regA withB:&regB];
                    mse = self.regressionFrom(start: m, end: m+sprung, withA: &regA, withB: &regB)
                }
                tempDict["EFreq"] = Float((regA+(realSample - zeroAdjust)*regB))
                tempDict["Size"] = Float(self.time_correct*(realSample - callstart))
                tempDict["Sizesample"] = Float(realSample - callstart)
                //[tempDict setObject:[NSNumber numberWithFloat:(regA+(realSample - zeroAdjust)*regB)] forKey:@"EFreq"];
                //[tempDict setObject:[NSNumber numberWithFloat:time_correct*(realSample - callstart)] forKey:@"Size"];
                //[tempDict setObject:[NSNumber numberWithInt:realSample - callstart] forKey:@"Sizesample"];
                
                if (realSample < endAt+self.zcwindowsize/2-d10) {
                    tempDict["Freq\(measureCount)"] = Float((regA+(realSample - zeroAdjust)*regB))
                    tempDict["Time\(measureCount)"] = Float((self.time_correct*(realSample))-msCallStart)
                    if debug {
                        Swift.print("\(measureCount) :: :: \(Float(regA+(realSample - zeroAdjust)*regB))")
                    }
                    //[tempDict setObject:[NSNumber numberWithFloat:(regA+(realSample - zeroAdjust)*regB)] forKey:[NSString stringWithFormat:@"Freq%d",measureCount]];
                    //[tempDict setObject:[NSNumber numberWithFloat:(time_correct*(realSample))-msCallStart] forKey:[NSString stringWithFormat:@"Time%d",measureCount]];
                    
                    realSample = realSample+d10
                    /* alter kommentar ! i=1;
                     while (zcTimeData[l]-zcTimeData[l-i] <= (sampleFactor/10)) i++;
                     if (i>2) i--;
                     mse = [self regressionFrom:endingPoints[l]-i to:endingPoints[l] withA:&regA withB:&regB];
                     zeroAdjust = zcTimeData[endingPoints[l]-i]-1;*/
                    
                    mse = self.regressionFrom(start: endingPoints[l]-sprung, end: endingPoints[l], withA: &regA, withB: &regB)
                    zeroAdjust = Double(self.zcTimeData[endingPoints[l]-sprung])-1
                    
                    tempDict["EFreq"] = Float((regA+(realSample - zeroAdjust)*regB))
                    tempDict["Size"] = Float(self.time_correct*(realSample - callstart))
                    tempDict["Sizesample"] = Float(realSample - callstart)
                    
                    //[tempDict setObject:[NSNumber numberWithFloat:(regA+(realSample - zeroAdjust)*regB)] forKey:@"EFreq"];
                    //[tempDict setObject:[NSNumber numberWithFloat:time_correct*(realSample - callstart)] forKey:@"Size"];
                    //[tempDict setObject:[NSNumber numberWithInt:realSample - callstart] forKey:@"Sizesample"];
                }
                //for (m=0;m<6;m++) NSLog(@"m: %d Time %f und F %f",m,zcTimeData[endingPoints[l]-5+m],zcFreqData[endingPoints[l]-5+m]);
                let size = tempDict["Size"]! * 10
                
                var index = 1
                while tempDict["Freq\(index)"] != nil {
                    if index > Int(size) {
                        tempDict.removeValue(forKey: "Freq\(index)")
                        tempDict.removeValue(forKey: "Time\(index)")
                    }
                    index += 1
                }
                
                
                Swift.print(" \(self.dataArray.count) - \(String(describing: tempDict["Startsample"]!)) - \(String(describing: tempDict["Sizesample"]!)) ======= ======= ======= ======= ")
                let thisCallMeasures = CallMeasurements(callData: tempDict, callNumber:0, species:"", speciesProb:0, meanFrequency: 0.0)
                
                self.dataArray.append(thisCallMeasures)
                //[tdaten addObject:[[tempDict mutableCopy] autorelease]];
            }
            //} // autorelease
        }
        zcTimeData.removeAll()
        zcFreqData.removeAll()
        
        tempDict.removeAll()
    }
    
    func cleanUpCallData() {
        
        var i = 0
        var count = dataArray.count
        var last: Float = 0.0
        var lastStart: Float = 0.0
        
        while i<count {
            if dataArray[i].callData["Size"]! < Float(mincalllength)
            {
                dataArray.remove(at: i)
                i -= 1
                count -= 1
            }
            i += 1
        }
        
        count = dataArray.count
        
       
        if count > 1 {
            last = dataArray[0].callData["Startsample"]!+dataArray[0].callData["Sizesample"]!
            
            //for i=1;i<count;i++ {
            i = 1
            while i<count {
                if dataArray[i].callData["Startsample"]! - last < Float(mincalldist) {
                    dataArray.remove(at: i)
                    i -= 1
                    count -= 1
                }
                else {
                    last = dataArray[i].callData["Startsample"]!+dataArray[i].callData["Sizesample"]!
                }
                i += 1
            }
        }
        else if count == 1 {
            dataArray[0].callNumber = 1
        }
        
        count = dataArray.count
        lastStart = -1
        //for i=0;i<count;i++ {
        for i in 0..<count {
            let myStart = dataArray[i].callData["Startsample"]
            dataArray[i].callData["Startsample"] = myStart!// - Float(self.startSample)
            if dataArray[i].callData["Startsample"]! < 0 {
                dataArray[i].callData["Startsample"] = myStart!
            }
            dataArray[i].callNumber = i+1
            if lastStart < 0 {
                dataArray[i].callData["IPI"] = 0
            }
            else {
                dataArray[i].callData["IPI"] = dataArray[i].callData["Start"]! - lastStart
            }
            lastStart = dataArray[i].callData["Start"]!
        }
    }
}

class CallCSVExporter {
    
    var klassen_avg: [Double] = Array(repeating: 0.0, count: 152)
    
    // #define ELEM_SWAP(a,b) { register float t=(a);(a)=(b);(b)=t; }
    func swap(a: inout Float, b: inout Float) {
        let temporaryA = a
        a = b
        b = temporaryA
    }
    
    func newSwap(data: inout Array<Float>, firstPos:Int, secondPos: Int) {
        let temporaryA = data[firstPos]
        data[firstPos] = data[secondPos]
        data[secondPos] = temporaryA
    }
    
    func median(arr: inout Array<Float>, count: Int) -> Float {
        //var inArray: [Float] = arr
        var low = 0
        var high = count - 1
        let median = (low + high) / 2
        var middle = 0
        var ll = 0
        var hh = 0
        
        while 1==1 {
            if high <= low {
                return arr[median]
            }
            
            if high == low + 1 {  /* Two elements only */
                
                if (arr[low] > arr[high]) {
                    self.newSwap(data: &arr, firstPos: low, secondPos: high)
                }
                return arr[median]
            }
            
            /* Find median of low, middle and high items; swap into position low */
            middle = (low + high) / 2
            if arr[middle] > arr[high]    { self.newSwap(data: &arr, firstPos: middle, secondPos: high)}
            if arr[low] > arr[high]       { self.newSwap(data: &arr, firstPos: low, secondPos: high)}
            if arr[middle] > arr[low]     { self.newSwap(data: &arr, firstPos: middle, secondPos: low) }
            
            /* Swap low item (now in position middle) into position (low+1) */
            self.newSwap(data: &arr, firstPos: middle, secondPos: low+1)
            
            ll = low + 1
            hh = high
            
            while 1==1 {
                repeat { ll += 1 } while (arr[low] > arr[ll])
                repeat { hh -= 1 } while (arr[hh]  > arr[low])
                
                if (hh < ll) { break }
                
                self.newSwap(data: &arr, firstPos: ll, secondPos: hh)
            }
            
            self.newSwap(data: &arr, firstPos: low, secondPos: hh)
            
            if hh <= median { low = ll }
            if hh >= median { high = hh - 1 }
        }
    }
    
    func maxFreq(arr: Array<Float>, count: Int) -> Float {
        var max: Float
        var i = 1
        max = arr[0]
        
        while i<count {
            if max<arr[i] {
                max = arr[i]
            }
            i += 1
        }
        return max
    }
    
    func minFreq(arr: Array<Float>, count: Int) -> Float {
        var min: Float
        var i = 1
        min = arr[0]
        
        while i<count {
            if min>arr[i] {
                min = arr[i]
            }
            i += 1
        }
        return min
    }
    
    func steigung(arr: Array<Array<Float>>, count: Int) -> Float
    {
        //regression vars
        var s_x: Double // 10 if avgsize = 4!
        var ss_x: Double // 10 if avgsize = 4!
        var s_f = 0.0
        var s_xf = 0.0
        var b: Double
        //var a: Double = 0.0
        // end regression vars
        
        //var k: Int
        
        // sum of x's
        s_x = 0
        for k in 0..<count {
            s_x = s_x + Double(arr[k][0])
        }
        
        // sum of squares of x's
        ss_x=0
        for k in 0..<count {
            ss_x = ss_x + Double( (arr[k][0]) * (arr[k][0]) )
        }
        
        // sum of frequencies
        s_f=0
        for k in 0..<count {
            s_f = s_f + Double(arr[k][1])
        }
        
        // sum of x*frequencies
        s_xf=0
        for k in 0..<count {
            s_xf = s_xf + Double( (arr[k][0]) * arr[k][1] )
        }
        
        //b = (double) (s_xf - ((s_x*s_f)/(float)n)) / (double) (ss_x-(((s_x*s_x)/(float)n)));
        b = (s_xf - ((s_x*s_f)/Double(count))) / (ss_x - ( (s_x*s_x) / Double(count)))
        //a = (s_f - (s_x*b)) / Double(count)
        
        return Float(b)
    }
    
    func modalFreq(arr: Array<Float>, count: Int, steig: inout Float) -> Float
    {
        var wsize = 24
        var start = 0
        var merker: Int = 0
        
        var min: Float = 1000.0
        var temp: Float
        var data: Array<Array<Float>> = Array()
        for index in 0..<wsize {
            data.append([Float(index), Float(0.0)])
        }
        
        while wsize < count {
            //for i = start; i < wsize; i++ {
            for i in start..<wsize {
                data[i-start][1] = arr[i]
            }
            
            temp = self.steigung(arr: data, count: wsize-start)
            if temp<min {
                min = temp
                merker = start
            }
            start += 1
            wsize += 1
        }
        
        var tempArray: Array<Float> = Array(repeating:Float(), count: wsize)
        //for (i = 0; i < wsize-start; i++) {
        for i in 0..<(wsize-start) {
            tempArray[i] = arr[i+merker];
        }
        
        steig = 10*min;
        return self.median(arr: &tempArray, count: wsize-start)
    }
    
    func getNMod(call: Dictionary<String, Float>, freq: inout Int ) -> Float {
        var l: Int
        //var j: Int
        var index: Int
        var nfreq = 0
        freq = nfreq
        
        l = Int(ceil(10.0*call["Size"]!))
        //l = ceil(10*[[call objectForKey:@"Size"] floatValue])
        
        while nil==call["Freq\(l)"] && l > 0{
            l -= 1
        }
        
        if l == 0 {
            return Float(0)
        }
        
        var klassen_alle: [Int] = Array(repeating: 0, count:152)
        //for j=0;j<152;j++ {
        for j in 0..<152 {
            klassen_alle[j]=0
            self.klassen_avg[j] = 0.0
        }
        
        // Fill histogram data ***
        var tempArray: [Float] = Array(repeating: 0.0, count:l+2)
        
        //var subJ: Int
        var expJ = (l+1)*9 + l + 1
        var fPart = 0.0
        
        tempArray[l+1] = call["EFreq"]!
        tempArray[0] = call["SFreq"]!
        
        index = Int(floor(call["SFreq"]!))
        index = (index>150 ? 0 : index)
        if index < 0 {
            index = 0
        }
        
        klassen_alle[index] = klassen_alle[index]+1
        
        //for (j=l;j>0;j--) {
        for j in stride(from: l, to: 0, by: -1) {
            tempArray[j] = call["Freq\(j)"]!
            expJ -= 1
            
            index = Int(floor(call["Freq\(j)"]!))
            index = (index>150 ? 0 : index)
            if index < 0 {
                index = 0
            }
            klassen_alle[index] = klassen_alle[index]+1
            
            fPart = Double(tempArray[j] - tempArray[j+1]) / 10.0
            //for (subJ = 1; subJ < 10; subJ++) {
            for subJ in 1..<10 {
                expJ -= 1
                index = Int(floor(Double(tempArray[j])-fPart*Double(subJ)))
                index = (index>150 ? 0 : index)
                if index < 0 {
                    index = 0
                }
                klassen_alle[index] = klassen_alle[index]+1
            }
        }
        
        fPart = Double(tempArray[0] - tempArray[1]) / 10.0
        
        //for (subJ = 1; subJ < 10; subJ++) {
        for subJ in 1..<10 {
            expJ -= 1
            index = Int(floor(Double(tempArray[0])-fPart*Double(subJ)))
            index = (index>150 ? 0 : index)
            if index < 0 {
                index = 0
            }
            klassen_alle[index] = klassen_alle[index]+1
        }
        
        // *** End of histogram fill
        
        // *** Start of Average Shifted Histogramm ***
        var odd = 9
        var even=9
        var sum=0
        
        //for (j = 10; j < 150; j++) { // upper limit was 151 -> lead to a crash!
        for j in stride(from: 10, to: 150, by: 2) {
            even += 1
            odd += 1
            sum = klassen_alle[even]+klassen_alle[even+1] + klassen_alle[odd-1]+klassen_alle[odd]
            klassen_avg[j]=Double(sum)/4.0
            even += 1
            odd += 1
            sum=klassen_alle[even]+klassen_alle[even+1] + klassen_alle[odd-1]+klassen_alle[odd]
            klassen_avg[j+1]=Double(sum)/4.0
        }
        
        // *** End of Average Shifted Histogramm ***
        
        var nmod = 0.0
        //for (j = 10; j < 151; j++) {
        for j in 10..<151 {
            if (nmod < klassen_avg[j]) {
                nmod = klassen_avg[j]
                nfreq=j
            }
        }
        
        
        freq = nfreq
        return Float(nmod)
    }
    
    func getRMinForCall(call: Dictionary<String, Float>, Rmin: inout Float, FRmin : inout Float, tRmin: inout Float ) {
        
        var l = 0
        //var j = 0
        var minpos = 0
        
        var tempR: Float = 0.0
        var rmin: Float = 0.0
        var fmin: Float = 0.0
        var tmin: Float = 0.0
        
        l = Int(ceil(10.0*call["Size"]!))
        
        while nil==call["Freq\(l)"] && l > 0{
            l -= 1
        }
        
        if l == 0 {
            Rmin = Float(0)
            FRmin = Float(0)
            tRmin = Float(0)
            return
        }
        
        var rs: [Float] = Array(repeating:0.0, count:l+1)
        var fs: [Float] = Array(repeating:0.0, count:l+1)
        var ts: [Float] = Array(repeating:0.0, count:l+1)
        
        rs[0] = (call["SFreq"]!-call["Freq1"]!) / 0.1
        fs[0] = (call["SFreq"]!+call["Freq1"]!) / 2.0
        ts[0] = -1.0*(call["Size"]!-0.1)
        rs[l] = (call["Freq\(l)"]!-call["EFreq"]!) / 0.1
        fs[l] = (call["Freq\(l)"]!+call["EFreq"]!) / 2.0
        ts[l] = -0.0
        
        //for (j=1;j<l-1;j++) {
        for j in 1..<(l-1) {
            rs[j] = ((call["Freq\(j)"]! - call["Freq\(j+1)"]!) / 0.1)
            fs[j] = ((call["Freq\(j)"]! + call["Freq\(j+1)"]!) / 2.0)
            ts[j] = -1.0 * (call["Size"]! - (call["Size"]! - (0.1*Float(l-j+1))))
        }
        
        minpos = 0
        tempR = abs((rs[0]+rs[1]+rs[2])/3.0)
        //for (j=1;j<l-3;j++) {
        for j in 1..<(l-3) {
            if (tempR>abs(((rs[j]+rs[j+1]+rs[j+2])/3.0))) {
                tempR=abs(((rs[j]+rs[j+1]+rs[j+2])/3.0))
                minpos=j
            }
        }
        
        rmin = abs(rs[minpos])
        fmin = fs[minpos]
        tmin = ts[minpos]
        
        //for (j=minpos+1;j<minpos+3;j++) {
        for j in minpos+1..<(minpos+3) {
            if (rmin>abs(rs[j])) {
                rmin = abs(rs[j])
                fmin = fs[j]
                tmin = ts[j]
            }
        }
        Rmin = rmin
        FRmin = fmin
        tRmin = tmin
    }
    
    func exportCallMeasurements( inArray: Array<CallMeasurements> ) -> Bool {
        
        let sp = NSSavePanel()
        
        //sp.directoryURL:[[NSApp delegate] exportPath]];
        //TODO:
        //sp.nameFieldStringValue = (NSDocumentController.sharedDocumentController().currentDocument as! SoundDocument).fileURL!.lastPathComponent!.stringByDeletingPathExtension
        sp.title = "Save batIdent file"
        sp.allowedFileTypes = ["csv"]
        if sp.runModal() == .OK {
            return self.exportCallMeasurements(inArray: inArray, toFile: sp.url!.path)
        }
        return false
    }
    
    func generateCallMeasurements(inArray: inout Array<CallMeasurements>) {
        //var exportString = ""
        //var csvArray: Array<Dictionary<String,Float>> = Array()
        //var i = 0
        //var j = 0
        var l = 0
        
        var nmod: Float = 0.0
        var rmin: Float = 0.0
        var frmin: Float = 0.0
        var trmin: Float = 0.0
        var nfreq = 99
        
        //exportString += "Datei\tArt\tRuf\tDur\tSfreq\tEfreq\tStime\tNMod\tFMod\tFRmin\tRmin\ttRmin\tRlastms\tFlastms"
        /* Generate labels for classing according... first 10 to 60 kHz 1 kHz bins, then 2 kHz bins to 150
         for i in 0..<50 {
         exportString += NSString(format: "\tX%2d", i+10)
         }
         i = 0
         for i;i<90;i+=2 {
         exportString += NSString(format:"\tX%2d", i+60)
         }*/
        
        // add parameters per call entry
       
        for i in 0..<inArray.count {
            var callDict: Dictionary<String,Float> = Dictionary()
            // original war: geht nicht in swift, wieso war das da überhaupt? if (![[[inArray objectAtIndex:i] objectForKey:@"Call"] isKindOfClass:[NSString class]]) {
            
            nmod = self.getNMod(call: inArray[i].callData, freq:&nfreq)
            callDict.updateValue(nmod, forKey: "NMod")
            callDict.updateValue(Float(nfreq), forKey: "FMod")
            
            self.getRMinForCall(call: inArray[i].callData, Rmin: &rmin, FRmin: &frmin, tRmin: &trmin)
            callDict.updateValue(frmin, forKey: "FRmin")
            callDict.updateValue(rmin, forKey: "Rmin")
            callDict.updateValue(trmin, forKey: "tRmin")
            
            l = Int(ceil(10.0*inArray[i].callData["Size"]!))
            while nil==inArray[i].callData["Freq\(l)"] && l > 0 {
                l -= 1
            }
            
            if l == 0 {
                continue
            }
            
            var lastOneArray: [Float] = Array(repeating:0.0, count:11)
            var lastRArray: [Float] = Array(repeating:0.0, count:10)
            var k = 0
            
            lastOneArray[10] = inArray[i].callData["EFreq"]!
            lastRArray[9] = (inArray[i].callData["Freq\(l)"]!-inArray[i].callData["EFreq"]!)/0.1
            
            k = 0
            //j = l-10
            //if j < 1 { j = 1 }
            for j in (l-10)..<l {
                if j<1 { continue }
                lastOneArray[k] = inArray[i].callData["Freq\(j)"]!
                k += 1
            }
            
            k = 0;
            //j = l-10
            //if j < 1 { j = 1 }
            for j in (l-10)..<(l-1) {
                if j < 1 { continue }
                lastRArray[k] = (inArray[i].callData["Freq\(j)"]!-inArray[i].callData["Freq\(j+1)"]!)/0.1
                k += 1
            }
            
            callDict.updateValue(self.median(arr: &lastRArray,count: 10), forKey:"Rlastms")
            callDict.updateValue(self.median(arr: &lastOneArray,count: 11), forKey:"Flastms")
            
            //exportString += "\t\(self.median(&lastRArray,count: 10))" // 10 udn 11 vertauscht, aber geht eigentlich nicht wegen definierter größe der arrays ?! NACHPRÜFEN!
            //exportString += "\t\(self.median(&lastOneArray,count: 11))"
            
            for j in stride(from: 10, to: 61, by: 1) {
                callDict.updateValue(Float(klassen_avg[j]), forKey:"X\(j)")
                //exportString += "\t\(klassen_avg[j])"
            }
            
            //for j in 60.stride(to: 150, by: 1)
            //for (j=60;j<150;j++) {
            for j in stride(from: 61, to: 150, by: 2) {
                callDict.updateValue(Float(klassen_avg[j])+Float(klassen_avg[j+1]), forKey:"X\(j+1)")
                //exportString += "\t\(klassen_avg[j]+klassen_avg[++j])"
            }
            inArray[i].identData = callDict
        }
    }
    
    func exportCallMeasurements(inArray: Array<CallMeasurements>, toFile:String) -> Bool {
        
        var exportString = ""
        //var i = 0
        //var j = 0
        var l = 0
        
        var nmod: Float = 0.0
        var rmin: Float = 0.0
        var frmin: Float = 0.0
        var trmin: Float = 0.0
        var nfreq = 99
        
        exportString += "Datei\tArt\tRuf\tDur\tSfreq\tEfreq\tStime\tNMod\tFMod\tFRmin\tRmin\ttRmin\tRlastms\tFlastms"
        // Generate labels for classing according... first 10 to 60 kHz 1 kHz bins, then 2 kHz bins to 150
        for i in 0..<50 {
            exportString += NSString(format: "\tX%2d", i+10) as String
        }
        //i = 0
        for i in stride(from: 0, to: 90, by: 2) {
            exportString += NSString(format:"\tX%2d", i+60) as String
        }
        
        // add parameters per call entry
        for i in 0..<inArray.count {
            // original war: geht nicht in swift, wieso war das da überhaupt? if (![[[inArray objectAtIndex:i] objectForKey:@"Call"] isKindOfClass:[NSString class]]) {
            let size = inArray[i].callData["Size"]!
            let SFreq = inArray[i].callData["SFreq"]!
            let EFreq = inArray[i].callData["EFreq"]!
            let Start = inArray[i].callData["Start"]!
            exportString += "\n\t\(inArray[i].species)\t\(inArray[i].callNumber)\t\(size)\t\(SFreq)\t\(EFreq)\t\(Start)"
            
            nmod = self.getNMod(call: inArray[i].callData, freq:&nfreq)
            exportString += "\t\(nmod)\t\(nfreq)"
            
            self.getRMinForCall(call: inArray[i].callData, Rmin: &rmin, FRmin: &frmin, tRmin: &trmin)
            exportString += "\t\(frmin)\t\(rmin)\t\(trmin)"
            
            l = Int(ceil(10.0*inArray[i].callData["Size"]!))
            while nil==inArray[i].callData["Freq\(l)"] {
                l -= 1
            }
            
            var lastOneArray: [Float] = Array(repeating:0.0, count:11)
            var lastRArray: [Float] = Array(repeating:0.0, count:10)
            var k = 0
            
            lastOneArray[10] = inArray[i].callData["EFreq"]!
            lastRArray[9] = (inArray[i].callData["Freq\(l)"]!-inArray[i].callData["EFreq"]!)/0.1
            
            k = 0
            //for j=l-10;j<l;j++ {
            for j in l-10..<l {
                if j < 1 { continue }
                lastOneArray[k] = inArray[i].callData["Freq\(j)"]!
                k += 1
            }
            
            k = 0;
            //for j=l-10;j<l-1;j++ {
            for j in l-10..<(l-1) {
                if j < 1 { continue }
                lastRArray[k] = (inArray[i].callData["Freq\(j)"]!-inArray[i].callData["Freq\(j+1)"]!)/0.1
                k += 1
            }
            
            exportString += "\t\(self.median(arr: &lastRArray,count: 10))" // 10 udn 11 vertauscht, aber geht eigentlich nicht wegen definierter größe der arrays ?! NACHPRÜFEN!
            exportString += "\t\(self.median(arr: &lastOneArray,count: 11))"
            
            //for (j=10;j<60;j++) {
            for j in 10...60 {
                exportString += "\t\(klassen_avg[j])"
            }
            //for (j=60;j<150;j++) {
            for j in stride(from: 61, to: 150, by: 2) {
                exportString += "\t\(klassen_avg[j]+klassen_avg[j+1])"
            }
            
        }
        
        var error: NSError?
        do {
            try exportString.write(toFile: toFile, atomically:true, encoding:String.Encoding.macOSRoman)
        } catch let error1 as NSError {
            error = error1
            NSApp.presentError(error!)
            return false
        }
        return true
    }
    
}
