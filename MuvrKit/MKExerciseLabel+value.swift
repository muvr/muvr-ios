extension MKExerciseLabel {

    var value: Double {
        switch self {
        case .Weight(let w): return w
        case .Repetitions(let r): return Double(r)
        case .Intensity(let i): return i
        }
    }

}