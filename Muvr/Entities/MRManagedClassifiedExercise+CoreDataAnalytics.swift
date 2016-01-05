import Foundation
import CoreData

extension MRManagedClassifiedExercise {
    
    static func summary(inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        // volume: sum(duration)
        // weight: sum(weight)
        // intensity: sum(intensity)
        // fitness: (weight * volume * intensity) / count
        
        func sumFor(keyPath: String) -> NSExpressionDescription {
            let expr = NSExpressionDescription()
            expr.name = "\(keyPath)Sum"
            expr.expression = NSExpression(forFunction: "sum:", arguments: [NSExpression(forKeyPath: keyPath)])
            expr.expressionResultType = NSAttributeType.DoubleAttributeType
            return expr
        }
        
        let count = NSExpressionDescription()
        count.name = "count"
        count.expression = NSExpression(forFunction: "count:", arguments: [NSExpression(forKeyPath: "duration")])
        count.expressionResultType = NSAttributeType.Integer32AttributeType
        
        let entity = NSEntityDescription.entityForName("MRManagedClassifiedExercise", inManagedObjectContext: managedObjectContext)
        let exerciseSession = entity!.propertiesByName["exerciseSession"]!
        
        let fetchRequest = NSFetchRequest(entityName: "MRManagedClassifiedExercise")
        fetchRequest.propertiesToFetch = [count, sumFor("duration"), sumFor("cdWeight"), sumFor("cdIntensity"), sumFor("cdRepetitions")]
        fetchRequest.propertiesToGroupBy = [exerciseSession]
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        
        let result = try? managedObjectContext.executeFetchRequest(fetchRequest)
        NSLog("\(result)")
    }
    

}