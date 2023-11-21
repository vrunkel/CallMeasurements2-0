//
//  FolderAnalysis.swift
//  RufbestimmungTestApp
//
//  Created by Volker Runkel on 07.11.23.
//

import SwiftUI
import TabularData
import UniformTypeIdentifiers

struct FolderAnalysis: View {
    
    @AppStorage("probability_threshold", store: .standard) var probThreshold: Double = 0.4
    @AppStorage("count_threshold", store: .standard) var countThreshold: Double = 2
    
    @State var item: URLItem
    
    @State var itemIdentificationResultsGenus: Array<(URLItem, Array<ResultItem>)>?
    @State var itemIdentificationResultsSpecies: Array<(URLItem, Array<ResultItem>)>?
    @State var itemIdentificationResultsSpeciesOnly: Array<(URLItem, Array<ResultItem>)>?
    
    var body: some View {
        
        HStack {
            Slider(value: $probThreshold) {
                Text("Probability threshold (\(probThreshold, specifier: "%.2f"))")
            } minimumValueLabel: {
                Text("0")
            } maximumValueLabel: {
                Text("1")
            }
            
            Slider(value: $countThreshold, in: Double(0)...10.0, step: 1) {
                Text("Count threshold (\(countThreshold, specifier: "%.0f"))")
            } minimumValueLabel: {
                Text("0")
            } maximumValueLabel: {
                Text("10")
            }
        }
        .padding()
        
        Text("Identify calls for recordings in \(item.url.lastPathComponent)")
        HStack {
            Button("Start identification") {
                identifyCalls()
            }
            Button("Append to CSV") {
                exportToCSV()
            }
            .disabled(itemIdentificationResultsGenus?.isEmpty ?? true)
        }

        HStack {
            VStack {
                Text("Overall genus results")
                    .font(.headline)
                List {
                    if let results = itemIdentificationResultsGenus {
                        ForEach(results, id: \.1) { item in
                            
                                Text("\(item.0.url.lastPathComponent)")
                            HStack {
                                ForEach(item.1, id: \.self) { value in
                                    HStack {
                                        //Text("\(value.count)")
                                        Text(value.result)
                                            .fontWeight(.semibold)
                                        Text("\(value.probability, specifier: "%.2f")")
                                            .foregroundStyle(value.textColor)
                                    }
                                }
                            }
                        }
                        .font(.caption)
                    }
                }
            }
            VStack {
                Text("Overall species results")
                    .font(.headline)
                List {
                    if let results = itemIdentificationResultsSpecies {
                        ForEach(results, id: \.1) { item in
                            
                                Text("\(item.0.url.lastPathComponent)")
                            HStack {
                                ForEach(item.1, id: \.self) { value in
                                    HStack {
                                        //Text("\(value.count)")
                                        Text(value.result)
                                            .fontWeight(.semibold)
                                        Text("\(value.probability, specifier: "%.2f")")
                                            .foregroundStyle(value.textColor)
                                    }
                                }
                            }
                        }
                        .font(.caption)
                    }
                }
            }
            VStack {
                Text("Overall species-only results")
                    .font(.headline)
                List {
                    if let results = itemIdentificationResultsSpeciesOnly {
                        ForEach(results, id: \.1) { item in
                            
                                Text("\(item.0.url.lastPathComponent)")
                            HStack {
                                ForEach(item.1, id: \.self) { value in
                                    HStack {
                                        //Text("\(value.count)")
                                        Text(value.result)
                                            .fontWeight(.semibold)
                                        Text("\(value.probability, specifier: "%.2f")")
                                            .foregroundStyle(value.textColor)
                                    }
                                }
                            }
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }
    
    private func identifyCalls() {
        guard let recordings = item.sortedRecordings else {
            return
        }
        
        itemIdentificationResultsGenus = Array()
        itemIdentificationResultsSpecies = Array()
        itemIdentificationResultsSpeciesOnly = Array()
        
        for aRecording in recordings {
            guard let batIdent2Data = aRecording.batIdent2Measurements() else {
                continue
            }
            let batCallClassifier = BatCallClassifier()
            batCallClassifier.batIdent2Data = batIdent2Data
            
            Task.init() {
                let result = await batCallClassifier.startClassifier()
                if result {
                    /*genusClassificationResults = batCallClassifier.genusClassificationResults
                    genusSummaryClassificationResults = batCallClassifier.genusSummaryClassificationResults
                    speciesClassificationResults = batCallClassifier.speciesClassificationResults
                    speciesSummaryClassificationResults = batCallClassifier.speciesSummaryClassificationResults
                    speciesOnlyClassificationResults = batCallClassifier.speciesOnlyClassificationResults
                    speciesOnlySummaryClassificationResults = batCallClassifier.speciesOnlySummaryClassificationResults*/
                    self.itemIdentificationResultsGenus?.append((aRecording, batCallClassifier.genusSummaryClassificationResults!))
                    self.itemIdentificationResultsSpecies?.append((aRecording, batCallClassifier.speciesSummaryClassificationResults!))
                    self.itemIdentificationResultsSpeciesOnly?.append((aRecording, batCallClassifier.speciesOnlySummaryClassificationResults!))
                }
            }
        }
    }
    
    private func exportToCSV() {
        if itemIdentificationResultsGenus == nil { return }
        if itemIdentificationResultsGenus!.count == itemIdentificationResultsSpecies!.count && itemIdentificationResultsGenus!.count == itemIdentificationResultsSpeciesOnly!.count {
            
            var nameColumn : (String, Array<String>) = ("file", Array<String>())
            var genusResultColumn : (String, Array<String>) = ("genus", Array<String>())
            var genusProbColumn : (String, Array<Double>) = ("genusProb", Array<Double>())
            var speciesResultColumn : (String, Array<String>) = ("species", Array<String>())
            var speciesProbColumn : (String, Array<Double>) = ("speciesProb", Array<Double>())
            var speciesOnlyResultColumn : (String, Array<String>) = ("speciesOnly", Array<String>())
            var speciesOnlyProbColumn: (String, Array<Double>) = ("speciesOnlyProb", Array<Double>())
            
            var index = 0
            for anItem in itemIdentificationResultsGenus! {
                nameColumn.1.append(anItem.0.url.lastPathComponent)
                genusResultColumn.1.append(anItem.1.first!.result)
                genusProbColumn.1.append(anItem.1.first!.probability)
                
                speciesResultColumn.1.append(itemIdentificationResultsSpecies![index].1.first!.result)
                speciesProbColumn.1.append(itemIdentificationResultsSpecies![index].1.first!.probability)
                
                speciesOnlyResultColumn.1.append(itemIdentificationResultsSpeciesOnly![index].1.first!.result)
                speciesOnlyProbColumn.1.append(itemIdentificationResultsSpeciesOnly![index].1.first!.probability)
                
                index += 1
            }
            
            let csvDataFrame : DataFrame = [nameColumn.0 : nameColumn.1, genusResultColumn.0 : genusResultColumn.1, genusProbColumn.0 : genusProbColumn.1, speciesResultColumn.0 : speciesResultColumn.1, speciesProbColumn.0 : speciesProbColumn.1, speciesOnlyResultColumn.0 : speciesOnlyResultColumn.1, speciesOnlyProbColumn.0 : speciesOnlyProbColumn.1]
            let sp = NSSavePanel()
            sp.allowedContentTypes = [UTType(filenameExtension: "csv", conformingTo: .delimitedText)!]
            let result = sp.runModal()
            if result == .OK, let url = sp.url {
                try? csvDataFrame.writeCSV(to: url)
            }
        }
    }
    
}

#Preview {
    FolderAnalysis(item: URLItem(url: URL(filePath: "/")))
}
