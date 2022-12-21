//
//  FFTAnalyzer.swift
//  bcAnalyze3
//
//  Created by Volker Runkel on 27.10.14.
//  Copyright (c) 2014 ecoObs GmbH. All rights reserved.
//

import Foundation
import Accelerate
import Quartz
import QuartzCore
import CoreGraphics
import SwiftImage

public class FFTAnalyzer {

    var lastdBGain: Float = 0.0
    
    let conv_fftsetup = vDSP_create_fftsetup(vDSP_Length(log2(Double(2048))), FFTRadix(kFFTRadix2))
    
    deinit {
        vDSP_destroy_fftsetup(conv_fftsetup)
    }
    
    class func calculateAnalysisWindowClass(numberOfSamples: Int, windowType:Int)->[Float] {
        
        var window = [Float](repeating:1.0, count:numberOfSamples) // also rectangle!
        let halfWindow = numberOfSamples / 2
        switch windowType {
        case 1: // Hanning
            //vDSP_hann_window(UnsafeMutablePointer(mutating: window), vDSP_Length(numberOfSamples), 0) // Hann
            vDSP_hann_window(&window, vDSP_Length(numberOfSamples), 0) // Hann
            /*for index in 0..<numberOfSamples {
             window[index] = Float(0.5 - 0.5*(cos(2*M_PI*Double(index)/Double(numberOfSamples-1)))) // Hanning window
             }*/
        case 2: vDSP_hamm_window(&window, vDSP_Length(numberOfSamples), 0) // Hamm
        case 3:
            for index in 0..<numberOfSamples {
                window[index] = 1 - (Float(index) / Float(halfWindow))
            }
        case 4: vDSP_blkman_window(&window, vDSP_Length(numberOfSamples), 0) // Blckman
        case 5: // Flattop
            for index in 0..<numberOfSamples {
                var value: Double = 1 - 1.933 * cos(2 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 1.286 * cos(4 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value - 0.388 * cos(6 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 0.032 * cos(8 * .pi * Double(index)/Double(numberOfSamples-1))
                window[index] = Float(value)
            }
        case 6: // quick 7term harris hack
            for index in 0..<numberOfSamples {
                var value: Double = 0.27122036 - 0.4334461*cos(2 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 0.2180041*cos(4 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value - 0.0657853 * cos(6 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 0.010761867 * cos(8 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value - 0.000770012*cos(10 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 0.0000136*cos(12 * .pi * Double(index)/Double(numberOfSamples-1))
                window[index] = Float(value)
            }
        default: window[0] = 1.0
        }
        return window
    }
    
    // To get rid of the `() -> () in` casting
    func withExtendedLifetime<T>(x: T, f: () -> ()) {
        return Swift.withExtendedLifetime(x, f)
        /*do {
            return try Swift.withExtendedLifetime(x, f)
        } catch _ {
            print("Error trying")
        }*/
        
    }
    
    // In the spirit of withUnsafePointers
    func withExtendedLifetimes<A0, A1>(arg0: A0, _ arg1: A1, f: () -> ()) {
        return withExtendedLifetime(x: arg0) { self.withExtendedLifetime(x: arg1, f: f) }
    }
    
    internal func calculateAnalysisWindow(numberOfSamples: Int, windowType:Int)->[Float] {
        
        var window = [Float](repeating:1.0, count:numberOfSamples) // also rectangle!
        let halfWindow = numberOfSamples / 2
        switch windowType {
        case 1: // Hanning
            vDSP_hann_window(&window, vDSP_Length(numberOfSamples), 0) // Hann
        case 2: vDSP_hamm_window(&window, vDSP_Length(numberOfSamples), 0) // Hamm
        case 3:
            for index in 0..<numberOfSamples {
                window[index] = 1 - (Float(index) / Float(halfWindow))
            }
        case 4: vDSP_blkman_window(&window, vDSP_Length(numberOfSamples), 0) // Blckman
        case 5: // Flattop
            for index in 0..<numberOfSamples {
                var value: Double = 1 - 1.933 * cos(2 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 1.286 * cos(4 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value - 0.388 * cos(6 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 0.032 * cos(8 * .pi * Double(index)/Double(numberOfSamples-1))
                window[index] = Float(value)
            }
        case 6: // quick 7term harris hack
            for index in 0..<numberOfSamples {
                var value: Double = 0.27122036 - 0.4334461*cos(2 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 0.2180041*cos(4 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value - 0.0657853 * cos(6 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 0.010761867 * cos(8 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value - 0.000770012*cos(10 * .pi * Double(index)/Double(numberOfSamples-1))
                value = value + 0.0000136*cos(12 * .pi * Double(index)/Double(numberOfSamples-1))
                window[index] = Float(value)
            }
        default: window[0] = 1.0
        }
        return window
    }
   
    internal func spectrumForValues(signal: [Float], fftsetup: FFTSetup) -> [Float] {
        // Find the largest power of two in our samples
        let log2N = vDSP_Length(log2(Double(signal.count)))
        let n = 1 << log2N
        let fftLength = n / 2
        
        // This is expensive; factor it out if you need to call this function a lot
        //let fftsetup = vDSP_create_fftsetup(log2N, FFTRadix(kFFTRadix2))
        
        var fft = [Float](repeating:0.0, count:Int(n))
        
        // Generate a split complex vector from the real data
        var realp = [Float](repeating:0.0, count:Int(fftLength))
        var imagp = realp
        //var myfftsetup = fftsetup
        
        withExtendedLifetimes(arg0: realp, imagp) {
            var splitComplex = DSPSplitComplex(realp:&realp, imagp:&imagp)
            UnsafePointer(signal).withMemoryRebound(to: DSPComplex.self, capacity: 1) {
                vDSP_ctoz($0, 2, &splitComplex, 1, vDSP_Length(fftLength))
            }
            //vDSP_ctoz(UnsafePointer(signal), 2, &splitComplex, 1, fftLength)
            
            // Take the fft
            vDSP_fft_zrip(fftsetup, &splitComplex, 1, log2N, FFTDirection(kFFTDirection_Forward))
            
            // Normalize
            var normFactor: Float = 1.0 / Float(n*2)
            vDSP_vsmul(splitComplex.realp, 1, &normFactor, splitComplex.realp, 1, vDSP_Length(fftLength))
            vDSP_vsmul(splitComplex.imagp, 1, &normFactor, splitComplex.imagp, 1, vDSP_Length(fftLength))
            
            // Zero out Nyquist
            splitComplex.imagp[0] = 0.0
            
            // Convert complex FFT to magnitude
            var b: Float = 1
            vDSP_zvmags(&splitComplex, 1, &fft, 1, vDSP_Length(fftLength))
            
            /* test um mehr vektor zu machen */
            var kAdjust0DB : Float = 1.5849e-13
            /*vDSP_vsadd(UnsafePointer(fft), 1, &kAdjust0DB, UnsafeMutablePointer(mutating: fft), 1, vDSP_Length(fftLength));
            vDSP_vdbcon(UnsafePointer(fft), 1, &b, UnsafeMutablePointer(mutating: fft), 1, vDSP_Length(fftLength), 1);*/
            var _fft = fft
            vDSP_vsadd(&_fft, 1, &kAdjust0DB, &fft, 1, vDSP_Length(fftLength));
            vDSP_vdbcon(&_fft, 1, &b, &fft, 1, vDSP_Length(fftLength), 1);
            
            /* test ende */
            
            //vvsqrtf(UnsafeMutablePointer(fft), UnsafePointer(fft), [Int32(fftLength)])
            //vDSP_vdbcon(UnsafePointer(fft), vDSP_Stride(1), UnsafePointer(b), UnsafeMutablePointer(fft), vDSP_Stride(1), [Int32(fftLength)], 0)
            
        }
        
        // Cleanup
        //vDSP_destroy_fftsetup(fftsetup)
        return fft
    }
    
    public func sonagramImage(fromSamples: [Float]!, startSample: Int = 0, numberOfSamples: Int!, FFTSize: Int = 256, Overlap: Float = 0.75, Window: Int = 0, ScaleFactor: Float = 128.0 / 96.0) -> CGImage? {
        
        if fromSamples.count < startSample+numberOfSamples {
            return nil
        }
        let halfSize = FFTSize / 2
        var sampleOverlap =  Int(Float(FFTSize)*(1.0-Overlap))
        var numberOfFrames = ((numberOfSamples /*- FFTSize*/) / sampleOverlap ) + 1
        if numberOfFrames > 30000 {
            numberOfFrames = 30000
            sampleOverlap = 1 + (numberOfSamples /*- FFTSize*/) / numberOfFrames
        }
        let overallSize = numberOfFrames*halfSize
        let whitePixel = GrayPixel(g:255)
        var results = [GrayPixel](repeating: whitePixel, count: overallSize) // will hold results later
        
        var b = [Float](repeating: 0.0, count: FFTSize) // will hold my data later
        let window = calculateAnalysisWindow(numberOfSamples: FFTSize, windowType:Window)
        
        var frameIndex: Int = startSample
        var curAddr: Int = 0
        let log2N = vDSP_Length(log2(Double(FFTSize)))
        let fftsetup = vDSP_create_fftsetup(log2N, FFTRadix(kFFTRadix2))
        
        var imageWidth = 0
        while (frameIndex + FFTSize - 1) < startSample+numberOfSamples {
            b[0..<FFTSize] = fromSamples[frameIndex..<frameIndex+FFTSize]
            vDSP_vmul(window,1,b,1,UnsafeMutablePointer(mutating: b),1,vDSP_Length(FFTSize))
            var fft =  spectrumForValues(signal: b, fftsetup: fftsetup!)
            
            for index in 1..<halfSize {
                var value: Int = -Int(fft[index])
                if value > 255 { value = 255}
                results[curAddr+index*numberOfFrames].g = UInt8(abs(value))
            }
            curAddr += 1
            frameIndex += sampleOverlap;
            imageWidth += 1
        }
        
        // Cleanup
        
        let rgbColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        
        var data = results
        let dataProvider = CGDataProvider(
            data: NSData(bytes: &data, length: data.count * MemoryLayout<GrayPixel>.size)
        )
        
        let resultImage = CGImage(width: imageWidth /*Int(numberOfFrames)*/, height: Int(halfSize), bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: Int(numberOfFrames*MemoryLayout<GrayPixel>.size), space: rgbColorSpace, bitmapInfo: bitmapInfo, provider: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        return resultImage
    }
    
    public func spectrumData(fromSamples: [Float]!, startSample: Int = 0, numberOfSamples: Int!, FFTSize: Int = 0, Window: Int = 0, ScaleFactor: Float = 128.0 / 96.0) -> [Float]? {
        if FFTSize == 0 || numberOfSamples == 0 {
            return nil
        }
        
        var b = [Float](repeating: 0.0, count: FFTSize)
        let window = calculateAnalysisWindow(numberOfSamples: FFTSize, windowType:Window)
        let log2N = vDSP_Length(log2(Double(FFTSize)))
        let fftsetup = vDSP_create_fftsetup(log2N, FFTRadix(kFFTRadix2))
        
        b[0..<FFTSize] = fromSamples[startSample..<FFTSize+startSample]
        vDSP_vmul(window,1,b,1,UnsafeMutablePointer(mutating: b),1,vDSP_Length(FFTSize))
        var fft =  spectrumForValues(signal: b, fftsetup: fftsetup!)
        
        return Array(fft[0..<FFTSize/2])
    }
    
    public func spectrumHiresData(fromSamples: [Float]!, startSample: Int = 0, numberOfSamples: Int!, FFTSize: Int = 0, Window: Int = 0, ScaleFactor: Float = 128.0 / 96.0) -> [Float]? {
        if numberOfSamples == 0 {
            return nil
        }
        
        var i = 1.0
        while pow(2.0,i) < Double(numberOfSamples) {
            i += 1
        }
        
        let spectrumFFTSize = Int(pow(2,i))
        var b = [Float](repeating: 0.0, count: spectrumFFTSize)

        let dataStart = (spectrumFFTSize-numberOfSamples) / 2
        
        let window = calculateAnalysisWindow(numberOfSamples: spectrumFFTSize, windowType:Window)
        let log2N = vDSP_Length(log2(Double(spectrumFFTSize)))
        let fftsetup = vDSP_create_fftsetup(log2N, FFTRadix(kFFTRadix2))
        
        if numberOfSamples+startSample <= fromSamples.count {
            b[dataStart..<numberOfSamples+dataStart] = fromSamples[startSample..<numberOfSamples+startSample]
        }
        else {
            b[dataStart..<numberOfSamples+dataStart] = fromSamples[startSample..<(fromSamples.count-startSample)]
        }
        vDSP_vmul(window,1,b,1,UnsafeMutablePointer(mutating: b),1,vDSP_Length(spectrumFFTSize))
        var fft =  spectrumForValues(signal: b, fftsetup: fftsetup!)
        
        return Array(fft[0..<spectrumFFTSize/2])
    }
    
    public func meanFrequency( fromSamples: inout [Float], startSample: Int, sizeSamples: Int) -> Float {
        var fftsize = sizeSamples
        var i = 0
        while (pow(2,Float(i)) < Float(sizeSamples)) {
            i += 1
        }
        fftsize = Int(pow(2,Float(i)))
        if fftsize > 65536 {
            fftsize = 65536
        }
        let fft = spectrumData(fromSamples: fromSamples, startSample: startSample, numberOfSamples: sizeSamples, FFTSize: fftsize, Window:0)
        
        var maxDB: Float = -255.0
        var maxFreq = 0.0
        var meanF: Float = 0.0
        for index in 1..<fftsize/2 {
            let value =  fft![index]
            
            if value > maxDB {
                maxDB = value
                maxFreq = Double(fftsize/2)/Double(index)
            }
        }
    meanF = Float(maxFreq)
    return meanF
    
    }
    
    public func sonagramImageRGBA(fromSamples: inout [Float]!, startSample: Int = 0, numberOfSamples: Int!, FFTSize: Int = 256, Overlap: Float = 0.75, Window: Int = 0, ScaleFactor: Float = 128.0 / 96.0) -> CGImage? {
        
        var image : Image<RGBA<UInt8>>?
        let colorType = 4
        image = Image<RGBA<UInt8>>(named: "SonaBright")!
        
        let halfSize = FFTSize / 2
        var sampleOverlap =  Int(Float(FFTSize)*(1.0-Overlap))
        var numberOfFrames = ((numberOfSamples) / sampleOverlap ) + 1
        if numberOfFrames > 30000 {
            numberOfFrames = 30000
            sampleOverlap = 1 + (numberOfSamples) / numberOfFrames
        }
        let overallSize = numberOfFrames*halfSize
        
        let whitePixel = RGBAPixel(r: 0, g: 0, b: 0, a: 255)
        var results = [RGBAPixel](repeating: whitePixel, count: overallSize) // will hold results later
        
        var b = [Float](repeating: 0.0, count: FFTSize) // will hold my data later
        let window = calculateAnalysisWindow(numberOfSamples: FFTSize, windowType:Window)
        
        var localStartSample = startSample
        if localStartSample < 0 {
            localStartSample = 0
        }
        var frameIndex: Int = localStartSample
        var curAddr: Int = 0
        let log2N = vDSP_Length(log2(Double(FFTSize)))
        let fftsetup = vDSP_create_fftsetup(log2N, FFTRadix(kFFTRadix2))
        
        let spreadFactor : Float = 1
        
        var imageWidth = 0
        let dBGain = self.lastdBGain
        let cutOffValue = 255
        
        while (frameIndex + FFTSize - 1) < localStartSample+numberOfSamples {
            b[0..<FFTSize] = fromSamples[frameIndex..<frameIndex+FFTSize]
            vDSP_vmul(window,1,b,1,UnsafeMutablePointer(mutating: b),1,vDSP_Length(FFTSize))
            var fft =  spectrumForValues(signal: b, fftsetup: fftsetup!)
            if dBGain != 0.0 {
                fft = fft.map{$0 - dBGain - self.lastdBGain}
            }
            if abs(spreadFactor - 1.0) > 0.1 {
                fft = fft.map{$0 * spreadFactor}
            }
            for index in 1..<halfSize {
                var floatValue = fft[index]
                if floatValue == -.infinity {
                    floatValue = 0
                }
                if floatValue == .infinity {
                    floatValue = 255
                }
                if !floatValue.isNaN {
                    
                    
                    var value: Int = -Int(floatValue)
                    if value > cutOffValue { value = 255}
                    if value < 0 { value = 0}
                    
                    var redValue =  UInt8(255)
                    var greenValue = UInt8(255)
                    var blueValue = UInt8(255)
                    
                    if colorType > 1 {
                        let pixel: RGBA<UInt8> = image![abs(value), 0]
                        redValue =  UInt8(pixel.red)
                        greenValue = UInt8(pixel.green)
                        blueValue = UInt8(pixel.blue)
                    }
                    
                    results[curAddr+index*numberOfFrames].setRGB(red: redValue, green: greenValue, blue: blueValue)
                    
                }
                else {
                    results[curAddr+index*numberOfFrames].setRGB(red: UInt8(abs(0)), green: UInt8(abs(0)), blue: UInt8(abs(0)))
                }
            }
            curAddr += 1
            frameIndex += sampleOverlap;
            imageWidth += 1
        }
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        var data = results
        let dataProvider = CGDataProvider(data: NSData(bytes: &data, length: data.count * MemoryLayout<RGBAPixel>.size))
        
        let resultImage = CGImage(width: imageWidth/*Int(numberOfFrames)*/, height: Int(halfSize), bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: Int(numberOfFrames*MemoryLayout<RGBAPixel>.size), space: rgbColorSpace, bitmapInfo: bitmapInfo, provider: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        vDSP_destroy_fftsetup(fftsetup)
        return resultImage
    }
}
