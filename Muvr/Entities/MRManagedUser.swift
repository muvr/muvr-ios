import Foundation
import CoreData

class MRManagedUser: NSManagedObject {
    
    static func insertNewObject(inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedUser {
        let mo = NSEntityDescription.insertNewObjectForEntityForName("MRManagedUser", inManagedObjectContext: managedObjectContext) as! MRManagedUser
        return mo
    }
    
    static func defaultUser(inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedUser? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedUser")
        fetchRequest.fetchLimit = 1
        guard let users = try? managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedUser] where !users.isEmpty
            else { return nil }
        return users[0]
    }
    
    static func userByLogin(email email: String, password: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext)  -> MRManagedUser? {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedUser")
        fetchRequest.predicate = NSPredicate(format: "(email = %@ AND password=%@)", email, password)
        fetchRequest.fetchLimit = 1
        guard let users = try? managedObjectContext.executeFetchRequest(fetchRequest) as! [MRManagedUser] where !users.isEmpty
            else { return nil }
        return users[0]
    }

}
