//
//  MRDummyPredictor.swift
//  Muvr
//
//  Created by Damien Bailly on 13/01/2016.
//  Copyright © 2016 Muvr. All rights reserved.
//

import Foundation
import MuvrKit

class MRDummyPredictor : MKPredictor {
    
    func predicAt<K where K : Hashable>(x: Int, forKey: K) -> Double {
        return 10
    }
    
}