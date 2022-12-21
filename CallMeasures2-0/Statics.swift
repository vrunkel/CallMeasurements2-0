//
//  Statics.swift
//  bcRefCalls3
//
//  Created by Volker Runkel on 20.03.20.
//  Copyright © 2020 ecoObs GmbH. All rights reserved.
//

import Foundation
import Cocoa
import AudioToolbox

let callFinderGroup = DispatchGroup()

/**
 call finder options
 */

let kFilterWaveFiles = "FilterWaveFilesBeforeCallFinding"

let kCleanCallDataBefore = "CleanDataBeforeFindingCalls"

let kCallFinderGeneralThresholdUI = "CallFinderGeneralThresholdUI"
let kCallFinderGeneralzfthreshold = "CallFinderGeneralThreshold"
let kCallFinderGeneralQuality = "CallFinderGeneralQuality"
let kCallFinderMinCallInt = "CallFinderMinimumCallIntervall"
let kCallFinderUseSession = "CallFinderUseSessionSettings"

let validAudioFiletypes = ["wav", "wave", "raw"]

enum AudioError : Error {
    case TooManyChannels
    case FileFormat
    case SecurityScopeExhausted
    case EmptyFile
    case OtherAudioError
}

enum FileTypes : String {
    case batcorder_raw
    case windows_wave
    case batsound_wave
    case unknown
}

// MARK: sound properties
enum sampleType {
    case Sample8bit
    case Sample16bitLE
    case Sample16bitBE
    case Sample24bitFloat
    case Sample32bitFloat
}


/**
 Holds necessesary information to interpret an audio file
 
 - samplerate
 - channelcount
 - sampleCount
 - soundStartSample
 - sampleFormat
 
 */
struct audioHeader {
    var samplerate: Int = 500000 {
        didSet {
            if samplerate < 192000 {
                self.timeExpansion = 10
            }
        }
    }
    var channelCount: Int = 1
    var sampleCount: Int = 0
    var soundStartSample: Int = 0
    var sampleFormat: sampleType = .Sample16bitLE
    var fileType: FileTypes = .unknown
    var audioFormatDescription: AudioStreamBasicDescription?
    var timeExpansion: Int = 1
}

struct CallMeasurements: CustomStringConvertible {

    init(callData: Dictionary<String,Float>, callNumber:Int, species:String, speciesProb:Float, meanFrequency: Float, identData: Dictionary<String, Float>?) {
        self.callData = callData
        self.calculateDerivedMeasurements()
        self.callNumber = callNumber
        self.species = species
        self.speciesProb = speciesProb
        self.meanFrequency = meanFrequency
        self.identData = identData
    }
    
    init(callData: Dictionary<String,Float>, callNumber:Int, species:String, speciesProb:Float, meanFrequency: Float) {
        self.init(callData: callData, callNumber:callNumber, species:species, speciesProb:speciesProb, meanFrequency: meanFrequency, identData: nil)
    }
    
    var callData: Dictionary<String,Float> {
        didSet {
            self.calculateDerivedMeasurements()
        }
    }
    
    var derivedMeasures: Dictionary<String,Float>?
    
    var callNumber: Int = 0
    var species: String = ""
    var speciesProb: Float = 0.0
    var meanFrequency: Float = 0.0
    var identData: Dictionary<String, Float>?
    var callClass: Int = 0 // Good, bad, other
    
    var callType: Int? = 0 // 1 qcf, 2 fm-qcf, 3 fm
    var kneeFreq: Float? = 0.0
    var kneePos: Int? = 0
    var kneeAlpha: Float? = 0.0
    var kneeR:  Float? = 0.0
    var myoFreq: Float? = 0.0
    var myoPos: Int? = 0
    var myoAlpha: Float? = 0.0
    var myoR: Float? = 0.0
    var medianFreq: Float? = 0.0
    var middleFreq: Float? = 0.0
    var dqcf : Float? = 0.0
    var dfm : Float? = 0.0
    var Rmitte : Float {
        var mutatableSelf = self
        if mutatableSelf.steigungen == nil {
            return 0
        }
        
        if mutatableSelf.steigungsMittel!.count % 2 == 0 {
            return (mutatableSelf.steigungsMittel![mutatableSelf.steigungsMittel!.count/2] + mutatableSelf.steigungsMittel![mutatableSelf.steigungsMittel!.count/2 + 1]) / 2.0
        }
        else {
            return mutatableSelf.steigungsMittel![mutatableSelf.steigungsMittel!.count/2]
        }
    }
    
    lazy var avgSteig: Float = {
        var mutatableSelf = self
        if mutatableSelf.steigungen == nil {
            return 0
        }
        let sum = mutatableSelf.steigungen!.reduce(0, +)
        let count = mutatableSelf.steigungen!.count
        return sum / Float(count)
    }()
    
    lazy var medSteig: Float = {
        var mutatableSelf = self
        if mutatableSelf.steigungen == nil {
            return 0
        }
        let sorted = mutatableSelf.steigungen!.sorted()
        if sorted.count % 2 != 0 {
            return sorted[sorted.count/2]
        }
        else {
            return (sorted[(sorted.count-1)/2] + sorted[(sorted.count+1)/2]) * 0.5
        }
    }()
    
    lazy var measurements: Array<Float>? = {
        var tempMeasurements: Array<Float> = Array()
        tempMeasurements.append(self.callData["SFreq"]!)
        var idx: Int = 1
        while self.callData["Freq\(idx)"] != nil {
            tempMeasurements.append(self.callData["Freq\(idx)"]!)
            idx += 1
        }
        tempMeasurements.append(self.callData["EFreq"]!)
        
        if tempMeasurements.count < 4 {
            return nil
        }
        return tempMeasurements
    }()
    
    lazy var steigungen: Array<Float>? = {
        guard let measurements = self.measurements else {
            return nil
        }
        var tempSteigungen: Array<Float> = Array()
        
        for index in 1..<measurements.count {
            tempSteigungen.append((measurements[index] - measurements[index-1])) // Steigung je ms
        }
        
        return tempSteigungen
    }()
    
    let stepSize = 4
    
    lazy var steigungsMittel: Array<Float>? = {
        guard let steigungen = self.steigungen else {
            return nil
        }
        var tempSteigungen: Array<Float> = Array()
        
        for index in stride(from: 0, to: steigungen.count, by: 1) {
            if index <= steigungen.count - stepSize {
                var sum : Float = 0
                for subIndex in index..<index+stepSize {
                    sum += steigungen[subIndex]
                }
                tempSteigungen.append(sum/Float(stepSize))
            }
        }
        return tempSteigungen
    }()
    
    var description: String {
        let callStart = callData["Start"]!
        let callDur = callData["Size"]!
        return "Call Number: \(callNumber) with start and dur: \(callStart) \(callDur) \n" //CallData count \(callData.count) and IdentCount \(identData!.count)\n"
    }
    
    var bcCallsRepresentation: NSMutableDictionary {
            var myDict = callData
            myDict.updateValue(Float(callNumber), forKey:"Call")
            myDict.updateValue(Float(0), forKey:"callClass")
            return NSMutableDictionary(dictionary: myDict)
    }
    
    mutating func calculateDerivedMeasurements() {
        
        var derivedMeasuresDict = Dictionary<String, Float>()
        
        guard let measurements = self.measurements else {
            return
        }
        let numberOfValues = 4
        var winkel_alpha: Array<Float> = Array()
        if measurements.count < numberOfValues*2 {
            return
        }
        
        for idx in 0..<self.steigungsMittel!.count-numberOfValues {
            let winkel = (self.steigungsMittel![idx+numberOfValues] - self.steigungsMittel![idx]) / (1 + (self.steigungsMittel![idx+numberOfValues] * self.steigungsMittel![idx]))
            winkel_alpha.append(atan(winkel) * 180 / Float.pi)
        }
        
        var max : Float = -100000
        var maxPos = winkel_alpha.count / 2
        for runIdx in 0..<winkel_alpha.count {
            if winkel_alpha[runIdx] > max {
                max = winkel_alpha[runIdx]
                maxPos = runIdx
            }
        }
        
        if max > 0 {
            self.kneeFreq = self.callData["Freq\(maxPos+numberOfValues)"]
            self.kneePos = maxPos+numberOfValues
            self.kneeAlpha = max
            self.kneeR = (self.steigungsMittel![maxPos] + self.steigungsMittel![maxPos+numberOfValues]) / 2.0
            
            derivedMeasuresDict.updateValue(self.kneeFreq!, forKey: "kneeFreq")
            derivedMeasuresDict.updateValue(Float(self.kneePos!), forKey: "kneePos")
            derivedMeasuresDict.updateValue(self.kneeAlpha!, forKey: "kneeAlpha")
            derivedMeasuresDict.updateValue(self.kneeR!, forKey: "kneeR")
        } else {
            derivedMeasuresDict.updateValue(Float(0), forKey: "kneeFreq")
            derivedMeasuresDict.updateValue(Float(0), forKey: "kneePos")
            derivedMeasuresDict.updateValue(Float(0), forKey: "kneeAlpha")
            derivedMeasuresDict.updateValue(Float(0), forKey: "kneeR")
        }
        
        var min : Float = 10000
        var minPos = 0
        
        for runIdx in maxPos..<winkel_alpha.count {
            if winkel_alpha[runIdx] < min {
                min = winkel_alpha[runIdx]
                minPos = runIdx
            }
        }
        
        if min < 0 {
            self.myoFreq = self.callData["Freq\(minPos+numberOfValues)"]
            self.myoPos = minPos+numberOfValues
            self.myoAlpha = min
            self.myoR = (self.steigungsMittel![minPos] + self.steigungsMittel![minPos+numberOfValues]) / 2.0
            
            derivedMeasuresDict.updateValue(self.myoFreq!, forKey: "myoFreq")
            derivedMeasuresDict.updateValue(Float(self.myoPos!), forKey: "myoPos")
            derivedMeasuresDict.updateValue(self.myoAlpha!, forKey: "myoAlpha")
            derivedMeasuresDict.updateValue(self.myoR!, forKey: "myoR")
        } else {
            derivedMeasuresDict.updateValue(Float(0), forKey: "myoFreq")
            derivedMeasuresDict.updateValue(Float(0), forKey: "myoPos")
            derivedMeasuresDict.updateValue(Float(0), forKey: "myoAlpha")
            derivedMeasuresDict.updateValue(Float(0), forKey: "myoR")
        }
        
        if measurements.count % 2 != 0 {
            self.middleFreq = measurements[measurements.count/2]
            self.medianFreq = measurements.sorted()[measurements.count/2]
            
            derivedMeasuresDict.updateValue(self.middleFreq!, forKey: "middleFreq")
            derivedMeasuresDict.updateValue(self.medianFreq!, forKey: "medianFreq")
        }
        else {
            self.middleFreq = (measurements[measurements.count/2-1] + measurements[measurements.count/2]) / 2.0
            self.medianFreq = (measurements.sorted()[measurements.count/2-1] + measurements.sorted()[measurements.count/2]) / 2.0
            
            derivedMeasuresDict.updateValue(self.middleFreq!, forKey: "middleFreq")
            derivedMeasuresDict.updateValue(self.medianFreq!, forKey: "medianFreq")
        }
        
        var qcfLength = 0
        var lastQCF = 0
        for aValue in self.steigungsMittel! {
            if abs(aValue) < 0.1 {
                qcfLength += 1
            }
            else {
                if qcfLength > lastQCF {
                    lastQCF = qcfLength
                    qcfLength = 0
                }
            }
        }
        if qcfLength > lastQCF {
            lastQCF = qcfLength
            qcfLength = 0
        }
        self.dqcf = Float(lastQCF+3) * 0.1
        derivedMeasuresDict.updateValue(self.dqcf!, forKey: "dqcf")
        
        var fmLength = 0
        var lastFM = 0
        for aValue in self.steigungsMittel! {
            if abs(aValue) > 0.1 {
                fmLength += 1
            }
            else {
                if fmLength > lastFM {
                    lastFM = fmLength
                    fmLength = 0
                }
            }
        }
        if fmLength > lastFM {
            lastFM = fmLength
            fmLength = 0
        }
        self.dfm = Float(lastFM+3) * 0.1
        derivedMeasuresDict.updateValue(self.dfm!, forKey: "dfm")
        
        derivedMeasuresDict.updateValue(self.Rmitte, forKey: "Rmitte")
        derivedMeasuresDict.updateValue(self.avgSteig, forKey: "avgSteig")
        derivedMeasuresDict.updateValue(self.medSteig, forKey: "medSteig")
        
        self.derivedMeasures = derivedMeasuresDict
    }
}

public struct PixelData {
//        var a:UInt8 = 255
        var r:UInt8 = 0
        var g:UInt8 = 0
        var b:UInt8 = 0
        var a:UInt8 = 255
}

public struct GrayPixel {
    var g:UInt8 = 0
}
