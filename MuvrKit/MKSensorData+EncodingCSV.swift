import Foundation

private extension NSMutableData {
    
    func appendASCIIString(s: String) {
        appendData(s.dataUsingEncoding(NSASCIIStringEncoding)!)
    }
    
}

public extension MKSensorData {
    
    public func encodeAsCsv(labelledExercises labelledExercises: [MKLabelledExercise]) -> NSData {
        // export data in CSV format: alwx,alwy,alwz,...,hr,...[,L,I,W,R]
        // alw: Accelerometer left wrist
        // hr: Heart rate
        // L: label
        // I: Intensity
        // W: weight
        // R: repetitions
        
        func findLabel(row: Int) -> MKLabelledExercise? {
            let now = start + (Double(row) / Double(samplesPerSecond))
            
            func sampleBelongsTo(label: MKLabelledExercise) -> Bool {
                let start = label.start.timeIntervalSinceReferenceDate
                let end = start + label.duration
                return start <= now && now < end
            }
            for l in labelledExercises where sampleBelongsTo(l) {
                return l
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
            if let l = findLabel(row) {
                result.appendASCIIString("\(l.exerciseId),")
                result.appendASCIIString("\(l.intensityLabel),")
                result.appendASCIIString("\(l.weightLabel),")
                result.appendASCIIString("\(l.repetitionsLabel)")
            } else {
                result.appendASCIIString(",,,")
            }
            result.appendASCIIString("\n")
        }
        return result
    }
    
}