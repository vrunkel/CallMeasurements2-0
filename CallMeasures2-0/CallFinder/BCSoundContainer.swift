//
//  BCSoundContainer.swift
//  bcAdmin4
//
//  Created by Volker Runkel on 28.11.16.
//  Copyright © 2016 ecoObs GmbH. All rights reserved.
//

import Foundation
import CoreServices
import AudioToolbox
import CoreAudio
import AVFoundation
import Cocoa
import Accelerate

import AVFoundation

struct audioIO {
    var pos: UInt32 = 0
    var srcBuffer: Array<Float>
    var srcBufferSize: UInt32 = 0
    var srcSizePerPacket: UInt32 = 4
    var	numPacketsPerRead:UInt32 = 0
    var maxPacketsInSound: UInt32 = 0
    var abl: AudioBufferList
}


func fillComplexCallback(myConverter: AudioConverterRef, packetNumber: UnsafeMutablePointer<UInt32>, ioData:UnsafeMutablePointer<AudioBufferList>, aspd: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>?>?, userInfo: UnsafeMutableRawPointer?) -> OSStatus {
    
    let myAIO = userInfo!.assumingMemoryBound(to: audioIO.self).pointee//UnsafeMutablePointer<audioIO>(userInfo).pointee
    
    if (packetNumber.pointee > myAIO.numPacketsPerRead) {
        //var pNumber = packetNumber.pointee
        packetNumber.pointee = myAIO.numPacketsPerRead
    }
    
    if (packetNumber.pointee +  myAIO.pos >= myAIO.maxPacketsInSound)
    {
        packetNumber.pointee = myAIO.maxPacketsInSound - myAIO.pos
    }
    
    let soundData:Array<Float> = myAIO.srcBuffer
    let _buffer: Array<Float> = Array(soundData[Int(myAIO.pos)..<Int(myAIO.pos+packetNumber.pointee)])
    let outByteSize = packetNumber.pointee * 4
    /*UnsafeMutablePointer<audioIO>(userInfo)*/userInfo!.assumingMemoryBound(to: audioIO.self).pointee.pos = myAIO.pos + packetNumber.pointee
    var abl = myAIO.abl
    
    abl.mBuffers.mDataByteSize = outByteSize
    abl.mBuffers.mNumberChannels = 1
    abl.mBuffers.mData = UnsafeMutableRawPointer(mutating: _buffer)
    UnsafeMutablePointer<AudioBufferList>(ioData).pointee = abl
    
    return 0
}

class BCSoundContainer
{
    var soundData: [Float]?
    var header: audioHeader?
    var sampleCount: Int = 0
    
    let denormal : Double = 0.000001
    
    init(with url: URL) throws {
        guard let header = BCSoundFileSpecs.sharedInstance.readHeader(of: url) else {
            throw AudioError.FileFormat
        }
        self.header = header
        if header.fileType == .batcorder_raw {
            let tempSoundData = try Data(contentsOf: url)
            self.sampleCount = self.header!.sampleCount
            self.soundData = [Float](repeating: 10.0, count: self.header!.sampleCount)
            tempSoundData.withUnsafeBytes({ (bytes: UnsafePointer<sint16>) -> Void in
                self.FloatFromSInt16(sourceObject: bytes)
            })
        }
        else if header.fileType == .windows_wave {
            guard let inputFormat = header.audioFormatDescription else {
                throw AudioError.FileFormat
            }

            var converterOutputFormat = inputFormat
            converterOutputFormat.mBytesPerFrame = converterOutputFormat.mChannelsPerFrame * 2
            converterOutputFormat.mBitsPerChannel = 16
            converterOutputFormat.mBytesPerPacket = converterOutputFormat.mChannelsPerFrame * 2
            
            let arraySize = Int(header.sampleCount*Int(inputFormat.mChannelsPerFrame))
            self.soundData = [Float](repeating: 0.0, count:arraySize)
            self.sampleCount = header.sampleCount
            
            //let isFloatFormat: Bool = inputFormat.mFormatFlags & AudioFormatFlags(kAudioFormatFlagIsFloat) == 1
            var err: OSStatus = 0
            var audioFile : AudioFileID?
            let status = AudioFileOpenURL(url as CFURL, AudioFilePermissions.readPermission, 0, &audioFile)
            if status != 0 { return }

            if inputFormat.mBitsPerChannel == 8 {
                var pos: Int = 0
                var writePos: Int = 0
                let stereoOffset = header.sampleCount
                var packetCount:UInt32  = 4096
                let IntToFloatScalar : Float = 1.0 / 256;
                var kSrcBufSizeSound:UInt32  = packetCount*inputFormat.mBytesPerFrame
                var rawBuffer = [UInt8](repeating: 0, count:Int(packetCount*2))
                let channelMax = header.channelCount
                while err != 0 || writePos<=header.sampleCount || packetCount > 0
                {
                    err = AudioFileReadPacketData(audioFile!, false, &kSrcBufSizeSound, nil, Int64(pos), &packetCount, &rawBuffer)
                    //println("\(writePos) : \(packetCount) and \(kSrcBufSizeSound)")
                    if err != 0 { break }
                    if packetCount < 2 {break }
                    for c in 0..<channelMax {
                        let start = c
                        var j = 0;
                        for i in stride(from: start, to: Int(packetCount), by: channelMax) {
                            if writePos+j >= header.sampleCount {break}
                            self.soundData?[(c*stereoOffset)+writePos+j] = Float(rawBuffer[i]) * IntToFloatScalar
                            j += 1
                        }
                    }
                    pos += Int(packetCount)/channelMax
                    writePos += Int(packetCount)/channelMax
                }
            }
            else if inputFormat.mBitsPerChannel == 16 {
                
                var pos: Int = 0
                var writePos: Int = 0
                let stereoOffset = header.sampleCount
                let IntToFloatScalar : Float = 1.0 / 32768.0;
                var packetCount:UInt32  = 4096
                var kSrcBufSizeSound:UInt32  = packetCount*inputFormat.mBytesPerFrame
                var rawBuffer = [Int16](repeating: 0, count:Int(packetCount*2))
                let channelMax = header.channelCount
                while err != 0 || writePos<=header.sampleCount || packetCount > 0
                {
                    err = AudioFileReadPacketData(audioFile!, false, &kSrcBufSizeSound, nil, Int64(pos), &packetCount, &rawBuffer)
                    //println("\(writePos) : \(packetCount) and \(kSrcBufSizeSound)")
                    if err != 0 { break }
                    if packetCount < 2 {break }
                    for c in 0..<channelMax {
                        let start = c
                        var j = 0;
                        for i in stride(from: start, to: Int(packetCount), by: channelMax) {
                            if writePos+j >= header.sampleCount {break}
                            self.soundData?[(c*stereoOffset)+writePos+j] = Float(rawBuffer[i]) * IntToFloatScalar
                            j += 1
                        }
                    }
                    pos += Int(packetCount)/channelMax
                    writePos += Int(packetCount)/channelMax
                }
            }
            else if inputFormat.mBitsPerChannel == 24 {
                var inputfile: ExtAudioFileRef?
                err = ExtAudioFileOpenURL(url as CFURL, &inputfile)
                if (err != 0) {
                    AudioFileClose(audioFile!)
                    print("Error ExtAudioFileOpen")
                    throw AudioError.FileFormat
                }
                
                var propertyWriteable: DarwinBoolean = false
                var propertySize: UInt32  = 0
                err = ExtAudioFileGetPropertyInfo(inputfile!, UInt32(kExtAudioFileProperty_ClientDataFormat), &propertySize, &propertyWriteable)
                if err != 0 {
                    AudioFileClose(audioFile!)
                    throw AudioError.FileFormat
                }
                
                err = ExtAudioFileSetProperty(inputfile!, kExtAudioFileProperty_ClientDataFormat, propertySize, &converterOutputFormat)
                if err != 0 {
                    AudioFileClose(audioFile!)
                    throw AudioError.FileFormat
                }
                
                let packetCount:UInt32  = UInt32(header.sampleCount)
                let kSrcBufSizeSound:UInt32  = packetCount*converterOutputFormat.mBytesPerFrame
                
                var pos: Int = 0
                let stereoOffset = header.sampleCount
                let IntToFloatScalar : Float = 1.0 / 32768.0;
                var _buffer = [Int16](repeating: 0, count:Int(packetCount*2))
                
                while 1 == 1 {
                    var fillBufList = AudioBufferList(mNumberBuffers: 1, mBuffers: AudioBuffer( mNumberChannels: inputFormat.mChannelsPerFrame, mDataByteSize: kSrcBufSizeSound, mData: &_buffer))
                    var numFrames = (kSrcBufSizeSound / converterOutputFormat.mBytesPerFrame) //packetCount
                    
                    err = ExtAudioFileRead (inputfile!, &numFrames, &fillBufList)
                    if err != 0 || numFrames == 0 {
                        break
                    }
                    
                    for c in 0..<header.channelCount {
                        let start = c
                        var j = 0
                        for i in stride(from: start, to: Int(numFrames*converterOutputFormat.mChannelsPerFrame), by: header.channelCount) {
                            if pos+j >= header.sampleCount {break}
                            self.soundData?[(c*stereoOffset)+pos+j] = Float(_buffer[i]) * IntToFloatScalar
                            j += 1
                        }
                    }
                    pos += Int(numFrames) / header.channelCount
                }
                ExtAudioFileDispose(inputfile!)
            }
            /*else if inputFormat.mBitsPerChannel == 32 {
                
                var pos: Int = 0
                var writePos: Int = 0
                let stereoOffset = self.sampleCount
                
                
                var packetCount:UInt32  = 4096
                var kSrcBufSizeSound:UInt32  = packetCount*inputFormat.mBytesPerFrame
                let channelMax = self.channelCount
                
                if isFloatFormat {
                    var rawBuffer = [Float32](count:Int(packetCount+10), repeatedValue: 0)
                    
                    while err != 0 || writePos<=self.sampleCount || packetCount > 0
                    {
                        err = AudioFileReadPacketData(audioFile, false, &kSrcBufSizeSound, nil, Int64(pos), &packetCount, &rawBuffer)
                        //print("\(writePos) : \(pos) : \(packetCount) and \(kSrcBufSizeSound)")
                        if err != 0 { break }
                        if packetCount < 2 {break }
                        for c in 0..<channelMax {
                            let start = c
                            var j = 0;
                            for i in start.stride(to: Int(packetCount), by: channelMax) {
                                if writePos+j >= self.sampleCount {break}
                                //print(rawBuffer[i])
                                self.soundData[(c*stereoOffset)+writePos+j] = rawBuffer[i] //Float(rawBuffer[i]) / IntToFloatScalar
                                j += 1
                            }
                        }
                        pos += Int(packetCount)/channelMax
                        writePos += Int(packetCount)/channelMax
                    }
                }
                else {
                    let IntToFloatScalar : Float = pow(2.0,31.0)
                    var rawBuffer = [Int32](count:Int(packetCount+1), repeatedValue: 0)
                    while err != 0 || writePos<=self.sampleCount || packetCount > 0
                    {
                        err = AudioFileReadPacketData(audioFile, false, &kSrcBufSizeSound, nil, Int64(pos), &packetCount, &rawBuffer)
                        //print("\(writePos) : \(pos) : \(packetCount) and \(kSrcBufSizeSound)")
                        if err != 0 { break }
                        if packetCount < 2 {break }
                        for c in 0..<channelMax {
                            let start = c
                            var j = 0;
                            for i in start.stride(to: Int(packetCount), by: channelMax) {
                                if writePos+j >= self.sampleCount {break}
                                //print(rawBuffer[i])
                                self.soundData[(c*stereoOffset)+writePos+j] = Float(rawBuffer[i]) / IntToFloatScalar
                                j += 1
                            }
                        }
                        pos += Int(packetCount)/channelMax
                        writePos += Int(packetCount)/channelMax
                    }
                }
            }*/
            else {
                AudioFileClose(audioFile!)
                throw AudioError.FileFormat
            }
            if audioFile != nil {
                AudioFileClose(audioFile!)
            }
        }
        else if header.fileType == .batsound_wave {
            let tempSoundData = try Data(contentsOf: url)
            
            self.soundData = [Float](repeating: 10.0, count: self.header!.sampleCount)
            tempSoundData.withUnsafeBytes({ (bytes: UnsafePointer<sint16>) -> Void in
                self.FloatFromSInt16(sourceObject: bytes, start: header.soundStartSample/2)
            })
            /*self.soundData = [Float](count: self.sampleCount, repeatedValue: 10.0)
             let rawSamples = UnsafePointer<sint16>(tempSoundData!.subdataWithRange(NSMakeRange(i,audiobytecount*2)).bytes)
             withExtendedLifetime(rawSamples) {
             self.FloatFromSInt16(rawSamples)
             }
             clientFormat = AudioStreamBasicDescription(mSampleRate: Float64(samplerate), mFormatID: AudioFormatID(kAudioFormatLinearPCM), mFormatFlags: AudioFormatFlags(kAudioFormatFlagsNativeFloatPacked), mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4, mChannelsPerFrame: UInt32(channels), mBitsPerChannel: 32, mReserved: 0)
             
             if self.sampleRate > 100000 {
             self.soundInfoText = String(format: "%.0fkHz - Batsound WAVE", Double(self.sampleRate) / 1000.0)
             }
             else {
             self.soundInfoText = String(format: "%.1fkHz - Batsound WAVE", Double(self.sampleRate) / 1000.0)
             }*/

        }
        else {
            throw AudioError.FileFormat
        }
    }
    
    func FloatFromSInt16(sourceObject:UnsafePointer<sint16>, channels: Int = 1, layoutInterleaved: Bool = true, start: Int = 0)
    {
        
        guard let header = self.header else {
            NSSound.beep()
            return
        }
        
        let IntToFloatScalar : Float = 1.0 / 32768.0;
        
        if layoutInterleaved {
            var dataCounter = 0
            for i in stride(from:start, to: header.sampleCount*channels, by: channels) {
                self.soundData![dataCounter] = Float(sourceObject[i]) * IntToFloatScalar
                if channels == 2 {
                    self.soundData![dataCounter+header.sampleCount] = Float(sourceObject[i+1]) * IntToFloatScalar
                }
                dataCounter += 1
            }
        }
        else {
            var dataCounter = 0
            for i in stride(from: start, to: header.sampleCount, by: 1) {
                self.soundData![dataCounter] = Float(sourceObject[i]) * IntToFloatScalar
                if channels == 2 {
                    self.soundData![dataCounter+header.sampleCount] = Float(sourceObject[i+header.sampleCount]) * IntToFloatScalar
                }
                dataCounter += 1
            }
        }
    }
        
    public func minMaxArrayLessMemory(stepSize: Int = 500, start: Int = 0) -> Array<Float> {
        if sampleCount == 0 {
            return Array()
        }

        var dataArray: Array<Float> = Array()
        
        //var i = 0
        let vStepsize: vDSP_Length = UInt(stepSize)
        //for i = 0; i < sampleCount-stepSize; i+=stepSize {
        for i in stride(from: 0, to: (sampleCount-stepSize), by: stepSize) {
            //var min: Float = 0.0
            var max: Float = 0.0
            var idx: vDSP_Length = 0
            let rangeEnd = i+stepSize
            let input = Array(self.soundData![i+start..<rangeEnd+start])
            //vDSP_minvi(input, 1, &min, &idx, vStepsize)
            vDSP_maxvi(input, 1, &max, &idx, vStepsize)
            dataArray.append(max)
        }
        return dataArray
    }
    
    func sonagramImage(from: Int, size: Int, fftParameters: FFTSettings) -> CGImage? {
        let fftAnalyzer = FFTAnalyzer()
        
        return fftAnalyzer.sonagramImageRGBA(fromSamples: &self.soundData, startSample: from, numberOfSamples: size, FFTSize: fftParameters.fftSize, Overlap: fftParameters.overlap, Window: fftParameters.window.rawValue)
        
    }
}
