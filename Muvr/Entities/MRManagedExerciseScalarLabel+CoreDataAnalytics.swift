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
        count.expressionResultType = NSAttributeType.integer32AttributeType
        return count
    }()
    
    ///
    /// Expression description for ``average:`` of ``keyPath``.
    /// - parameter keyPath: the property's KP
    /// - returns: the expression description
    ///
    private static func averageFor(_ keyPath: String) -> NSExpressionDescription {
        let expr = NSExpressionDescription()
        expr.name = "\(keyPath)"
        expr.expression = NSExpression(forFunction: "average:", arguments: [NSExpression(forKeyPath: keyPath)])
        expr.expressionResultType = NSAttributeType.doubleAttributeType
        return expr
    }
    
    ///
    /// Generates the ``NSFetchRequest`` that computes average values for each exercise
    ///  - parameter inManagedObjectContext: the CoreData managed object context to be use for the request
    ///  - parameter aggregate: the ``MRAggregate`` used to filter the exercise labels
    ///
    private static func analyticRequest(inManagedObjectContext managedObjectContext: NSManagedObjectContext, aggregate: MRAggregate) -> NSFetchRequest<NSDictionary> {
        let labelDescriptors = aggregate.labelsDescriptors
        let fetchLimit = 100 * labelDescriptors.count
    
        let entity = NSEntityDescription.entity(forEntityName: "MRManagedExerciseScalarLabel", in: managedObjectContext)
        let exerciseId = NSExpressionDescription()
        exerciseId.name = "exercise.id"
        exerciseId.expression = NSExpression(forKeyPath: "exercise.id")
        exerciseId.expressionResultType = NSAttributeType.stringAttributeType
        let scalarType = entity!.propertiesByName["type"]!
    
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: (entity?.name)!)
        fetchRequest.propertiesToFetch = [exerciseId, scalarType, countByEntity, averageFor("exercise.duration"), averageFor("value")]
        fetchRequest.propertiesToGroupBy = [exerciseId, scalarType]
        fetchRequest.sortDescriptors = [SortDescriptor(key: "exercise.session.start", ascending: false)]
        fetchRequest.resultType = NSFetchRequestResultType.dictionaryResultType
        fetchRequest.fetchLimit = fetchLimit
        
        switch aggregate {
        case .exercises(let muscleGroup):
            // exerciseId LIKE *:%@*
            fetchRequest.predicate = Predicate(format: "exercise.id LIKE %@ AND type IN %@", "*:" + muscleGroup.id + "*", labelDescriptors.map { $0.id })
        case .muscleGroups(let type):
            // exerciseId LIKE %@:*
            fetchRequest.predicate = Predicate(format: "exercise.id LIKE %@ AND type IN %@", type.id + "*", labelDescriptors.map { $0.id })
        case .types:
            fetchRequest.predicate = Predicate(format: "type IN %@", labelDescriptors.map { $0.id })
        }
        
        return fetchRequest
    }
    
    ///
    /// Compute a function that returns the ``MRAggregateKey``s for a given exercise id
    ///  - parameter: aggregate: the ``MRAggregate`` used to compute the aggregate key for a given exercise id
    ///
    private static func keyExtractor(_ aggregate: MRAggregate) -> ((String) -> [MRAggregateKey]) {
        switch aggregate {
        case .exercises:
            return { exerciseId in
                return [.exercise(id: exerciseId)]
            }
        case .muscleGroups:
            return { exerciseId in
                if let (_, mgs, _) = MKExercise.componentsFromExerciseId(exerciseId) {
                    let keys: [MRAggregateKey] = mgs.flatMap { name in
                        guard let mg = MKMuscleGroup(id: name) else { return nil }
                        return .muscleGroup(muscleGroup: mg)
                    }
                    return keys.isEmpty ? [.exercise(id: exerciseId)] : keys
                }
                return [.noMuscleGroup]
            }
        case .types:
            return { exerciseId in
                return [MRAggregateKey.exerciseType(exerciseType: MKExerciseTypeDescriptor(exerciseId: exerciseId)!)]
            }
        }
    }
    
    ///
    /// Computes the average label values for the given aggregate
    ///
    static func averages(inManagedObjectContext managedObjectContext: NSManagedObjectContext, aggregate: MRAggregate) -> [(MRAggregateKey, MRAverage)] {
        let fetchRequest = analyticRequest(inManagedObjectContext: managedObjectContext, aggregate: aggregate)
        guard let result = try? managedObjectContext.fetch(fetchRequest) else { return [] }
        
        let keysForExerciseId = keyExtractor(aggregate)
        
        // result contains one entry per (exerciseId, label type)
        var averages: [MRAggregateKey : [String : MRAverage]] = [:]
        for entry in result {
            let exerciseId = entry["exercise.id"] as! String
            let label = aggregate.labelsDescriptors.filter { $0.id == (entry["type"] as! String) }.first!
            let value = (entry["value"] as! NSNumber).doubleValue
            let count = (entry["count"] as! NSNumber).intValue
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
