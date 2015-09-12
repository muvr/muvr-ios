import Foundation

extension Array {
    
    ///
    /// Finds the first element that satisfies ``predicate``
    ///
    func find(predicate: Element -> Bool) -> Element? {
        for e in self {
            if predicate(e) { return e }
        }
        
        return nil
    }
    
    ///
    /// Takes the specified ``count`` of elements from this
    ///
    func take(n: Int) -> [Element] {
        if n > count { return self }
        return Array(self[0..<n])
    }
    
    ///
    /// Constructs a new array, which contains the original elements
    /// tupled with their index.
    ///
    func zipWithIndex() -> [(Int, Element)] {
        var r: [(Int, Element)] = []
        for i in 0..<self.count {
            r += [(i, self[i])]
        }
        return r
    }
        
}