import Foundation

extension Result {
    
    func getOrUnit(r: V -> Void) -> Void {
        func loggingError(err: NSError) -> Void {
            NSLog("Ignoring error %@", err)
        }

        cata(loggingError, r: r)
    }
    
}
