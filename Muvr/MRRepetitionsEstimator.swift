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
    
    private func autocorrelation(data: [Double]) -> [Double] {
        let NF = data.count
        let NC = 2*NF+1
        var correlation = [Double](count:NC, repeatedValue: 0)
        let filter = data + [Double](count:NF, repeatedValue: 0)
        
        vDSP_convD(data, vDSP_Stride(1), filter, vDSP_Stride(1), &correlation, vDSP_Stride(1), vDSP_Length(NC), vDSP_Length(NF))
        return correlation
    }
    
    private func selectRepetition(repetitionsInDimensions: [Int]) -> Int? {
        var min: Int?;
        for rep in repetitionsInDimensions {
            if(min == nil || rep < min){
                min = rep
            }
        }
        return min
    }
    
    func numberOfRepetitions(data: [[Double]]) -> Int? {
        var repetitionsInDimenstion = [Int]()
        for dimension in data {
            var correlation = autocorrelation(dimension)
            let peaks = findPeaks(correlation, nDowns: 1, nUps: 1)
            
            let repetitions = guessNumberOfRepetitions(from: peaks, withMinPeakDistance: 40)
            repetitionsInDimenstion.append(repetitions)
        }
        return selectRepetition(repetitionsInDimenstion)
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