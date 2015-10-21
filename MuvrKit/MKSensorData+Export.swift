import Foundation

extension MKSensorData {
    
    func exportAsCsv(labels: [(MKTimestamp, MKTimestamp, String)]) -> NSData {
        // alwx,alwy,alwz,...,hr,...
        // x,y,z,h[,L,I,W]
        
        let result = NSMutableData()
        (0..<rowCount).forEach { row in
            
            (0..<dimension).forEach { col in
                let ofs = col + (row * dimension)
                let dataForSomethingString = "somestring".dataUsingEncoding(NSASCIIStringEncoding)!
                result.appendData(dataForSomethingString)
            }
            
        }
        
        return result
    }
    
}