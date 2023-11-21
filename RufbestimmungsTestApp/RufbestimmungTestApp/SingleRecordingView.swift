//
//  SingleRecordingView.swift
//  RufbestimmungTestApp
//
//  Created by Volker Runkel on 01.11.23.
//

import SwiftUI

struct SingleRecordingView: View {
    
    @AppStorage("probability_threshold", store: .standard) var probThreshold: Double = 0.4
    @AppStorage("count_threshold", store: .standard) var countThreshold: Double = 2
    
    @State var item: URLItem
    @State var genusClassificationResults: Array<ResultItem>?
    @State var genusSummaryClassificationResults: Array<ResultItem>?
    
    @Binding var callSelection: ResultItem?
    @State var selectionNumber: Int = -1
    @State private var showCallDetails = false
    
    @Binding var speciesClassificationResults: Array<ResultItem>?
    @State var speciesSummaryClassificationResults: Array<ResultItem>?
    
    @State var speciesOnlyClassificationResults: Array<ResultItem>?
    @State var speciesOnlySummaryClassificationResults: Array<ResultItem>?
    
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
            Button() {
                //genusClassification()
                classifyCalls()
            } label: {
                Label("", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderless)
            Button() {
                NSWorkspace.shared.open(item.url)
            } label: {
                Label("", systemImage: "eye")
            }
            .buttonStyle(.borderless)
        }
        .padding()
        ScrollView {
            CallPreviewView(callData: item.callsForDisplay(), selectedCall: $selectionNumber)
                .frame(idealHeight: 250)
        }
        .frame(height: 250)
        HStack {
            VStack {
                Text("Genus")
                    .font(.headline)
                List() {
                    if let results = genusClassificationResults {
                        ForEach(Array(results.enumerated()), id: \.1) { (index, value) in
                            HStack {
                                Text("\(index+1)")
                                Text(value.result)
                                Text("\(value.probability)")
                                    .foregroundStyle(value.textColor)
                            }
                        }
                    }
                }
                Text("Overall")
                    .font(.headline)
                List {
                    if let results = genusSummaryClassificationResults {
                        ForEach(Array(results.enumerated()), id: \.1) { (index, value) in
                            HStack {
                                Text("\(value.count)")
                                Text(value.result)
                                Text("\(value.probability)")
                                    .foregroundStyle(value.textColor)
                            }
                        }
                    }
                }
                .frame(height: 140)
            }
            VStack {
                Text("Genus specific species")
                    .font(.headline)
                List(selection: $callSelection) {
                    if let results = speciesClassificationResults {
                        //ForEach(results, id: \.self) { aResult in
                        ForEach(Array(results.enumerated()), id: \.1) { (index, value) in
                            HStack {
                                Text("\(index+1)")
                                Text(value.result)
                                Text("\(value.probability)")
                                    .foregroundStyle(value.textColor)
                                Spacer()
                                /*Button() {
                                    showCallDetails.toggle()
                                } label: {
                                    Label("", systemImage: "eye")
                                }
                                .buttonStyle(.borderless)
                                 */
                            }
                        }
                    }
                }
                .onChange(of: callSelection) {
                    if let indexOfCall = speciesClassificationResults!.firstIndex(where: { $0 == callSelection}) {
                        selectionNumber = indexOfCall
                    }
                }
                Text("Overall")
                    .font(.headline)
                List {
                    if let results = speciesSummaryClassificationResults {
                        ForEach(Array(results.enumerated()), id: \.1) { (index, value) in
                            HStack {
                                Text("\(value.count)")
                                Text(value.result)
                                Text("\(value.probability)")
                                    .foregroundStyle(value.textColor)
                            }
                        }
                    }
                }
                .frame(height: 140)
            }
            VStack {
                Text("Species only")
                    .font(.headline)
                List {
                    if let results = speciesOnlyClassificationResults {
                        ForEach(Array(results.enumerated()), id: \.1) { (index, value) in
                            HStack {
                                Text("\(index+1)")
                                Text(value.result)
                                Text("\(value.probability)")
                                    .foregroundStyle(value.textColor)
                            }
                        }
                    }
                }
                Text("Overall")
                    .font(.headline)
                List {
                    if let results = speciesOnlySummaryClassificationResults {
                        ForEach(Array(results.enumerated()), id: \.1) { (index, value) in
                            HStack {
                                Text("\(value.count)")
                                Text(value.result)
                                Text("\(value.probability)")
                                    .foregroundStyle(value.textColor)
                            }
                        }
                    }
                }
                .frame(height: 140)
            }
        }
        .onAppear() {
            //genusClassification()
            classifyCalls()
        }
        .sheet(isPresented: $showCallDetails) {
            NavigationStack {
                if callSelection != nil, let indexOfCall = speciesClassificationResults!.firstIndex(where: { $0 == callSelection}), let batIdent2Data = item.batIdent2Measurements() {
                    CallDetailSheet(callParameters: batIdent2Data[indexOfCall], callMeasurements: item.callsForDisplay()![indexOfCall])
                        .frame(idealWidth: 500, idealHeight: 400)
                } else {
                    ContentUnavailableView {
                    } description: {
                        Text("No call data available")
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    func classifyCalls() {
        guard let batIdent2Data = item.batIdent2Measurements() else {
            return
        }
        
        let batCallClassifier = BatCallClassifier()
        batCallClassifier.batIdent2Data = batIdent2Data
        
        Task.init() {
            let result = await batCallClassifier.startClassifier()
            if result {
                genusClassificationResults = batCallClassifier.genusClassificationResults
                genusSummaryClassificationResults = batCallClassifier.genusSummaryClassificationResults
                speciesClassificationResults = batCallClassifier.speciesClassificationResults
                speciesSummaryClassificationResults = batCallClassifier.speciesSummaryClassificationResults
                speciesOnlyClassificationResults = batCallClassifier.speciesOnlyClassificationResults
                speciesOnlySummaryClassificationResults = batCallClassifier.speciesOnlySummaryClassificationResults
            }
        }
        
    }
}

struct CallPreviewView: NSViewRepresentable {
    
    @State var callData: Array<CallMeasurements>?
    @Binding var selectedCall: Int
    
    func makeNSView(context: Context) -> CallPreview {
        let callPreview = CallPreview()
        callPreview.setupView()
        if callData != nil {
            callPreview.updateCalls(callData!)
        }
        return callPreview
    }
    
    func updateNSView(_ nsView: CallPreview, context: Context) {
        nsView.selectedCall = selectedCall
    }
    
}
