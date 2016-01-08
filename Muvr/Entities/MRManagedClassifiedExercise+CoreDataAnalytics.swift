import Foundation
import MuvrKit
import CoreData

///
/// Adds basic (i.e. single-user) statistics for the classified exercises.
/// This is typically used on the home page.
///
extension MRManagedClassifiedExercise {
    
    ///
    /// Average view of an exercise with the given ``exerciseId``. For simple 
    /// analytics, it appears to be sufficient to record average intensity,
    /// repetitions, weight and duration.
    ///
    struct Average {
        /// The number of entries that make up the average
        let count: Int

        /// The intensity
        let averageIntensity: Double
        /// The repetitions
        let averageRepetitions: Int
        /// The weight
        let averageWeight: Double
        /// The duration
        let averageDuration: NSTimeInterval
        
        ///
        /// A zero value suited for ``Array.reduce``.
        /// - parameter exerciseId: the exercise id
        /// - returns: the 0 element
        ///
        static func zero() -> Average {
            return Average(count: 0, averageIntensity: 0, averageRepetitions: 0, averageWeight: 0, averageDuration: 0)
        }
        
        ///
        /// Adds ``that`` to this value
        /// - parameter that: the other value
        /// - returns: self + that
        ///
        private func plus(that: Average) -> Average {
            return Average(
                count: count + that.count,
                averageIntensity: averageIntensity + that.averageIntensity,
                averageRepetitions: averageRepetitions + that.averageRepetitions,
                averageWeight: averageWeight + that.averageWeight,
                averageDuration: averageDuration + that.averageDuration
            )
        }
        
        ///
        /// Divides ``self`` by ``const``
        /// - parameter const: the constant to divide the values by
        /// - returns: the updated value
        ///
        private func divideBy(const: Double) -> Average {
            return Average(
                count: count,
                averageIntensity: averageIntensity / const,
                averageRepetitions: Int(Double(averageRepetitions) / const),
                averageWeight: averageWeight / const,
                averageDuration: averageDuration / const
            )
        }
    }
    
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
    
    enum AggregateKey {
        case Everything
        case Type(type: MKExerciseType)
    }
    
    ///
    /// Computes the averages for the ``MRManagedClassifiedExercise`` in the given ``managedObjectContext``,
    /// whose ``exerciseId`` starts with ``exerciseIdPrefix``, dropping the ``exerciseIdPrefix`` from the
    /// exerciseIds returned.
    /// - parameter managedObjectContext: the MOC
    /// - parameter exerciseIdPrefix: the exercise id prefix to match (i.e. back/, arms/)
    /// - returns: the average for the last 100 sessions
    ///
    static func averages(inManagedObjectContext managedObjectContext: NSManagedObjectContext, forExerciseType type: MKExerciseType?) -> [Average] {
        let fetchLimit = 100
        let entity = NSEntityDescription.entityForName("MRManagedClassifiedExercise", inManagedObjectContext: managedObjectContext)
        let exerciseId = entity!.propertiesByName["exerciseId"]!

        let fetchRequest = NSFetchRequest(entityName: "MRManagedClassifiedExercise")
        fetchRequest.propertiesToFetch = [exerciseId, countByEntity, averageFor("duration"), averageFor("cdWeight"), averageFor("cdIntensity"), averageFor("cdRepetitions")]
        fetchRequest.propertiesToGroupBy = [exerciseId]
        if let type = type {
            let predicates = type.prefixes.map { NSPredicate(format: "exerciseId LIKE %@", $0 + "*") }
            fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "exerciseSession.start", ascending: false)]
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        fetchRequest.fetchLimit = fetchLimit
        
        if let result = (try? managedObjectContext.executeFetchRequest(fetchRequest)) as? [NSDictionary] {
            var averages: [MKExerciseId : [Average]] = [:]
            for entry in result {
                let exerciseId = entry["exerciseId"] as! String
                let matches = type.map { $0.containsExerciseId(exerciseId) } ?? true
                if matches {
                    let average = Average(
                        count: (entry["count"] as! NSNumber).integerValue,
                        averageIntensity: (entry["cdIntensity"] as? NSNumber)?.doubleValue ?? 0,
                        averageRepetitions: (entry["cdRepetitions"] as! NSNumber).integerValue,
                        averageWeight: (entry["cdWeight"] as? NSNumber)?.doubleValue ?? 0,
                        averageDuration: (entry["duration"] as? NSNumber)?.doubleValue ?? 0
                    )
                    
                    if let existingAverages = averages[exerciseId] {
                        averages[exerciseId] = existingAverages + [average]
                    } else {
                        averages[exerciseId] = [average]
                    }
                }
            }
            return averages.values.map { averages in
                let z = Average.zero()
                let reduced = averages.reduce(z) { $0.plus($1) }
                return reduced.divideBy(Double(averages.count))
            }
        }
        
        return []
    }

}