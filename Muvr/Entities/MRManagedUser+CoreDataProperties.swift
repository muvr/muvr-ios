import Foundation
import CoreData

extension MRManagedUser {
    
    @NSManaged var userId: String
    @NSManaged var firstname: String
    @NSManaged var lastname: String
    @NSManaged var email: String
    @NSManaged var password: String
    @NSManaged var signedIn: Bool
    
}
