import CoreData

extension NSManagedObjectContext {

    func countForFetchRequest(_ request: NSFetchRequest<AnyObject>) -> Int? {
        var error: NSError?
        let count = self.count(for: request, error: &error)
        
        if error == nil { return count }
        else { return nil }
    }
    
}
