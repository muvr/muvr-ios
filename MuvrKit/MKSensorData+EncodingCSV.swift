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
                result.appendASCIIString("\(l.intensity),")
                result.appendASCIIString("\(l.weight),")
                result.appendASCIIString("\(l.repetitions)")
            } else {
                result.appendASCIIString(",,,")
            }
            result.appendASCIIString("\n")
        }
        return result
    }
    
    public static func initDataFromCSV(filename filename: String, ext: String) throws -> MKSensorData {
        func loadTextFiles(filename filename: String, ext: String, separator: NSCharacterSet) -> [String] {
            let fullPath = NSBundle.mainBundle().pathForResource(filename, ofType: ext)!
            func removeEmptyStr(arrStr: [String]) -> [String] {
                return arrStr
                    .filter {$0 != ""}
                    .map {$0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())}
            }
            do {
                let content = try String(contentsOfFile: fullPath, encoding: NSUTF8StringEncoding)
                return removeEmptyStr(content.componentsSeparatedByCharactersInSet(separator))
            } catch {
                return []
            }
        }
        
        let csvArr = loadTextFiles(filename: filename, ext: ext, separator: NSCharacterSet.newlineCharacterSet())
        let samples = csvArr.flatMap { line -> [Float] in
            let split = line.componentsSeparatedByString(",")
            let X = NSString(string: split[0]).floatValue
            let Y = NSString(string: split[1]).floatValue
            let Z = NSString(string: split[2]).floatValue
            return [X, Y, Z]
        }
        let types = [MKSensorDataType.Accelerometer(location: MKSensorDataType.Location.LeftWrist)]
        return try MKSensorData(types: types, start: 0, samplesPerSecond: UInt(50), samples: samples)
    }
    
}