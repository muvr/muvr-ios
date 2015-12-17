//
//  MKInputPreperator.swift
//  Muvr
//
//  Created by Tom Bocklisch on 14.12.15.
//  Copyright © 2015 Muvr. All rights reserved.
//

import Foundation

public struct MKInputPreperator {
    private let accelerometerValueRange = Float(4.0) // most values will be between -2.0 and 2.0
    
    private let featureSampleRate = Float(1.0/50)
    
    private let highpassFilterCutoff = Float(1.0/10)
    
    /// 
    /// Scale the data that is in [-range/2, range/2] to be in range [-1, 1]
    ///
    func scale(data: [Float], range: Float) -> [Float] {
        return data.map{e in Float(e) / (range / 2)}
    }
    
    ///
    /// Apply a highpass filter to the passed in data using the given parameters. This will remove high frequency signal alterations from
    /// the data.
    ///
    func highpassfilter(data: [Float], rate: Float, freq: Float, offset: Int = 0, stride: Int = 1, dimensions: Int = 1) -> [Float] {
        let dt = 1.0 / rate;
        let RC = 1.0 / freq;
        let alpha = RC / (RC + dt)
        let count = (data.count - offset) / stride / dimensions
        var filtered = [Float](count: count * dimensions, repeatedValue: 0.0)
        
        for d in 0..<dimensions {
            filtered[d] = data[offset + d * stride]
        }
        
        for var idx = 1; idx < count; ++idx {
            for d in 0..<dimensions {
                let i = idx * dimensions + d
                filtered[i] =  data[offset + i * stride] * alpha + filtered[i-dimensions] * (1.0 - alpha)
            }
        }
        return filtered
    }
    
    func preprocess(input: [Float], dimensions: Int) -> [Float] {
        return highpassfilter(scale(input, range: self.accelerometerValueRange), rate: self.featureSampleRate, freq: self.highpassFilterCutoff, dimensions: dimensions)
    }
}

