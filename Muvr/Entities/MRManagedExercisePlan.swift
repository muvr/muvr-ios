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

class MRManagedExercisePlan: NSManagedObject {
    
    var plan: MKMarkovPredictor<MKExercise.Id>!

}
