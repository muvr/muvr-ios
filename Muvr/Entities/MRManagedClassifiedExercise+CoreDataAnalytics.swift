import Foundation
import MuvrKit
import CoreData

extension MRManagedClassifiedExercise {
    
    ///
    /// Average view of an exercise with the given ``exerciseId``. For simple 
    /// analytics, it appears to be sufficient to record average intensity,
    /// repetitions, weight and duration.
    ///
    struct Average {
        let exerciseId: MKExerciseId
        let count: Int

        let averageIntensity: Double
        let averageRepetitions: Int
        let averageWeight: Double
        let averageDuration: NSTimeInterval
        
        static func zero(exerciseId: MKExerciseId) -> Average {
            return Average(exerciseId: exerciseId, count: 0, averageIntensity: 0, averageRepetitions: 0, averageWeight: 0, averageDuration: 0)
        }
        
        private func plus(that: Average) -> Average {
            assert(that.exerciseId == self.exerciseId)
            
            return Average(exerciseId: exerciseId,
                count: count + that.count,
                averageIntensity: averageIntensity + that.averageIntensity,
                averageRepetitions: averageRepetitions + that.averageRepetitions,
                averageWeight: averageWeight + that.averageWeight,
                averageDuration: averageDuration + that.averageDuration
            )
        }
        
        private func div(by: Double) -> Average {
            return Average(exerciseId: exerciseId,
                count: count,
                averageIntensity: averageIntensity / by,
                averageRepetitions: Int(Double(averageRepetitions) / by),
                averageWeight: averageWeight / by,
                averageDuration: averageDuration / by
            )
        }
    }
    
    private static let countByEntity: NSExpressionDescription = {
        let count = NSExpressionDescription()
        count.name = "count"
        count.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "entity")])
        count.expressionResultType = NSAttributeType.Integer32AttributeType
        return count
    }()
    
    private static func averageFor(keyPath: String) -> NSExpressionDescription {
        let expr = NSExpressionDescription()
        expr.name = "\(keyPath)"
        expr.expression = NSExpression(forFunction: "average:", arguments: [NSExpression(forKeyPath: keyPath)])
        expr.expressionResultType = NSAttributeType.DoubleAttributeType
        return expr
    }
    
    private static func componentAt(index: Int, exerciseId: String) -> String? {
        let components = exerciseId.componentsSeparatedByString("/")
        if index >= 0 && index < components.count { return components[index] }
        return nil
    }

    static func averages(inManagedObjectContext managedObjectContext: NSManagedObjectContext, exerciseIdPrefix: String?) -> [Average] {
        let entity = NSEntityDescription.entityForName("MRManagedClassifiedExercise", inManagedObjectContext: managedObjectContext)
        let exerciseId = entity!.propertiesByName["exerciseId"]!

        let fetchRequest = NSFetchRequest(entityName: "MRManagedClassifiedExercise")
        fetchRequest.propertiesToFetch = [exerciseId, countByEntity, averageFor("duration"), averageFor("cdWeight"), averageFor("cdIntensity"), averageFor("cdRepetitions")]
        fetchRequest.propertiesToGroupBy = [exerciseId]
        if let exerciseIdPrefix = exerciseIdPrefix {
            fetchRequest.predicate = NSPredicate(format: "exerciseId LIKE %@", exerciseIdPrefix + "*")
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "exerciseSession.start", ascending: false)]
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        fetchRequest.fetchLimit = 100
        
        // exerciseIdComponentIndex is the number of "/" in ``exerciseIdPrefix`` if given or 0
        let exerciseIdComponentIndex = exerciseIdPrefix.map { $0.characters.reduce(0) { r, c in if c == "/" { return r + 1 } else { return r } } } ?? 0
        
        if let result = (try? managedObjectContext.executeFetchRequest(fetchRequest)) as? [NSDictionary] {
            var averages: [MKExerciseId : [Average]] = [:]
            for entry in result {
                if let exerciseId = componentAt(exerciseIdComponentIndex, exerciseId: entry["exerciseId"] as! String) {
                    let average = Average(
                        exerciseId: exerciseId,
                        count: (entry["count"] as! NSNumber).integerValue,
                        averageIntensity: (entry["cdIntensity"] as! NSNumber).doubleValue,
                        averageRepetitions: (entry["cdRepetitions"] as! NSNumber).integerValue,
                        averageWeight: (entry["cdWeight"] as! NSNumber).doubleValue,
                        averageDuration: (entry["duration"] as! NSNumber).doubleValue
                    )
                    
                    if let existingAverages = averages[exerciseId] {
                        averages[exerciseId] = existingAverages + [average]
                    } else {
                        averages[exerciseId] = [average]
                    }
                }
            }
            return averages.values.map { averages in
                let z = Average.zero(averages.first!.exerciseId)
                let reduced = averages.reduce(z) { $0.plus($1) }
                return reduced.div(Double(averages.count))
            }
        }
        
        return []
    }
//    
//    static func summary(inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
//        // volume: sum(duration)
//        // weight: sum(weight)
//        // intensity: sum(intensity)
//        // fitness: (weight * volume * intensity) / count
//        
//        let entity = NSEntityDescription.entityForName("MRManagedClassifiedExercise", inManagedObjectContext: managedObjectContext)
//        let exerciseSession = entity!.propertiesByName["exerciseSession"]!
//        
//        let fetchRequest = NSFetchRequest(entityName: "MRManagedClassifiedExercise")
//        fetchRequest.propertiesToFetch = [countByEntity, sumFor("duration"), sumFor("cdWeight"), sumFor("cdIntensity"), sumFor("cdRepetitions")]
//        fetchRequest.propertiesToGroupBy = [exerciseSession]
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "exerciseSession.start", ascending: false)]
//        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
//        fetchRequest.fetchLimit = 100
//        
//        let result = try? managedObjectContext.executeFetchRequest(fetchRequest)
//        NSLog("\(result)")
//    }
    

}