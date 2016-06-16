import Foundation

extension String {
    
    func localized(_ args: CVarArg...) -> String {
        let s = NSLocalizedString(self, comment: self)
        if args.count == 0 {
            return s
        } else {
            return String(format: s, arguments: args)
        }
    }
    
}
