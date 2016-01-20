import CoreData
import MuvrKit

enum MRScalarRounder {

    case RoundInteger
    case NoRound
    case RoundClipToNorm
    case RoundWeight(propertySource: MKExercisePropertySource)
    
    var rounder: (Double, MKExercise.Id) -> Double {
        switch self {
        case .RoundInteger: return { value, exerciseId in
            return Double(Int(max(0, value)))
        }
        case .NoRound: return { value, exerciseId in
            max(0, value)
        }
        case .RoundClipToNorm: return { value, exerciseId in
            return min(1, max(0, value))
        }
        case .RoundWeight(let propertySource): return { value, exerciseId in
            for property in propertySource.exercisePropertiesForExerciseId(exerciseId) {
                if case .WeightProgression(let minimum, let step, let maximum) = property {
                    return MKScalarRounderFunction.roundMinMax(value, minimum: minimum, step: step, maximum: maximum)
                }
            }
            return max(0, value)
        }
        }
    }
    
}

extension MRManagedExerciseSession {
    
    private static let polynomialFittingWeight = "pfw"
    private static let polynomialFittingDuration = "pfd"
    private static let polynomialFittingIntensity = "pfi"
    private static let polynomialFittingRepetitions = "pfr"

    func injectPredictors(
        atLocation currentLocation: MRManagedLocation?,
        propertySource: MKExercisePropertySource,
        inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
            
        let weightPredictor = MKPolynomialFittingScalarPredictor(round: MRScalarRounder.RoundWeight(propertySource: propertySource).rounder)
        let durationPredictor = MKPolynomialFittingScalarPredictor(round: MRScalarRounder.NoRound.rounder)
        let intensityPredictor = MKPolynomialFittingScalarPredictor(round: MRScalarRounder.RoundClipToNorm.rounder)
        let repetitionsPredictor = MKPolynomialFittingScalarPredictor(round: MRScalarRounder.RoundInteger.rounder)
        
        if let p = MRManagedScalarPredictor.scalarPredictorFor(MRManagedExerciseSession.polynomialFittingWeight, location: currentLocation, sessionExerciseType: exerciseType, inManagedObjectContext: managedObjectContext) {
            weightPredictor.mergeJSON(p.data)
        }
        if let p = MRManagedScalarPredictor.scalarPredictorFor(MRManagedExerciseSession.polynomialFittingDuration, location: currentLocation, sessionExerciseType: exerciseType, inManagedObjectContext: managedObjectContext) {
            durationPredictor.mergeJSON(p.data)
        }
        if let p = MRManagedScalarPredictor.scalarPredictorFor(MRManagedExerciseSession.polynomialFittingIntensity, location: currentLocation, sessionExerciseType: exerciseType, inManagedObjectContext: managedObjectContext) {
            intensityPredictor.mergeJSON(p.data)
        }
        if let p = MRManagedScalarPredictor.scalarPredictorFor(MRManagedExerciseSession.polynomialFittingRepetitions, location: currentLocation, sessionExerciseType: exerciseType, inManagedObjectContext: managedObjectContext) {
            repetitionsPredictor.mergeJSON(p.data)
        }
        
        if let plan = MRManagedExercisePlan.planForExerciseType(exerciseType, location: currentLocation, inManagedObjectContext: managedObjectContext) {
            self.plan = plan.plan
        } else {
            self.plan = MKExercisePlan<MKExercise.Id>()
        }
        self.weightPredictor = weightPredictor
        self.durationPredictor = durationPredictor
        self.intensityPredictor = intensityPredictor
        self.repetitionsPredictor = repetitionsPredictor
    }
    
    func savePredictors(atLocation currentLocation: MRManagedLocation?, inManagedObjectContext managedObjectContext: NSManagedObjectContext) {
        MRManagedExercisePlan.upsert(plan, exerciseType: exerciseType, location: currentLocation, inManagedObjectContext: managedObjectContext)
        MRManagedScalarPredictor.upsertScalarPredictor(MRManagedExerciseSession.polynomialFittingWeight, location: currentLocation, sessionExerciseType: exerciseType, data: weightPredictor.json, inManagedObjectContext: managedObjectContext)
        MRManagedScalarPredictor.upsertScalarPredictor(MRManagedExerciseSession.polynomialFittingDuration, location: currentLocation, sessionExerciseType: exerciseType, data: durationPredictor.json, inManagedObjectContext: managedObjectContext)
        MRManagedScalarPredictor.upsertScalarPredictor(MRManagedExerciseSession.polynomialFittingIntensity, location: currentLocation, sessionExerciseType: exerciseType, data: intensityPredictor.json, inManagedObjectContext: managedObjectContext)
        MRManagedScalarPredictor.upsertScalarPredictor(MRManagedExerciseSession.polynomialFittingRepetitions, location: currentLocation, sessionExerciseType: exerciseType, data: repetitionsPredictor.json, inManagedObjectContext: managedObjectContext)
    }
    
}
