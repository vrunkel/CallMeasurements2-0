//
//  Model.swift
//  RufbestimmungTestApp
//
//  Created by Volker Runkel on 01.11.23.
//

import Foundation
import SwiftUI

struct ResultItem: Hashable, Identifiable {
    var id: UUID = UUID()
    var result: String
    var probability: Double
    var count: Int = 1
    
    var textColor: Color {
        if probability <= 0.5 {
            return Color(nsColor: NSColor.lightGray)
        } else if probability < 0.7 {
          return .gray
        } else if probability < 0.9 {
          return .black
       } else {
          return .teal
       }
    }
}

enum FileResultSummarization {
    case count
    case probability
}

struct FileResults {
    
    var itemResults: Array<FileResultItem> = Array()
    var overallCount: Int = 0
    var probabilityThreshold: Double = 0.0
    var countThreshold: Int = 0
    
    mutating func addProbability(value: Double, for result: String) {
        defer {
            overallCount += 1
        }
        for (index,anItem) in itemResults.enumerated() {
            if anItem.result == result {
                itemResults[index].addProbability(value: value)
                return
            }
        }
        var itemResult = FileResultItem(result: result)
        itemResult.addProbability(value: value)
        itemResults.append(itemResult)
    }
    
    func filteredByCount() -> Array<FileResultItem> {
        if overallCount < 4 || countThreshold == 0 {
            return itemResults
        }
        if itemResults.max(by: { $0.count < $1.count})?.count ?? 0 <= countThreshold {
            return itemResults
        }
        return itemResults.filter { $0.count > countThreshold}
    }
    
    func sorted(summaryBasedOn: FileResultSummarization = .count) -> Array<FileResultItem> {
        switch summaryBasedOn {
        case .count:
            return self.sortedByCount()
        case .probability:
            return self.sortedByProbability()
        }
    }
    
    func sortedByCount() -> Array<FileResultItem> {
        return filteredByCount().sorted(by: { a, b in
            return (a.count) > (b.count)
        })
    }
    
    func sortedByProbability() -> Array<FileResultItem> {
        return filteredByCount().sorted(by: { a, b in
            return (a.overallResult(threshold: probabilityThreshold)) > (b.overallResult(threshold: probabilityThreshold))
        })
    }
}

struct FileResultItem: Hashable, Identifiable {
    var id: Self { self }
    var result: String
    var probabilities: Array<Double> = Array()
    var count: Int = 0
    
    mutating func addProbability(value: Double) {
        count += 1
        probabilities.append(value)
    }
    
    func overallResult(threshold: Double = 0.0) -> Double {
        if count < 1 {
            return 0.0
        }
        if threshold == 0.0 {
            return (probabilities.reduce(0){$0 + $1}) / Double(count)
        }
        let filtered = probabilities.filter({$0 >= threshold})
        let avg = sqrt(((filtered.reduce(0){$0 + $1}) / Double(filtered.count) * log10(Double(filtered.count)+3.0)))
        if avg.isNaN { return 0 }
        return avg > 1 ? 1 : avg
        // for a final result we could provide avg and call counts. If average of second is nearly as high as first, decond result. also if call count of second is nearly as high as first -> second result
        // three results condition?
    }
    
    static func == (lhs: FileResultItem, rhs: FileResultItem) -> Bool {
        return lhs.result == rhs.result
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(result)
    }
}

class URLItem: Hashable, Identifiable {
    var id: URLItem { self }
    
    //var id: Self { self }
    var url: URL
    var isFolder: Bool = true
    var numberOfCalls: Int = 0
    var urlForID: URL?
    
    var recordings: [URLItem]? = nil
    var sortedRecordings: [URLItem]? {
        if recordings == nil {
            return nil
        }
        return recordings?.sorted(by: { a, b in
            a.url.lastPathComponent < b.url.lastPathComponent
        })
    }
    
    init(url: URL, isFolder: Bool = true, numberOfCalls: Int = 0, urlForID: URL? = nil, recordings: [URLItem]? = nil) {
        self.url = url
        self.isFolder = isFolder
        self.numberOfCalls = numberOfCalls
        self.urlForID = urlForID
        self.recordings = recordings
    }
    
    static func == (lhs: URLItem, rhs: URLItem) -> Bool {
        return lhs.url == rhs.url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    func measurementFileURL() -> URL? {
        if self.isFolder {
            return nil
        }
        return self.url.deletingPathExtension().appendingPathExtension("bcCalls")
    }
    
    func batIdentFileURL() -> URL? {
        if self.isFolder {
            return nil
        }
        return self.url.deletingPathExtension().appendingPathExtension("csv")
    }
    
    func batIdent2FileURL() -> URL? {
        if self.isFolder {
            return nil
        }
        return self.url.deletingPathExtension().appendingPathExtension("batIdent2")
    }
    
    func batIdentMeasurements() -> Array<Dictionary<String, Float>>? {
        var measuresDict : Array<Dictionary<String, Float>>?
        
        guard let fileURL = self.batIdentFileURL(), FileManager.default.fileExists(atPath: fileURL.path), var csvString = try? String.init(contentsOf: fileURL) else { return nil }
        
        csvString = csvString.replacingOccurrences(of: ",", with: ".")
        let callLines = csvString.components(separatedBy: CharacterSet.newlines)
        var headers: Array<String>? {
            didSet {
                for (index, aHeader) in headers!.enumerated() {
                    if aHeader.isEmpty {
                        headers![index] = "\(index)"
                    }
                }
            }
        }
        measuresDict = Array()
        for (index, aLine) in callLines.enumerated() {
            if aLine.isEmpty {
                continue
            }
            let callData = aLine.components(separatedBy: "\t")
            if index == 0 {
                headers = callData
                continue
            }
            measuresDict?.append(Dictionary(uniqueKeysWithValues: zip(headers!, callData.map { Float($0) ?? -.infinity })))
        }
        
        return measuresDict
    }
    
    func calculateBatIdent2Measurements()  -> Array<Dictionary<String, Float>>? {
        guard let fileURL = self.measurementFileURL(), FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        
        let plistData = NSArray(contentsOf: fileURL)
        if let origCallData = plistData {
            
            var dataArray: Array<CallMeasurements> = Array()
            for call in origCallData as! [NSDictionary] {
                
                var tempDict: Dictionary<String,Float> = Dictionary()
                tempDict["Startsample"] = call["Startsample"] as? Float
                tempDict["Start"] = call["Start"] as? Float // besser? call["Startsample"] as! Float / Float(self.mySoundContainer.sampleRate/1000)
                tempDict["SFreq"] = call["SFreq"] as? Float
                tempDict["EFreq"] = call["EFreq"] as? Float
                tempDict["Size"] = call["Size"] as? Float
                tempDict["Sizesample"] = call["Sizesample"] as? Float
                
                var index = 1
                while (call["Time\(index)"] != nil) {
                    let time = call["Time\(index)"] as! Float
                    let freq = call["Freq\(index)"] as! Float
                    tempDict["Time\(index)"] = time
                    tempDict["Freq\(index)"] = freq
                    index += 1
                }
                
                var callProb: Float = 0.0
                var callSpecies = ""
                if let prob = call["DiscrProb"] as? Float {
                    callProb = prob
                }
                if let species = call["DiscrSpecies"] as? String {
                    callSpecies = species
                }
                var thisCallMeasures = CallMeasurements(callData: tempDict, callNumber:call["Call"] as! Int, species:callSpecies, speciesProb:callProb, meanFrequency: 0.0)
                thisCallMeasures.calculateDerivedMeasurements()
                dataArray.append(thisCallMeasures)
                
            }

            // for now we generate the csv instead of reading it
            let csvExporter = CallCSVExporter()
            csvExporter.generateCallMeasurements(inArray: &dataArray, newMeasurementsIncluded: true)
            
            var returnArray = Array<Dictionary<String, Float>>()
            for aCall in dataArray {
                var callDict = aCall.identData!
                let size = aCall.callData["Size"]!
                let SFreq = aCall.callData["SFreq"]!
                let EFreq = aCall.callData["EFreq"]!
                let Start = aCall.callData["Start"]!
                callDict.updateValue(size, forKey: "Dur")
                callDict.updateValue(SFreq, forKey: "Sfreq")
                callDict.updateValue(EFreq, forKey: "Efreq")
                callDict.updateValue(Start, forKey: "Start")
                returnArray.append(callDict)
            }
            return returnArray
        }
        return nil
    }
    
    func batIdent2Measurements() -> Array<Dictionary<String, Float>>? {
        var measuresDict : Array<Dictionary<String, Float>>?
        
        guard let fileURL = self.batIdent2FileURL(), FileManager.default.fileExists(atPath: fileURL.path), var csvString = try? String.init(contentsOf: fileURL) else { return calculateBatIdent2Measurements() }
        
        csvString = csvString.replacingOccurrences(of: ",", with: ".")
        let callLines = csvString.components(separatedBy: CharacterSet.newlines)
        var headers: Array<String>? {
            didSet {
                for (index, aHeader) in headers!.enumerated() {
                    if aHeader.isEmpty {
                        headers![index] = "\(index)"
                    }
                }
            }
        }
        measuresDict = Array()
        for (index, aLine) in callLines.enumerated() {
            if aLine.isEmpty {
                continue
            }
            let callData = aLine.components(separatedBy: "\t")
            if index == 0 {
                headers = callData
                continue
            }
            measuresDict?.append(Dictionary(uniqueKeysWithValues: zip(headers!, callData.map { Float($0) ?? -.infinity })))
        }
        
        return measuresDict
    }
    
    func callsForDisplay() -> Array<CallMeasurements>? {
        guard let measurementURL = self.measurementFileURL() else {
            return nil
        }
        if FileManager.default.fileExists(atPath: measurementURL.path) {
            let plistData = NSArray(contentsOf: measurementURL)
            if let origCallData = plistData {
                
                var dataArray: Array<CallMeasurements> = Array()
                for call in origCallData as! [NSDictionary] {
                    
                    var tempDict: Dictionary<String,Float> = Dictionary()
                    tempDict["Startsample"] = call["Startsample"] as? Float
                    tempDict["Start"] = call["Start"] as? Float // besser? call["Startsample"] as! Float / Float(self.mySoundContainer.sampleRate/1000)
                    tempDict["SFreq"] = call["SFreq"] as? Float
                    tempDict["EFreq"] = call["EFreq"] as? Float
                    tempDict["Size"] = call["Size"] as? Float
                    tempDict["Sizesample"] = call["Sizesample"] as? Float
                    
                    var index = 1
                    while (call["Time\(index)"] != nil) {
                        let time = call["Time\(index)"] as! Float
                        let freq = call["Freq\(index)"] as! Float
                        tempDict["Time\(index)"] = time
                        tempDict["Freq\(index)"] = freq
                        index += 1
                    }
                    
                    var callProb: Float = 0.0
                    var callSpecies = ""
                    if let prob = call["DiscrProb"] as? Float {
                        callProb = prob
                    }
                    if let species = call["DiscrSpecies"] as? String {
                        callSpecies = species
                    }
                    let thisCallMeasures = CallMeasurements(callData: tempDict, callNumber:call["Call"] as! Int, species:callSpecies, speciesProb:callProb, meanFrequency: 0.0)
                    dataArray.append(thisCallMeasures)
                    
                }
                
                
                // for now we generate the csv instead of reading it
                let csvExporter = CallCSVExporter()
                csvExporter.generateCallMeasurements(inArray: &dataArray)
                
                return dataArray
            }
        }
        return nil
    }
    
}

