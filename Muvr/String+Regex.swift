import Foundation

extension String {
    
    ///
    /// Returns a substring given a NSRange
    ///
    func substringWithRange(range: NSRange) -> String {
        let startIndex = self.startIndex
        let start = startIndex.advancedBy(range.location)
        let end = start.advancedBy(range.length)
        return self.substringWithRange(start..<end)
    }
    
    ///
    /// Matches against a regex and returns the matching groups
    ///
    func matchingGroups(pattern: NSRegularExpression, groups: Int) -> [String] {
        let matches = pattern.matchesInString(self, options: [], range: NSRange(location:0, length: self.characters.count))
        guard let match = matches.first else { return [] }
        return (0..<groups).map { i in
            return self.substringWithRange(match.rangeAtIndex(i + 1))
        }
    }
    
}
