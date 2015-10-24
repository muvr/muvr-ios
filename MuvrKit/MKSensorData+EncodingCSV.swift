import Foundation

private extension NSMutableData {
    
    func appendASCIIString(s: String) {
        appendData(s.dataUsingEncoding(NSASCIIStringEncoding)!)
    }
    
}

public extension MKSensorData {
    
    public func encodeAsCsv(labelledExercises labelledExercises: [MKLabelledExercise]) -> NSData {
        // expord data in CSV format: alwx,alwy,alwz,...,hr,...[,L,I,W,R]
        // alw: Accelerometer left wrist
        // hr: Heart rate
        // L: label
        // I: Intensity
        // W: weight
        // R: repetitions
        
        func findLabel(row: Int) -> MKLabelledExercise? {
            let now = start + (Double(row) / Double(samplesPerSecond))
            
            func sampleBelongsTo(label: MKLabelledExercise) -> Bool {
                let start = label.start.timeIntervalSince1970
                let end = label.end.timeIntervalSince1970
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
                if let i = l.intensity { result.appendASCIIString("\(i)") }
                result.appendASCIIString(",")
                if let w = l.weight { result.appendASCIIString("\(w)") }
                result.appendASCIIString(",")
                if let r = l.repetitions { result.appendASCIIString("\(r)") }
                result.appendASCIIString(",")
            } else {
                result.appendASCIIString(",,,")
            }
            result.appendASCIIString("\n")
        }
        return result
    }
    
}