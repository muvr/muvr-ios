import Foundation

public protocol MKExerciseRepository {
    
    /// All exercise ids
    var allExerciseIds: [MKExerciseId] { get }
 
    func exerciseIdsInExerciseType(type: MKExerciseType) -> [MKExerciseId]
    
    func exerciseTypeForExerciseId(id: MKExerciseId) -> MKExerciseType
    
}

//public extension MKExerciseRepository {
//    
//    /// All muscle groups for all exercises
//    var allMuscleGroups: [MKMuscleGroup] {
//        return muscleGroupsForExerciseIds(allExerciseIds)
//    }
//
//    public func exerciseIdsInMuscleGroup(muscleGroup: MKMuscleGroup) -> [MKExerciseId] {
//        allExerciseIds.map
//    }
//    
////    func muscleGroupsForExerciseId(id: MKExerciseId) -> [MKMuscleGroup] {
////        return muscleGroupsForExerciseIds([id])
////    }
////    
//    private func muscleGroupsForExerciseIds(ids: [MKExerciseId]) -> [MKMuscleGroup] {
//        var result: Set<MKMuscleGroup> = Set()
//        for type in ids.map(exerciseTypeForExerciseId) {
//            switch type {
//            case .ResistanceWholeBody: MKMuscleGroup.all.forEach { result.insert($0) }
//            case .ResistanceTargeted(let muscleGroups): muscleGroups.forEach { result.insert($0) }
//            case .Cardio: continue
//            }
//        }
//        return Array(result)
//    }
//    
//}

public extension MKExerciseRepository {

    var allTypes: [MKExerciseType] {
        return Array(Set(allExerciseIds.map(exerciseTypeForExerciseId)))
    }
    
//    func exerciseIdsInExerciseTypes(types: [MKExerciseType]) -> [MKExerciseId] {
//        var result: Set<MKExerciseId> = Set()
//        for type in types {
//            switch type {
//            case .ResistanceTargeted(let muscleGroups): muscleGroups.flatMap(exerciseIdsInMuscleGroup).forEach { result.insert($0) }
//            case .ResistanceWholeBody: MKMuscleGroup.all.flatMap(exerciseIdsInMuscleGroup).forEach { result.insert($0) }
//            case .Cardio: continue
//            }
//        }
//        
//        return Array(result)
//    }
    
}
