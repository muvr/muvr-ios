import MuvrKit
import CoreData

extension MRManagedExerciseScalarLabel {

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
    /// Generates the ``NSFetchRequest`` that computes average values for each exercise
    ///  - parameter inManagedObjectContext: the CoreData managed object context to be use for the request
    ///  - parameter aggregate: the ``MRAggregate`` used to filter the exercise labels
    ///
    private static func analyticRequest(inManagedObjectContext managedObjectContext: NSManagedObjectContext, aggregate: MRAggregate) -> NSFetchRequest {
        let labelDescriptors = aggregate.labelsDescriptors
        let fetchLimit = 100 * labelDescriptors.count
    
        let entity = NSEntityDescription.entityForName("MRManagedExerciseScalarLabel", inManagedObjectContext: managedObjectContext)
        let exerciseId = NSExpressionDescription()
        exerciseId.name = "exercise.id"
        exerciseId.expression = NSExpression(forKeyPath: "exercise.id")
        exerciseId.expressionResultType = NSAttributeType.StringAttributeType
        let scalarType = entity!.propertiesByName["type"]!
    
        let fetchRequest = NSFetchRequest(entityName: (entity?.name)!)
        fetchRequest.propertiesToFetch = [exerciseId, scalarType, countByEntity, averageFor("exercise.duration"), averageFor("value")]
        fetchRequest.propertiesToGroupBy = [exerciseId, scalarType]
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "exercise.session.start", ascending: false)]
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        fetchRequest.fetchLimit = fetchLimit
        
        switch aggregate {
        case .Exercises(let muscleGroup):
            // exerciseId LIKE *:%@*
            fetchRequest.predicate = NSPredicate(format: "exercise.id LIKE %@ AND type IN %@", "*:" + muscleGroup.id + "*", labelDescriptors.map { $0.id })
        case .MuscleGroups(let type):
            // exerciseId LIKE %@:*
            fetchRequest.predicate = NSPredicate(format: "exercise.id LIKE %@ AND type IN %@", type.id + "*", labelDescriptors.map { $0.id })
        case .Types:
            fetchRequest.predicate = NSPredicate(format: "type IN %@", labelDescriptors.map { $0.id })
        }
        
        return fetchRequest
    }
    
    ///
    /// Compute a function that returns the ``MRAggregateKey``s for a given exercise id
    ///  - parameter: aggregate: the ``MRAggregate`` used to compute the aggregate key for a given exercise id
    ///
    private static func keyExtractor(aggregate: MRAggregate) -> (String -> [MRAggregateKey]) {
        switch aggregate {
        case .Exercises:
            return { exerciseId in
                return [.Exercise(id: exerciseId)]
            }
        case .MuscleGroups:
            return { exerciseId in
                if let (_, mgs, _) = MKExercise.componentsFromExerciseId(exerciseId) {
                    let keys: [MRAggregateKey] = mgs.flatMap { name in
                        guard let mg = MKMuscleGroup(id: name) else { return nil }
                        return .MuscleGroup(muscleGroup: mg)
                    }
                    return keys.isEmpty ? [.Exercise(id: exerciseId)] : keys
                }
                return [.NoMuscleGroup]
            }
        case .Types:
            return { exerciseId in
                return [MRAggregateKey.ExerciseType(exerciseType: MKExerciseTypeDescriptor(exerciseId: exerciseId)!)]
            }
        }
    }
    
    ///
    /// Computes the average label values for the given aggregate
    ///
    static func averages(inManagedObjectContext managedObjectContext: NSManagedObjectContext, aggregate: MRAggregate) -> [(MRAggregateKey, MRAverage)] {
        let fetchRequest = analyticRequest(inManagedObjectContext: managedObjectContext, aggregate: aggregate)
        guard let result = (try? managedObjectContext.executeFetchRequest(fetchRequest)) as? [NSDictionary] else { return [] }
        
        let keysForExerciseId = keyExtractor(aggregate)
        
        // result contains one entry per (exerciseId, label type)
        var averages: [MRAggregateKey : [String : MRAverage]] = [:]
        for entry in result {
            let exerciseId = entry["exercise.id"] as! String
            let label = aggregate.labelsDescriptors.filter { $0.id == (entry["type"] as! String) }.first!
            let value = (entry["value"] as! NSNumber).doubleValue
            let count = (entry["count"] as! NSNumber).integerValue
            let duration = (entry["exercise.duration"] as! NSNumber).doubleValue
            
            keysForExerciseId(exerciseId).forEach { key in
                if averages[key] == nil { averages[key] = [:] }
                let newAverage = averages[key]?[exerciseId]?.with(value, forLabel: label) ??
                    MRAverage(count: count, averages: [label:value], averageDuration: duration)
                averages[key]?[exerciseId] = newAverage
            }
        }
        return averages.map { k, averages in
            let z = MRAverage.zero(aggregate.labelsDescriptors)
            let reduced = averages.values.reduce(z) { $0.plus($1) }
            return (k, reduced.divideBy(Double(averages.count)))
        }
    }
    
}