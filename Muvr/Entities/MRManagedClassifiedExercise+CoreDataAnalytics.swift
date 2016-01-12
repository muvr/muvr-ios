import Foundation
import MuvrKit
import CoreData

///
/// Adds basic (i.e. single-user) statistics for the classified exercises.
/// This is typically used on the home page.
///
extension MRManagedClassifiedExercise {
        
    ///
    /// Expression description for ``COUNT(_objectId)``, where ``_objectId`` is the identifier
    /// of whatever entity it is being applied to.
    ///
    private static let countByEntity: NSExpressionDescription = {
        let count = NSExpressionDescription()
        count.name = "count"
        count.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "entity")])
        count.expressionResultType = NSAttributeType.Integer32AttributeType
        return count
    }()
    
    ///
    /// Expression description for ``average:`` of ``keyPath``.
    /// - parameter keyPath: the property's KP
    /// - returns: the expression description
    ///
    private static func averageFor(keyPath: String) -> NSExpressionDescription {
        let expr = NSExpressionDescription()
        expr.name = "\(keyPath)"
        expr.expression = NSExpression(forFunction: "average:", arguments: [NSExpression(forKeyPath: keyPath)])
        expr.expressionResultType = NSAttributeType.DoubleAttributeType
        return expr
    }
    
    ///
    /// Computes the averages for the ``MRManagedClassifiedExercise`` in the given ``managedObjectContext``,
    /// whose ``exerciseId`` starts with ``exerciseIdPrefix``, dropping the ``exerciseIdPrefix`` from the
    /// exerciseIds returned.
    /// - parameter managedObjectContext: the MOC
    /// - parameter exerciseIdPrefix: the exercise id prefix to match (i.e. back/, arms/)
    /// - returns: the average for the last 100 sessions
    ///
    static func averages(inManagedObjectContext managedObjectContext: NSManagedObjectContext, aggregate: MRAggregate) -> [(MRAggregateKey, MRAverage)] {
                
        let fetchLimit = 100
        let entity = NSEntityDescription.entityForName("MRManagedClassifiedExercise", inManagedObjectContext: managedObjectContext)
        let exerciseId = entity!.propertiesByName["exerciseId"]!

        let fetchRequest = NSFetchRequest(entityName: "MRManagedClassifiedExercise")
        fetchRequest.propertiesToFetch = [exerciseId, countByEntity, averageFor("duration"), averageFor("cdWeight"), averageFor("cdIntensity"), averageFor("cdRepetitions")]
        fetchRequest.propertiesToGroupBy = [exerciseId]
        var keyExtractor: (MKExerciseId -> [MRAggregateKey])!
        switch aggregate {
        case .Exercises(let muscleGroup):
            // exerciseId LIKE *:%@*
            fetchRequest.predicate = NSPredicate(format: "exerciseId LIKE %@", "*:" + muscleGroup.id + "*")
            keyExtractor = { exerciseId in return [.Exercise(id: exerciseId)] }
        case .MuscleGroups(let type):
            // exerciseId LIKE %@:*
            fetchRequest.predicate = NSPredicate(format: "exerciseId LIKE %@", type.id + "*")
            keyExtractor = { exerciseId in
                if let mgs = MKMuscleGroup.fromExerciseId(exerciseId) {
                    return mgs.map { .MuscleGroup(muscleGroup: $0) }
                }
                return [.NoMuscleGroup]
            }
        case .Types:
            keyExtractor = { exerciseId in return [.ExerciseType(exerciseType: MKGeneralExerciseType.fromExerciseId(exerciseId)!)] }
        }
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "exerciseSession.start", ascending: false)]
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        fetchRequest.fetchLimit = fetchLimit
        
        if let result = (try? managedObjectContext.executeFetchRequest(fetchRequest)) as? [NSDictionary] {
            var averages: [MRAggregateKey : [MRAverage]] = [:]
            for entry in result {
                let exerciseId = entry["exerciseId"] as! String
                let average = MRAverage(
                    count: (entry["count"] as! NSNumber).integerValue,
                    averageIntensity: (entry["cdIntensity"] as? NSNumber)?.doubleValue ?? 0,
                    averageRepetitions: (entry["cdRepetitions"] as! NSNumber).integerValue,
                    averageWeight: (entry["cdWeight"] as? NSNumber)?.doubleValue ?? 0,
                    averageDuration: (entry["duration"] as? NSNumber)?.doubleValue ?? 0
                )
                
                keyExtractor(exerciseId).forEach { key in
                    if let existingAverages = averages[key] {
                        averages[key] = existingAverages + [average]
                    } else {
                        averages[key] = [average]
                    }
                }
            }
            return averages.map { k, averages in
                let z = MRAverage.zero()
                let reduced = averages.reduce(z) { $0.plus($1) }
                return (k, reduced.divideBy(Double(averages.count)))
            }
        }
        
        return []
    }

}

