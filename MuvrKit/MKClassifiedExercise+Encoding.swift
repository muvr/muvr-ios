import Foundation

///
/// Adds encoding to the ``MKClassifiedExercise``
///
/// The Pebble format is:
///
/// ```
/// typedef uint8_t repetitions_t; // repetition count
/// typedef uint8_t intensity_t; // intensity in 0..100
/// typedef uint8_t confidence_t; // classification confidence in 0..100
/// typedef uint16_t weight_t; // weight in user units
///
/// #define UNK_REPETITIONS 255
/// #define UNK_INTENSITY 255
/// #define UNK_WEIGHT 65535
///
/// typedef struct __attribute__((__packed__)) {
///     char name[24];
///     confidence_t  confidence;       // 0..100
///     repetitions_t repetitions;      // 1..~50,  UNK_REPETITIONS for unknown
///     intensity_t   intensity;        // 1..100,  UNK_INTENSITY for unknown
///     weight_t      weight;           // 1..~500, UNK_WEIGHT for unknown
/// } resistance_exercise_t;
/// ```
///
public extension MKClassifiedExercise {
    
    /// The encoding target
    public enum Target {
        /// Encode for Pebble
        case Pebble
        // case AppleWatch
    }
    
    private func encode(string s: String, maximumLength: Int, encoding: NSStringEncoding, into data: NSMutableData) {
        var zero: UInt8 = 0
        if let encoded = s.dataUsingEncoding(encoding) {
            if encoded.length > maximumLength {
                data.appendData(encoded.subdataWithRange(NSRange(location: 0, length: maximumLength)))
            } else {
                data.appendData(encoded)
            }

            let padding = maximumLength - encoded.length
            if padding > 0 {
                (0..<padding).forEach { _ in data.appendBytes(&zero, length: 1) }
            }
        }
        data.appendBytes(&zero, length: 1)
    }

    public func encode(target: Target, localising f: MKExerciseId -> String) -> NSData {
        let data = NSMutableData()
        
        switch self {
        case .Resistance(let confidence, let exerciseId, duration: _, let repetitions, let intensity, let weight):
            let e = f(exerciseId)
            var c = UInt8(100 * confidence)
            var r = UInt8(repetitions ?? 0)
            var i = UInt8(100 * (intensity ?? 0))
            var w = UInt16(weight ?? 0)
            
            encode(string: e, maximumLength: 23, encoding: NSASCIIStringEncoding, into: data)
            data.appendBytes(&c, length: 1)
            data.appendBytes(&r, length: 1)
            data.appendBytes(&i, length: 1)
            data.appendBytes(&w, length: 2)
        }
        
        return data
    }
    
}
