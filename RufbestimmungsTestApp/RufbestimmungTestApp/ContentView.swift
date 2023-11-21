//
//  ContentView.swift
//  RufbestimmungTestApp
//
//  Created by Volker Runkel on 01.11.23.
//

import SwiftUI

struct ContentView: View {
    
    @State private var folders: Array<URLItem> = Array()
    @State private var selection: URLItem?
    @State private var callSelection: ResultItem?
    
    @State var speciesClassificationResults: Array<ResultItem>?
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                OutlineGroup(folders, id: \.self, children: \.sortedRecordings) { urlitem in
                    Text(urlitem.url.lastPathComponent)
                }
            }
            .overlay {
                if folders.isEmpty {
                    ContentUnavailableView {
                        Button() {
                            chooseFolder()
                        } label: {
                            Label("Choose folder", systemImage: "folder.badge.plus")
                        }
                        .buttonStyle(.borderless)
                    } description: {
                        Text("After choosing a folder the contents will appear here")
                    }
                }
            }
            .navigationTitle("Recordings")
            .navigationSplitViewColumnWidth(min: 250, ideal: 275, max: 350)
            .toolbar {
                ToolbarItem {
                    Button() {
                        chooseFolder()
                    } label: {
                        Label("Choose folder", systemImage: "folder.badge.plus")
                    }
                }
            }
        } content: {
            if let selection = selection {
                if !selection.isFolder {
                    NavigationStack {
                        SingleRecordingView(item: selection, callSelection: $callSelection, speciesClassificationResults: $speciesClassificationResults)
                            .id(selection.id)
                    }
                } else {
                    NavigationStack {
                        FolderAnalysis(item: selection)
                            .id(selection.id)
                    }
                }
            }
        } detail: {
            NavigationStack {
                if callSelection != nil, let indexOfCall = speciesClassificationResults!.firstIndex(where: { $0 == callSelection}), let batIdent2Data = selection?.batIdent2Measurements() {
                    CallDetailSheet(callParameters: batIdent2Data[indexOfCall], callMeasurements: selection!.callsForDisplay()![indexOfCall])
                        .frame(idealWidth: 500, idealHeight: 400)
                        .id(callSelection)
                } else {
                    ContentUnavailableView {
                    } description: {
                        Text("No call data available")
                    }
                }
            }
        }
    }
    
    private func chooseFolder() {
        folders.removeAll(keepingCapacity: true)
        let op = NSOpenPanel()
        op.canChooseFiles = false
        op.canChooseDirectories = true
        if op.runModal() == .OK, let url = op.url {
            //enumerateFolderTree(url: url)
            addFolders(url: url)
            /*do {
                enumerateFolderTree(url: url)
                let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                for anUrl in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent}) {
                    if anUrl.pathExtension == "raw" || anUrl.pathExtension == "wav" {
                        if let measurements = try? anUrl.deletingPathExtension().appendingPathExtension("csv").checkResourceIsReachable() {
                            var newURLItem = URLItem(url: anUrl, isFolder: false, urlForID: anUrl.deletingPathExtension().appendingPathExtension("csv"))
                            if let measurementContents = try? String(contentsOf: newURLItem.urlForID) {
                                newURLItem.numberOfCalls = measurementContents.components(separatedBy: CharacterSet.newlines).count - 1
                            }
                            folders.append(newURLItem)
                        }
                        
                    }
                }
            }
            catch {
                NSApp.presentError(error)
            }*/
        }
    }
    
    private func addFolders(url: URL) {
        let fm = FileManager.default
        do {
            let urls = try fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for anUrl in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent}) {
                if anUrl.pathExtension == "raw" || anUrl.pathExtension == "wav" {
                    if let _ = try? anUrl.deletingPathExtension().appendingPathExtension("csv").checkResourceIsReachable() {
                        let newURLItem = URLItem(url: anUrl, isFolder: false, urlForID: anUrl.deletingPathExtension().appendingPathExtension("csv"))
                        folders.append(newURLItem)
                    }
                    
                }
                else if anUrl.hasDirectoryPath {
                    let newURLItem = URLItem(url: anUrl, isFolder: true)
                    folders.append(newURLItem)
                    recursiveFolderCrawl(folderItem: newURLItem)
                }
            }
        }
        catch {
            print(error)
        }
        
    }
    
    private func recursiveFolderCrawl(folderItem: URLItem) {
        let fm = FileManager.default
        do {
            let urls = try fm.contentsOfDirectory(at: folderItem.url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for anUrl in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent}) {
                if anUrl.pathExtension == "raw" || anUrl.pathExtension == "wav" {
                    if let _ = try? anUrl.deletingPathExtension().appendingPathExtension("csv").checkResourceIsReachable() {
                        let newURLItem = URLItem(url: anUrl, isFolder: false, urlForID: anUrl.deletingPathExtension().appendingPathExtension("csv"))
                        if folderItem.recordings == nil {
                            folderItem.recordings = Array()
                        }
                        folderItem.recordings!.append(newURLItem)
                    }
                    
                }
                else if anUrl.hasDirectoryPath {
                    if folderItem.recordings == nil {
                        folderItem.recordings = Array()
                    }
                    let newURLItem = URLItem(url: anUrl, isFolder: true)
                    folderItem.recordings!.append(newURLItem)
                    recursiveFolderCrawl(folderItem: newURLItem)
                }
            }
        }
        catch {
            print(error)
        }
    }
    
    private func enumerateFolderTree(url: URL) {
        if let folderEnum = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) {
            var lastFolder: URLItem?
            while let suburl = folderEnum.nextObject() {
                if let suburl = suburl as? URL {
                    if !suburl.hasDirectoryPath {
                        if suburl.pathExtension == "raw" || suburl.pathExtension == "wav" {
                            if let measurements = try? suburl.deletingPathExtension().appendingPathExtension("csv").checkResourceIsReachable() {
                                var newURLItem = URLItem(url: suburl, isFolder: false, urlForID: suburl.deletingPathExtension().appendingPathExtension("csv"))
                                if let measurementContents = try? String(contentsOf: newURLItem.urlForID!) {
                                    newURLItem.numberOfCalls = measurementContents.components(separatedBy: CharacterSet.newlines).count - 1
                                }
                                if lastFolder != nil {
                                    if lastFolder!.recordings == nil {
                                        lastFolder!.recordings = Array()
                                    }
                                    lastFolder!.recordings!.append(newURLItem)
                                }
                                else {
                                    folders.append(newURLItem)
                                }
                            }
                            
                        }
                    } else {
                        if lastFolder == nil {
                            lastFolder = URLItem(url: suburl, isFolder: true)
                        } else {
                            folders.append(lastFolder!)
                            lastFolder = URLItem(url: suburl, isFolder: true)
                        }
                    }
                }
            }
            if lastFolder != nil {
                folders.append(lastFolder!)
            }
        }
    }
    
}

#Preview {
    ContentView()
}
