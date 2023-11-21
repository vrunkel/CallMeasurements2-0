//
//  BatCallClassifier.swift
//  RufbestimmungTestApp
//
//  Created by Volker Runkel on 07.11.23.
//

import Foundation
import CoreML
import SwiftUI

class BatCallClassifier {
    
    @AppStorage("probability_threshold", store: .standard) var probThreshold: Double = 0.4
    @AppStorage("count_threshold", store: .standard) var countThreshold: Double = 2
    
    var batIdent2Data: Array<Dictionary<String, Float>>?
    
    var genusClassificationResults: Array<ResultItem>?
    var genusSummaryClassificationResults: Array<ResultItem>?
    
    var speciesClassificationResults: Array<ResultItem>?
    var speciesSummaryClassificationResults: Array<ResultItem>?
    
    var speciesOnlyClassificationResults: Array<ResultItem>?
    var speciesOnlySummaryClassificationResults: Array<ResultItem>?
    
    var genusClassifier: TabluarGenusClassifier? = try? TabluarGenusClassifier(configuration: MLModelConfiguration())
    
    var myotisClassifier: TabluarMyotisClassifier? = try? TabluarMyotisClassifier(configuration: MLModelConfiguration())
    var nyctaloidClassifier: TabluarNyctaloidClassifier? = try? TabluarNyctaloidClassifier(configuration: MLModelConfiguration())
    var pipistrelloidClassifier: TabluarPipistrelloidClassifier? = try? TabluarPipistrelloidClassifier(configuration: MLModelConfiguration())
    
    var speciesOnlyClassifier: TabluarSpeciesClassifier? = try? TabluarSpeciesClassifier(configuration: MLModelConfiguration())
    
    func startClassifier() async -> Bool {
        let genusOkay = await genusClassification()
        let speciesOnlyOkay = await speciesOnlyClassification()
        if !genusOkay || !speciesOnlyOkay {
            return false
        }
        return true
    }
    
    private func genusClassification() async -> Bool {
        
        guard let batIdent2Data = batIdent2Data, let classifier = self.genusClassifier else {
            return false
        }
        genusClassificationResults = Array()
        var overallResultsIntern = FileResults()
        for call in batIdent2Data {
            if let output = try? classifier.prediction(Dur: Double(call["Dur"]!), Sfreq: Double(call["Sfreq"]!), Efreq: Double(call["Efreq"]!), NMod: Double(call["NMod"]!), FMod: Double(call["FMod"]!), FRmin: Double(call["FRmin"]!), Rmin: Double(call["Rmin"]!), tRmin: Double(call["tRmin"]!), Rlastms: Double(call["Rlastms"]!), Flastms: Double(call["Flastms"]!), Fknee: Double(call["Fknee"]!), Alphaknee: Double(call["Alphaknee"]!), Rknee: Double(call["Rknee"]!), ptknee: Double(call["ptknee"]!), Fmk: Double(call["Fmk"]!), Alphamk: Double(call["Alphamk"]!), Rmk: Double(call["Rmk"]!), ptmk: Double(call["ptmk"]!), Fmed: Double(call["Fmed"]!), Fmidt: Double(call["Fmidt"]!), Fmidf: Double(call["Fmidf"]!), tmidf: Double(call["tmidf"]!), ptmidf: Double(call["ptmidf"]!), PFmidt: Double(call["PFmidt"]!), Rmidt: Double(call["Rmidt"]!), Rmed: Double(call["Rmed"]!), Rges: Double(call["Rges"]!), Dfm: Double(call["Dfm"]!), Dqcf: Double(call["Dqcf"]!), Typ: Double(call["Typ"]!), X10: Double(call["X10"]!), X11: Double(call["X11"]!), X12: Double(call["X12"]!), X13: Double(call["X13"]!), X14: Double(call["X14"]!), X15: Double(call["X15"]!), X16: Double(call["X16"]!), X17: Double(call["X17"]!), X18: Double(call["X18"]!), X19: Double(call["X19"]!), X20: Double(call["X20"]!), X21: Double(call["X21"]!), X22: Double(call["X22"]!), X23: Double(call["X23"]!), X24: Double(call["X24"]!), X25: Double(call["X25"]!), X26: Double(call["X26"]!), X27: Double(call["X27"]!), X28: Double(call["X28"]!), X29: Double(call["X29"]!), X30: Double(call["X30"]!), X31: Double(call["X31"]!), X32: Double(call["X32"]!), X33: Double(call["X33"]!), X34: Double(call["X34"]!), X35: Double(call["X35"]!), X36: Double(call["X36"]!), X37: Double(call["X37"]!), X38: Double(call["X38"]!), X39: Double(call["X39"]!), X40: Double(call["X40"]!), X41: Double(call["X41"]!), X42: Double(call["X42"]!), X43: Double(call["X43"]!), X44: Double(call["X44"]!), X45: Double(call["X45"]!), X46: Double(call["X46"]!), X47: Double(call["X47"]!), X48: Double(call["X48"]!), X49: Double(call["X49"]!), X50: Double(call["X50"]!), X51: Double(call["X51"]!), X52: Double(call["X52"]!), X53: Double(call["X53"]!), X54: Double(call["X54"]!), X55: Double(call["X55"]!), X56: Double(call["X56"]!), X57: Double(call["X57"]!), X58: Double(call["X58"]!), X59: Double(call["X59"]!), X60: Double(call["X60"]!), X62: Double(call["X62"]!), X64: Double(call["X64"]!), X66: Double(call["X66"]!), X68: Double(call["X68"]!), X70: Double(call["X70"]!), X72: Double(call["X72"]!), X74: Double(call["X74"]!), X76: Double(call["X76"]!), X78: Double(call["X78"]!), X80: Double(call["X80"]!), X82: Double(call["X82"]!), X84: Double(call["X84"]!), X86: Double(call["X86"]!), X88: Double(call["X88"]!), X90: Double(call["X90"]!), X92: Double(call["X92"]!), X94: Double(call["X94"]!), X96: Double(call["X96"]!), X98: Double(call["X98"]!), X100: Double(call["X100"]!), X102: Double(call["X102"]!), X104: Double(call["X104"]!), X106: Double(call["X106"]!), X108: Double(call["X108"]!), X110: Double(call["X110"]!), X112: Double(call["X112"]!), X114: Double(call["X114"]!), X116: Double(call["X116"]!), X118: Double(call["X118"]!), X120: Double(call["X120"]!), X122: Double(call["X122"]!), X124: Double(call["X124"]!), X126: Double(call["X126"]!), X128: Double(call["X128"]!), X130: Double(call["X130"]!), X132: Double(call["X132"]!), X134: Double(call["X134"]!), X136: Double(call["X136"]!), X138: Double(call["X138"]!), X140: Double(call["X140"]!), X142: Double(call["X142"]!), X144: Double(call["X144"]!), X146: Double(call["X146"]!), X148: Double(call["X148"]!)) {
                //Swift.print(output.Gruppe + " \(output.GruppeProbability[output.Gruppe])")
                genusClassificationResults?.append(ResultItem(result: output.Gruppe, probability: output.GruppeProbability[output.Gruppe]!))
                overallResultsIntern.addProbability(value: output.GruppeProbability[output.Gruppe]!, for: output.Gruppe)
            }
        }
        
        genusSummaryClassificationResults = Array()
        overallResultsIntern.probabilityThreshold = probThreshold
        overallResultsIntern.countThreshold = Int(countThreshold)
        for aResultContainer in overallResultsIntern.sorted(summaryBasedOn: .probability) {
            genusSummaryClassificationResults?.append(ResultItem(result: aResultContainer.result, probability: aResultContainer.overallResult(), count:aResultContainer.count))
        }
        let speciesOkay = await speciesClassification()
        return (true == speciesOkay)
    }
    
    private func speciesClassification() async -> Bool  {
        guard let batIdent2Data = batIdent2Data, let myotisClassifier = self.myotisClassifier, let nyctaloidClassifier = self.nyctaloidClassifier, let pipistrelloidClassifier = self.pipistrelloidClassifier else {
            return false
        }
        
        speciesClassificationResults = Array()
        var overallResultsIntern = FileResults()
        for (index, call) in batIdent2Data.enumerated() {
            if genusClassificationResults![index].result == "Nyctaloid" {
                if let output = try? nyctaloidClassifier.prediction(Dur: Double(call["Dur"]!), Sfreq: Double(call["Sfreq"]!), Efreq: Double(call["Efreq"]!), NMod: Double(call["NMod"]!), FMod: Double(call["FMod"]!), FRmin: Double(call["FRmin"]!), Rmin: Double(call["Rmin"]!), tRmin: Double(call["tRmin"]!), Rlastms: Double(call["Rlastms"]!), Flastms: Double(call["Flastms"]!), Fknee: Double(call["Fknee"]!), Alphaknee: Double(call["Alphaknee"]!), Rknee: Double(call["Rknee"]!), ptknee: Double(call["ptknee"]!), Fmk: Double(call["Fmk"]!), Alphamk: Double(call["Alphamk"]!), Rmk: Double(call["Rmk"]!), ptmk: Double(call["ptmk"]!), Fmed: Double(call["Fmed"]!), Fmidt: Double(call["Fmidt"]!), Fmidf: Double(call["Fmidf"]!), tmidf: Double(call["tmidf"]!), ptmidf: Double(call["ptmidf"]!), PFmidt: Double(call["PFmidt"]!), Rmidt: Double(call["Rmidt"]!), Rmed: Double(call["Rmed"]!), Rges: Double(call["Rges"]!), Dfm: Double(call["Dfm"]!), Dqcf: Double(call["Dqcf"]!), Typ: Double(call["Typ"]!), X10: Double(call["X10"]!), X11: Double(call["X11"]!), X12: Double(call["X12"]!), X13: Double(call["X13"]!), X14: Double(call["X14"]!), X15: Double(call["X15"]!), X16: Double(call["X16"]!), X17: Double(call["X17"]!), X18: Double(call["X18"]!), X19: Double(call["X19"]!), X20: Double(call["X20"]!), X21: Double(call["X21"]!), X22: Double(call["X22"]!), X23: Double(call["X23"]!), X24: Double(call["X24"]!), X25: Double(call["X25"]!), X26: Double(call["X26"]!), X27: Double(call["X27"]!), X28: Double(call["X28"]!), X29: Double(call["X29"]!), X30: Double(call["X30"]!), X31: Double(call["X31"]!), X32: Double(call["X32"]!), X33: Double(call["X33"]!), X34: Double(call["X34"]!), X35: Double(call["X35"]!), X36: Double(call["X36"]!), X37: Double(call["X37"]!), X38: Double(call["X38"]!), X39: Double(call["X39"]!), X40: Double(call["X40"]!), X41: Double(call["X41"]!), X42: Double(call["X42"]!), X43: Double(call["X43"]!), X44: Double(call["X44"]!), X45: Double(call["X45"]!), X46: Double(call["X46"]!), X47: Double(call["X47"]!), X48: Double(call["X48"]!), X49: Double(call["X49"]!), X50: Double(call["X50"]!), X51: Double(call["X51"]!), X52: Double(call["X52"]!), X53: Double(call["X53"]!), X54: Double(call["X54"]!), X55: Double(call["X55"]!), X56: Double(call["X56"]!), X57: Double(call["X57"]!), X58: Double(call["X58"]!), X59: Double(call["X59"]!), X60: Double(call["X60"]!), X62: Double(call["X62"]!), X64: Double(call["X64"]!), X66: Double(call["X66"]!), X68: Double(call["X68"]!), X70: Double(call["X70"]!), X72: Double(call["X72"]!), X74: Double(call["X74"]!), X76: Double(call["X76"]!), X78: Double(call["X78"]!), X80: Double(call["X80"]!), X82: Double(call["X82"]!), X84: Double(call["X84"]!), X86: Double(call["X86"]!), X88: Double(call["X88"]!), X90: Double(call["X90"]!), X92: Double(call["X92"]!), X94: Double(call["X94"]!), X96: Double(call["X96"]!), X98: Double(call["X98"]!), X100: Double(call["X100"]!), X102: Double(call["X102"]!), X104: Double(call["X104"]!), X106: Double(call["X106"]!), X108: Double(call["X108"]!), X110: Double(call["X110"]!), X112: Double(call["X112"]!), X114: Double(call["X114"]!), X116: Double(call["X116"]!), X118: Double(call["X118"]!), X120: Double(call["X120"]!), X122: Double(call["X122"]!), X124: Double(call["X124"]!), X126: Double(call["X126"]!), X128: Double(call["X128"]!), X130: Double(call["X130"]!), X132: Double(call["X132"]!), X134: Double(call["X134"]!), X136: Double(call["X136"]!), X138: Double(call["X138"]!), X140: Double(call["X140"]!), X142: Double(call["X142"]!), X144: Double(call["X144"]!), X146: Double(call["X146"]!), X148: Double(call["X148"]!)) {
                    //Swift.print(output.Gruppe + " \(output.GruppeProbability[output.Gruppe])")
                    speciesClassificationResults?.append(ResultItem(result: output.Art, probability: output.ArtProbability[output.Art]!))
                    overallResultsIntern.addProbability(value: output.ArtProbability[output.Art]!, for: output.Art)
                    
                    //return output.Gruppe
                }
            } else if genusClassificationResults![index].result == "Pipistrelloid" {
                if let output = try? pipistrelloidClassifier.prediction(Dur: Double(call["Dur"]!), Sfreq: Double(call["Sfreq"]!), Efreq: Double(call["Efreq"]!), NMod: Double(call["NMod"]!), FMod: Double(call["FMod"]!), FRmin: Double(call["FRmin"]!), Rmin: Double(call["Rmin"]!), tRmin: Double(call["tRmin"]!), Rlastms: Double(call["Rlastms"]!), Flastms: Double(call["Flastms"]!), Fknee: Double(call["Fknee"]!), Alphaknee: Double(call["Alphaknee"]!), Rknee: Double(call["Rknee"]!), ptknee: Double(call["ptknee"]!), Fmk: Double(call["Fmk"]!), Alphamk: Double(call["Alphamk"]!), Rmk: Double(call["Rmk"]!), ptmk: Double(call["ptmk"]!), Fmed: Double(call["Fmed"]!), Fmidt: Double(call["Fmidt"]!), Fmidf: Double(call["Fmidf"]!), tmidf: Double(call["tmidf"]!), ptmidf: Double(call["ptmidf"]!), PFmidt: Double(call["PFmidt"]!), Rmidt: Double(call["Rmidt"]!), Rmed: Double(call["Rmed"]!), Rges: Double(call["Rges"]!), Dfm: Double(call["Dfm"]!), Dqcf: Double(call["Dqcf"]!), Typ: Double(call["Typ"]!), X10: Double(call["X10"]!), X11: Double(call["X11"]!), X12: Double(call["X12"]!), X13: Double(call["X13"]!), X14: Double(call["X14"]!), X15: Double(call["X15"]!), X16: Double(call["X16"]!), X17: Double(call["X17"]!), X18: Double(call["X18"]!), X19: Double(call["X19"]!), X20: Double(call["X20"]!), X21: Double(call["X21"]!), X22: Double(call["X22"]!), X23: Double(call["X23"]!), X24: Double(call["X24"]!), X25: Double(call["X25"]!), X26: Double(call["X26"]!), X27: Double(call["X27"]!), X28: Double(call["X28"]!), X29: Double(call["X29"]!), X30: Double(call["X30"]!), X31: Double(call["X31"]!), X32: Double(call["X32"]!), X33: Double(call["X33"]!), X34: Double(call["X34"]!), X35: Double(call["X35"]!), X36: Double(call["X36"]!), X37: Double(call["X37"]!), X38: Double(call["X38"]!), X39: Double(call["X39"]!), X40: Double(call["X40"]!), X41: Double(call["X41"]!), X42: Double(call["X42"]!), X43: Double(call["X43"]!), X44: Double(call["X44"]!), X45: Double(call["X45"]!), X46: Double(call["X46"]!), X47: Double(call["X47"]!), X48: Double(call["X48"]!), X49: Double(call["X49"]!), X50: Double(call["X50"]!), X51: Double(call["X51"]!), X52: Double(call["X52"]!), X53: Double(call["X53"]!), X54: Double(call["X54"]!), X55: Double(call["X55"]!), X56: Double(call["X56"]!), X57: Double(call["X57"]!), X58: Double(call["X58"]!), X59: Double(call["X59"]!), X60: Double(call["X60"]!), X62: Double(call["X62"]!), X64: Double(call["X64"]!), X66: Double(call["X66"]!), X68: Double(call["X68"]!), X70: Double(call["X70"]!), X72: Double(call["X72"]!), X74: Double(call["X74"]!), X76: Double(call["X76"]!), X78: Double(call["X78"]!), X80: Double(call["X80"]!), X82: Double(call["X82"]!), X84: Double(call["X84"]!), X86: Double(call["X86"]!), X88: Double(call["X88"]!), X90: Double(call["X90"]!), X92: Double(call["X92"]!), X94: Double(call["X94"]!), X96: Double(call["X96"]!), X98: Double(call["X98"]!), X100: Double(call["X100"]!), X102: Double(call["X102"]!), X104: Double(call["X104"]!), X106: Double(call["X106"]!), X108: Double(call["X108"]!), X110: Double(call["X110"]!), X112: Double(call["X112"]!), X114: Double(call["X114"]!), X116: Double(call["X116"]!), X118: Double(call["X118"]!), X120: Double(call["X120"]!), X122: Double(call["X122"]!), X124: Double(call["X124"]!), X126: Double(call["X126"]!), X128: Double(call["X128"]!), X130: Double(call["X130"]!), X132: Double(call["X132"]!), X134: Double(call["X134"]!), X136: Double(call["X136"]!), X138: Double(call["X138"]!), X140: Double(call["X140"]!), X142: Double(call["X142"]!), X144: Double(call["X144"]!), X146: Double(call["X146"]!), X148: Double(call["X148"]!)) {
                    //Swift.print(output.Gruppe + " \(output.GruppeProbability[output.Gruppe])")
                    speciesClassificationResults?.append(ResultItem(result: output.Art, probability: output.ArtProbability[output.Art]!))
                    overallResultsIntern.addProbability(value: output.ArtProbability[output.Art]!, for: output.Art)
                    //return output.Gruppe
                }
            }  else if genusClassificationResults![index].result == "Myotis" {
                if let output = try? myotisClassifier.prediction(Dur: Double(call["Dur"]!), Sfreq: Double(call["Sfreq"]!), Efreq: Double(call["Efreq"]!), NMod: Double(call["NMod"]!), FMod: Double(call["FMod"]!), FRmin: Double(call["FRmin"]!), Rmin: Double(call["Rmin"]!), tRmin: Double(call["tRmin"]!), Rlastms: Double(call["Rlastms"]!), Flastms: Double(call["Flastms"]!), Fknee: Double(call["Fknee"]!), Alphaknee: Double(call["Alphaknee"]!), Rknee: Double(call["Rknee"]!), ptknee: Double(call["ptknee"]!), Fmk: Double(call["Fmk"]!), Alphamk: Double(call["Alphamk"]!), Rmk: Double(call["Rmk"]!), ptmk: Double(call["ptmk"]!), Fmed: Double(call["Fmed"]!), Fmidt: Double(call["Fmidt"]!), Fmidf: Double(call["Fmidf"]!), tmidf: Double(call["tmidf"]!), ptmidf: Double(call["ptmidf"]!), PFmidt: Double(call["PFmidt"]!), Rmidt: Double(call["Rmidt"]!), Rmed: Double(call["Rmed"]!), Rges: Double(call["Rges"]!), Dfm: Double(call["Dfm"]!), Dqcf: Double(call["Dqcf"]!), Typ: Double(call["Typ"]!), X10: Double(call["X10"]!), X11: Double(call["X11"]!), X12: Double(call["X12"]!), X13: Double(call["X13"]!), X14: Double(call["X14"]!), X15: Double(call["X15"]!), X16: Double(call["X16"]!), X17: Double(call["X17"]!), X18: Double(call["X18"]!), X19: Double(call["X19"]!), X20: Double(call["X20"]!), X21: Double(call["X21"]!), X22: Double(call["X22"]!), X23: Double(call["X23"]!), X24: Double(call["X24"]!), X25: Double(call["X25"]!), X26: Double(call["X26"]!), X27: Double(call["X27"]!), X28: Double(call["X28"]!), X29: Double(call["X29"]!), X30: Double(call["X30"]!), X31: Double(call["X31"]!), X32: Double(call["X32"]!), X33: Double(call["X33"]!), X34: Double(call["X34"]!), X35: Double(call["X35"]!), X36: Double(call["X36"]!), X37: Double(call["X37"]!), X38: Double(call["X38"]!), X39: Double(call["X39"]!), X40: Double(call["X40"]!), X41: Double(call["X41"]!), X42: Double(call["X42"]!), X43: Double(call["X43"]!), X44: Double(call["X44"]!), X45: Double(call["X45"]!), X46: Double(call["X46"]!), X47: Double(call["X47"]!), X48: Double(call["X48"]!), X49: Double(call["X49"]!), X50: Double(call["X50"]!), X51: Double(call["X51"]!), X52: Double(call["X52"]!), X53: Double(call["X53"]!), X54: Double(call["X54"]!), X55: Double(call["X55"]!), X56: Double(call["X56"]!), X57: Double(call["X57"]!), X58: Double(call["X58"]!), X59: Double(call["X59"]!), X60: Double(call["X60"]!), X62: Double(call["X62"]!), X64: Double(call["X64"]!), X66: Double(call["X66"]!), X68: Double(call["X68"]!), X70: Double(call["X70"]!), X72: Double(call["X72"]!), X74: Double(call["X74"]!), X76: Double(call["X76"]!), X78: Double(call["X78"]!), X80: Double(call["X80"]!), X82: Double(call["X82"]!), X84: Double(call["X84"]!), X86: Double(call["X86"]!), X88: Double(call["X88"]!), X90: Double(call["X90"]!), X92: Double(call["X92"]!), X94: Double(call["X94"]!), X96: Double(call["X96"]!), X98: Double(call["X98"]!), X100: Double(call["X100"]!), X102: Double(call["X102"]!), X104: Double(call["X104"]!), X106: Double(call["X106"]!), X108: Double(call["X108"]!), X110: Double(call["X110"]!), X112: Double(call["X112"]!), X114: Double(call["X114"]!), X116: Double(call["X116"]!), X118: Double(call["X118"]!), X120: Double(call["X120"]!), X122: Double(call["X122"]!), X124: Double(call["X124"]!), X126: Double(call["X126"]!), X128: Double(call["X128"]!), X130: Double(call["X130"]!), X132: Double(call["X132"]!), X134: Double(call["X134"]!), X136: Double(call["X136"]!), X138: Double(call["X138"]!), X140: Double(call["X140"]!), X142: Double(call["X142"]!), X144: Double(call["X144"]!), X146: Double(call["X146"]!), X148: Double(call["X148"]!)) {
                    //Swift.print(output.Gruppe + " \(output.GruppeProbability[output.Gruppe])")
                    speciesClassificationResults?.append(ResultItem(result: output.Art, probability: output.ArtProbability[output.Art]!))
                    overallResultsIntern.addProbability(value: output.ArtProbability[output.Art]!, for: output.Art)
                    //return output.Gruppe
                }
            } else {
                speciesClassificationResults?.append(genusClassificationResults![index])
            }
        }
        speciesSummaryClassificationResults = Array()
        overallResultsIntern.probabilityThreshold = probThreshold
        overallResultsIntern.countThreshold = Int(countThreshold)
        for aResultContainer in overallResultsIntern.sorted(summaryBasedOn: .probability) {
            speciesSummaryClassificationResults?.append(ResultItem(result: aResultContainer.result, probability: aResultContainer.overallResult(threshold: probThreshold), count:aResultContainer.count))
        }
        return true
    }
    
    private func speciesOnlyClassification() async -> Bool {
        guard let batIdent2Data = batIdent2Data, let classifier = self.speciesOnlyClassifier else {
            return false
        }
        speciesOnlyClassificationResults = Array()
        var overallResultsIntern = FileResults()
        for call in batIdent2Data {
            if let output = try? classifier.prediction(Dur: Double(call["Dur"]!), Sfreq: Double(call["Sfreq"]!), Efreq: Double(call["Efreq"]!), NMod: Double(call["NMod"]!), FMod: Double(call["FMod"]!), FRmin: Double(call["FRmin"]!), Rmin: Double(call["Rmin"]!), tRmin: Double(call["tRmin"]!), Rlastms: Double(call["Rlastms"]!), Flastms: Double(call["Flastms"]!), Fknee: Double(call["Fknee"]!), Alphaknee: Double(call["Alphaknee"]!), Rknee: Double(call["Rknee"]!), ptknee: Double(call["ptknee"]!), Fmk: Double(call["Fmk"]!), Alphamk: Double(call["Alphamk"]!), Rmk: Double(call["Rmk"]!), ptmk: Double(call["ptmk"]!), Fmed: Double(call["Fmed"]!), Fmidt: Double(call["Fmidt"]!), Fmidf: Double(call["Fmidf"]!), tmidf: Double(call["tmidf"]!), ptmidf: Double(call["ptmidf"]!), PFmidt: Double(call["PFmidt"]!), Rmidt: Double(call["Rmidt"]!), Rmed: Double(call["Rmed"]!), Rges: Double(call["Rges"]!), Dfm: Double(call["Dfm"]!), Dqcf: Double(call["Dqcf"]!), Typ: Double(call["Typ"]!), X10: Double(call["X10"]!), X11: Double(call["X11"]!), X12: Double(call["X12"]!), X13: Double(call["X13"]!), X14: Double(call["X14"]!), X15: Double(call["X15"]!), X16: Double(call["X16"]!), X17: Double(call["X17"]!), X18: Double(call["X18"]!), X19: Double(call["X19"]!), X20: Double(call["X20"]!), X21: Double(call["X21"]!), X22: Double(call["X22"]!), X23: Double(call["X23"]!), X24: Double(call["X24"]!), X25: Double(call["X25"]!), X26: Double(call["X26"]!), X27: Double(call["X27"]!), X28: Double(call["X28"]!), X29: Double(call["X29"]!), X30: Double(call["X30"]!), X31: Double(call["X31"]!), X32: Double(call["X32"]!), X33: Double(call["X33"]!), X34: Double(call["X34"]!), X35: Double(call["X35"]!), X36: Double(call["X36"]!), X37: Double(call["X37"]!), X38: Double(call["X38"]!), X39: Double(call["X39"]!), X40: Double(call["X40"]!), X41: Double(call["X41"]!), X42: Double(call["X42"]!), X43: Double(call["X43"]!), X44: Double(call["X44"]!), X45: Double(call["X45"]!), X46: Double(call["X46"]!), X47: Double(call["X47"]!), X48: Double(call["X48"]!), X49: Double(call["X49"]!), X50: Double(call["X50"]!), X51: Double(call["X51"]!), X52: Double(call["X52"]!), X53: Double(call["X53"]!), X54: Double(call["X54"]!), X55: Double(call["X55"]!), X56: Double(call["X56"]!), X57: Double(call["X57"]!), X58: Double(call["X58"]!), X59: Double(call["X59"]!), X60: Double(call["X60"]!), X62: Double(call["X62"]!), X64: Double(call["X64"]!), X66: Double(call["X66"]!), X68: Double(call["X68"]!), X70: Double(call["X70"]!), X72: Double(call["X72"]!), X74: Double(call["X74"]!), X76: Double(call["X76"]!), X78: Double(call["X78"]!), X80: Double(call["X80"]!), X82: Double(call["X82"]!), X84: Double(call["X84"]!), X86: Double(call["X86"]!), X88: Double(call["X88"]!), X90: Double(call["X90"]!), X92: Double(call["X92"]!), X94: Double(call["X94"]!), X96: Double(call["X96"]!), X98: Double(call["X98"]!), X100: Double(call["X100"]!), X102: Double(call["X102"]!), X104: Double(call["X104"]!), X106: Double(call["X106"]!), X108: Double(call["X108"]!), X110: Double(call["X110"]!), X112: Double(call["X112"]!), X114: Double(call["X114"]!), X116: Double(call["X116"]!), X118: Double(call["X118"]!), X120: Double(call["X120"]!), X122: Double(call["X122"]!), X124: Double(call["X124"]!), X126: Double(call["X126"]!), X128: Double(call["X128"]!), X130: Double(call["X130"]!), X132: Double(call["X132"]!), X134: Double(call["X134"]!), X136: Double(call["X136"]!), X138: Double(call["X138"]!), X140: Double(call["X140"]!), X142: Double(call["X142"]!), X144: Double(call["X144"]!), X146: Double(call["X146"]!), X148: Double(call["X148"]!)) {
                //Swift.print(output.Gruppe + " \(output.GruppeProbability[output.Gruppe])")
                speciesOnlyClassificationResults?.append(ResultItem(result: output.Art, probability: output.ArtProbability[output.Art]!))
                overallResultsIntern.addProbability(value: output.ArtProbability[output.Art]!, for: output.Art)
            }
        }
        speciesOnlySummaryClassificationResults = Array()
        overallResultsIntern.probabilityThreshold = probThreshold
        overallResultsIntern.countThreshold = Int(countThreshold)
        for aResultContainer in overallResultsIntern.sorted(summaryBasedOn: .probability) {
            speciesOnlySummaryClassificationResults?.append(ResultItem(result: aResultContainer.result, probability: aResultContainer.overallResult(), count:aResultContainer.count))
        }
        return true
    }
    
}
