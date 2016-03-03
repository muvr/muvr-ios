//
//  MRManagedExercisePlan.swift
//  Muvr
//
//  Created by Jan Machacek on 1/16/16.
//  Copyright © 2016 Muvr. All rights reserved.
//

import Foundation
import CoreData
import MuvrKit

///
/// Contains the list of exercise to be performed in a workout session
/// (The exercise list is stored as a MarkovChain)
///
class MRManagedExercisePlan: NSManagedObject {
    
    internal var plan: MKMarkovPredictor<MKExercise.Id>!

}
