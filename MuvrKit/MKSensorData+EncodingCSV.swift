import Foundation

private extension NSMutableData {

    func appendASCIIString(s: String) {
        appendData(s.dataUsingEncoding(NSASCIIStringEncoding)!)
    }

}

public extension MKSensorData {
    typealias ExerciseRow = (MKExercise.Id, MKExerciseType, NSTimeInterval, NSTimeInterval, [MKExerciseLabel])

    public func encodeAsCsv(exercisesWithLabels: [ExerciseRow]) -> NSData {
        // export data in CSV format: alwx,alwy,alwz,...,hr,...[,L,I,W,R]
        // alw: Accelerometer left wrist x, y, z
        // L: label

        let setupDuration: NSTimeInterval = 5.0

        func findLabel(row: Int) -> String? {
            let now = (Double(row) / Double(samplesPerSecond)) + self.delay!

            func sampleBelongsTo(offset: NSTimeInterval, duration: NSTimeInterval) -> Bool {
                let end = offset + duration
                return offset <= now && now < end
            }

            // Find setup label
            for (id, _, offset, _, _) in exercisesWithLabels where sampleBelongsTo(offset - setupDuration, duration: setupDuration) {
                return "setup_\(id),,," // 3 empty values for (weight, repetitions, intensity)
            }
            // Find Exercise label
            for (id, _, offset, duration, labels) in exercisesWithLabels where sampleBelongsTo(offset, duration: duration) {
                let (weight, repetitions, intensity) = expandLabels(labels)
                return "\(id),\(weight),\(repetitions),\(intensity)"
            }
            return nil
        }

        func expandLabels(labels: [MKExerciseLabel]) -> (Double, Int, Double) {
            var weight: Double = 0
            var repetitions: Int = 0
            var intensity: Double = 0
            labels.forEach { label in
                switch label {
                case .Weight(let value): weight = value
                case .Repetitions(let value): repetitions = value
                case .Intensity(let value): intensity = value
                }
            }
            return (weight, repetitions, intensity)
        }

        let result = NSMutableData()
        (0..<rowCount).forEach { row in
            (0..<dimension).forEach { col in
                let offset = col + row * dimension
                let point = samples[offset]
                result.appendASCIIString("\(point),")
            }
            if let label = findLabel(row) {
                result.appendASCIIString("\(label)")
            } else {
                result.appendASCIIString("no_exercise,,,") // 3 empty values for (weight, repetitions, intensity)
            }
            result.appendASCIIString("\n")
        }
        return result
    }

}
