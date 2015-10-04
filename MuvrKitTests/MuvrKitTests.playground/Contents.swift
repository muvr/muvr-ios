//: Playground - noun: a place where people can play

import UIKit
import XCPlayground
@testable import MuvrKit

func samplesWithStride(block: MKSensorData, stride: Int) -> [Int] {
    let sampleCount = block.samples.count / block.dimension
    // 1200 -> 400
    return (0..<sampleCount).map { i in
        return Int(1000 * block.samples[(stride - 1) + i * block.dimension])
    }
}

let block = MKSensorData.sensorData(types: [MKSensorDataType.Accelerometer(location: .LeftWrist)], samplesPerSecond: 100, generating: 400, withValue: .Sin1(period: 10))

samplesWithStride(block, stride: 1).map {$0}

samplesWithStride(block, stride: 2).map {$0}

samplesWithStride(block, stride: 3).map {$0}
