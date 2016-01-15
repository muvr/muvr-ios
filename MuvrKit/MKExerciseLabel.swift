//
//  MKExerciseLabel.swift
//  Muvr
//
//  Created by Jan Machacek on 15/01/2016.
//  Copyright © 2016 Muvr. All rights reserved.
//

import Foundation

public enum MKExerciseLabel {
    
    case Weight(weight: Double)
    
    case Repetitions(repetitions: Int)
        
    // case AverageHeartRate(heartRate: Double)
    
    // case Distance(distance: Double)
    
    // ...
    
}

public enum MKExerciseLabelDescriptor {
    
    case Weight
    
    case Repetitions
    
}