import CoreData

extension MRManagedAchievement {

    ///
    /// Insert a new achievement (if it doesn't exists otherwise returns the existing one).
    ///
    /// - parameter name: the achievement name
    /// - parameter plan: the "achieved" exercise plan
    /// - parameter managedObjectContext: the MOC
    /// - returns: the inserted achievement (or the existing one)
    ///
    static func insertNewObject(_ achievement: MRAchievement, plan: MRManagedExercisePlan, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> MRManagedAchievement {
        let achievements = fetchAchievementsForPlan(plan, inManagedObjectContext: managedObjectContext)
        if let achievement = achievements.filter({ $0.name == achievement }).first { return achievement }
        
        let entity = NSEntityDescription.insertNewObject(forEntityName: "MRManagedAchievement", into: managedObjectContext) as! MRManagedAchievement
        entity.name = achievement
        entity.planId = plan.templateId ?? plan.id
        entity.planName = plan.name
        entity.date = Date()
        return entity
    }
    
    ///
    /// Loads the user's achievements for a given plan
    /// - parameter managedObjectContext: the MOC
    /// - returns: all the user's achievements ordered by date desc
    ///
    static func fetchAchievementsForPlan(_ plan: MRManagedExercisePlan, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> [MRManagedAchievement] {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedAchievement")
        fetchRequest.predicate = Predicate(format: "planId = %@", plan.templateId ?? plan.id)
        fetchRequest.sortDescriptors = [SortDescriptor(key: "date", ascending: false)]
        
        return (try? managedObjectContext.fetch(fetchRequest) as! [MRManagedAchievement]) ?? []
    }
    
    
    ///
    /// Loads the user's achievements
    /// - parameter managedObjectContext: the MOC
    /// - returns: all the user's achievements ordered by date desc
    ///
    static func fetchAchievements(inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> [MRManagedAchievement] {
        let fetchRequest = NSFetchRequest(entityName: "MRManagedAchievement")
        fetchRequest.sortDescriptors = [SortDescriptor(key: "date", ascending: false)]
        
        return (try? managedObjectContext.fetch(fetchRequest) as! [MRManagedAchievement]) ?? []
    }
    
}
