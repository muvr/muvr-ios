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
                return "setup_\(id)"
            }
            // Find Exercise label
            for (id, _, offset, duration, _) in exercisesWithLabels where sampleBelongsTo(offset, duration: duration) {
                return id
            }
            return nil
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
                result.appendASCIIString("no_exercise")
            }
            result.appendASCIIString("\n")
        }
        return result
    }

}
