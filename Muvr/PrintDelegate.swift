import Foundation

class PrintDelegate: MRExerciseBlockDelegate {
    func exerciseBlockStarted() {
        println("BlockStarted")
    }
    
    func exerciseBlockEnded() {
        println("BlockEnded")
    }
}