//
//  MRRepetitionsEstimator.swift
//  Muvr
//
//  Created by Tom Bocklisch on 10/09/2015.
//  Copyright (c) 2015 Muvr. All rights reserved.
//

import Foundation
import Accelerate

class MRRepetitionsEstimator {
    
     func autocorrelation(data: [Double]) -> [Double] {
        let filterLength = data.count
        let resultLength = filterLength
        let lenSignal = 2*filterLength - 1
        var correlation = [Double](count:resultLength, repeatedValue: 0)
        let signal = data + [Double](count:filterLength - 1, repeatedValue: 0)
        
        vDSP_convD(signal, vDSP_Stride(1), data, vDSP_Stride(1), &correlation, vDSP_Stride(1), vDSP_Length(resultLength), vDSP_Length(filterLength))
        
        // Convert into [-1, 1]
        var max: Double = 2 / correlation[0]
        var shift: Double = -1
        vDSP_vsmsaD(correlation, vDSP_Stride(1), &max, &shift, &correlation, vDSP_Stride(1), vDSP_Length(correlation.count))
        
        return correlation
    }
    
    func numberOfRepetitions(data: [[Double]]) -> Int? {
        var repetitionsInDimenstion = [Int]()
        var peaksInDimenstion = [Int]()
        let N = data[0].count
        
        NSLog("Data size: %d", data[0].count)
        
        var summedCorr = [Double](count: N, repeatedValue: 0)
        
        for dimension in data {
            var correlation = autocorrelation(dimension)
            vDSP_vaddD(summedCorr, vDSP_Stride(1), correlation, vDSP_Stride(1), &summedCorr, vDSP_Stride(1), vDSP_Length(N))
        }
        
        let peaks = findPeaks(summedCorr, nDowns: 1, nUps: 1)
        NSLog("Peaks: %d", peaks.count)
        let repetitions = guessNumberOfRepetitions(from: peaks, withMinPeakDistance: 25)
        NSLog("Repetitions: %d", repetitions)
        return repetitions
    }
    
    private func guessNumberOfRepetitions(from peakLocations: [Int], withMinPeakDistance: Int) -> Int {
        if peakLocations.count <= 1 {
            return peakLocations.count
        }
        for i in 0...peakLocations.count - 2 {
            if peakLocations[i+1] - peakLocations[i] < withMinPeakDistance {
                return i + 1
            }
        }
        return peakLocations.count
    }
    
    func findPeaks(data: [Double], nDowns: Int = 1, nUps: Int = 1) -> [Int]{
        let windowSize = nDowns + nUps + 1
        var peaks = [Int]()
        
        for index in nDowns...data.count - nUps - 1 {
            var isPeak = true
            for j in -nDowns...nUps-1 {
                if j < 0 {
                    isPeak = isPeak && data[index + j] < data[index + j + 1]
                } else {
                    isPeak = isPeak && data[index + j] >= data[index + j + 1]
                }
            }
            if isPeak {
                peaks.append(index)
            }
        }
        return peaks
    }
}