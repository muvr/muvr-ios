import CoreData

extension MRManagedAchievement {

    /// the achievement date
    @NSManaged var date: Date
    /// the workout id (i.e. template id)
    @NSManaged var planId: String
    /// the workout name
    @NSManaged var planName: String
    /// the achievement name
    @NSManaged var name: String
    
}
