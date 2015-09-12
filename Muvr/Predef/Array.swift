import Foundation

extension Array {
    
    mutating func removeObject<U: Equatable>(object: U) {
        var index: Int?
        for (idx, objectToCompare) in self.enumerate() {
            if let to = objectToCompare as? U {
                if object == to {
                    index = idx
                }
            }
        }
        
        if(index != nil) {
            self.removeAtIndex(index!)
        }
    }
    
    ///
    /// Returns the tail of this array
    ///
    var tail: [Element] {
        if self.isEmpty { return [] }
        return Array(self[1..<count])
    }
    
    ///
    /// Returns the first element as array of one element
    ///
    var firsts: [Element] {
        if self.isEmpty { return [] }
        return [self[0]]
    }
    
    ///
    /// fold left
    ///
    func foldLeft<B>(zero: B, f: (Element, B) -> B) -> B {
        var result = zero
        for x in self {
            result = f(x, result)
        }
        return result
    }

    ///
    /// Returns the index of the first element that satisfies ``predicate``
    ///
    func indexOf(predicate: Element -> Bool) -> Int? {
        for (i, e) in self.enumerate() {
            if predicate(e) { return i }
        }
        return nil
    }
    
    
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
    /// Apply the function ``f`` to every element
    ///
    func forEach(f: Element -> Void) -> Void {
        for e in self { f(e) }
    }
    
    ///
    /// Returns ``true`` if ``predicate`` evaluates to ``true`` for all elements.
    ///
    func forAll(predicate: Element -> Bool) -> Bool {
        for e in self {
            if !predicate(e) { return false }
        }
        
        return true
    }
    
    func flatMap<B>(transform: Element -> B?) -> [B] {
        var result: [B] = []
        for e in self {
            if let b = transform(e) { result += [b] }
        }
        return result
    }
    
    ///
    /// Takes the specified ``count`` of elements from this
    ///
    func take(n: Int) -> [Element] {
        if n > count { return self }
        return Array(self[0..<n])
    }
    
    ///
    /// Returns ``true`` if the ``predicate`` evalues to ``true`` for at least
    /// one element in this array
    ///
    func exists(predicate: Element -> Bool) -> Bool {
        return find(predicate) != nil
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