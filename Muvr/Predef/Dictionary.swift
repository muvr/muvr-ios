import Foundation

extension Dictionary {
    
    ///
    /// Return the session stats as a list of tuples, ordered by the key
    ///
    func toList() -> [(Key, Value)] {
        var r: [(Key, Value)] = []
        for (k, v) in self {
            let tuple = [(k, v)]
            r += tuple
        }
        return r
    }
    
    ///
    /// Updates this by looking up value under ``key``, applying ``update`` to it if it exists,
    /// else setting ``key`` to be ``notFound``
    ///
    mutating func updated(key: Key, notFound: Value, update: Value -> Value) -> Void {
        if let x = self[key] {
            self[key] = update(x)
        } else {
            self[key] = notFound
        }
    }
    
    ///
    /// Updates this by looking up value under ``key`` and applying ``update`` to it.
    ///
    mutating func updated(key: Key, update: Value -> Value) -> Void {
        if let x = self[key] {
            self[key] = update(x)
        }
    }
    
    ///
    /// Returns a new dictionary created by mapping values with ``f``.
    ///
    func flatMapValues<That>(f: Value -> That?) -> [Key : That] {
        var r = [Key : That](minimumCapacity: self.count)
        for (k, v) in self {
            if let value = f(v) {
                r[k] = value
            }
        }
        return r
    }
    
    ///
    /// Maps over this dictionary, returning a new dictionary with mapped keys 
    ///
    func map<K, V>(f: (Key, Value) -> (K, V)) -> [K:V] {
        var r = [K:V](minimumCapacity: self.count)
        for (ok, ov) in self {
            let (nk, nv) = f(ok, ov)
            r[nk] = nv
        }
        return r
    }

}
