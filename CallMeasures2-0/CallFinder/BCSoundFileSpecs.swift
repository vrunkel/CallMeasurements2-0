//
//  BCSoundFileSpecs.swift
//  bcAdmin4
//
//  Created by Volker Runkel on 10.11.16.
//  Copyright © 2016 ecoObs GmbH. All rights reserved.
//

import Foundation
import CoreServices
import AudioToolbox
import CoreAudio

import AVFoundation

public class BCSoundFileSpecs {
    
    static let sharedInstance = BCSoundFileSpecs()
        
    func readHeader(of audioURL: URL) ->  audioHeader? {
        
        if audioURL.pathExtension.lowercased() == "raw" {
            
            var header: audioHeader = audioHeader()
            header.samplerate = 500000
            header.channelCount = 1
            header.sampleFormat = .Sample16bitLE
            header.fileType = .batcorder_raw
            
            do {
                header.sampleCount = try FileManager.default.attributesOfItem(atPath:audioURL.path)[FileAttributeKey.size] as! Int / 2
                
            }
            catch {
                return nil
            }
            
            return header
        }
        else {
            var header: audioHeader = audioHeader()
            var audioFile : AudioFileID?
            let status = AudioFileOpenURL(audioURL as CFURL, AudioFilePermissions.readPermission, 0, &audioFile)
            if status != 0 {
                
                if audioFile != nil {
                    AudioFileClose(audioFile!)
                }
                let tempSoundData = NSData(contentsOf: audioURL)
                if nil == tempSoundData || tempSoundData?.length == 0 {
                    /*header.sampleCount = 0
                    self.soundData = [Float](count: self.sampleCount, repeatedValue: 10.0)*/
                    return nil
                }
                var buffer: Array<Int8> = Array(repeating: 00, count: 5)
                var i = 0
                //var headerHandled = false
                
                //for i=0; i < tempSoundData!.length - 4; i += 1 {
                for _ in 0..<(tempSoundData!.length - 4) {
                    tempSoundData!.getBytes(&buffer, range: NSMakeRange(i,4))
                    if let myString = String(validatingUTF8: UnsafePointer(buffer)) {
                        if myString == "fmt " {
                            i += 8
                            
                            var channels = 0
                            tempSoundData!.getBytes(&channels, range: NSMakeRange(i,2))
                            
                            var samplerate = 0
                            i += 4
                            tempSoundData!.getBytes(&samplerate, range: NSMakeRange(i,4))
                            if channels > 2 || channels < 1 {
                                return nil
                            }
                            header.channelCount = channels
                            header.samplerate = samplerate
                            
                            var dataString = ""
                            while dataString != "data" && i < tempSoundData!.length - 4 {
                                i += 1
                                tempSoundData!.getBytes(&buffer, range: NSMakeRange(i,4))
                                if let testString = String(validatingUTF8: UnsafePointer(buffer)) {
                                    dataString = testString
                                }
                                
                            }
                            i += 4
                            let audiobytecount = ((tempSoundData!.length-i)/2)*header.channelCount
                            header.sampleCount = audiobytecount
                            header.soundStartSample = i
                            header.fileType = .batsound_wave
                            return header
                        }
                    }
                    i += 1
                }
                return nil
            }
            guard let _audioFile = audioFile else { return nil }
            var inputFormat = AudioStreamBasicDescription(mSampleRate: 500000.0, mFormatID: AudioFormatID(kAudioFormatLinearPCM), mFormatFlags: AudioFormatFlags(kAudioFormatFlagsNativeFloatPacked), mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4, mChannelsPerFrame: 1, mBitsPerChannel: 32, mReserved: 0)
            
            var audioByteCount: UInt32 = 0
            var size: UInt32 = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
            var propertySize: UInt32  = 0
            var propWrite: UInt32 = 0
            
            var err = AudioFileGetProperty(_audioFile, UInt32(kAudioFilePropertyDataFormat), &size, &inputFormat)
            if err != 0 { print("ERROR") }
            else {
                header.channelCount = Int(inputFormat.mChannelsPerFrame)
                header.samplerate = Int(inputFormat.mSampleRate)
                header.audioFormatDescription = inputFormat
            }
            
            err = AudioFileGetPropertyInfo(_audioFile, UInt32(kAudioFilePropertyAudioDataByteCount), &propertySize, &propWrite)
            if err != 0 { print("ERROR") }
            else {
                err = AudioFileGetProperty(_audioFile, UInt32(kAudioFilePropertyAudioDataByteCount), &propertySize, &audioByteCount)
                if err != 0 { print("ERROR") }
                else {
                    header.sampleCount = Int(audioByteCount) / Int(inputFormat.mBytesPerFrame)
                }
            }
            header.fileType = .windows_wave
            AudioFileClose(audioFile!)
            return header
        }
    }
}

