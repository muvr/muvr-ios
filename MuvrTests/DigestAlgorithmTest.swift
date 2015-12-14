import Foundation
import XCTest
@testable import Muvr

class DigestAlgorithmTest: XCTestCase {
    
    func testHash() {
        let data = "This is a test"
    
        let expectedMD5 = "ce114e4501d2f4e2dcea3e17b546f339"
        let md5 = String(strToHash: data, algo: .MD5)
        XCTAssertEqual(expectedMD5, md5)
        
        let expectedSHA256 = "c7be1ed902fb8dd4d48997c6452f5d7e509fbcdbe2808b16bcf4edce4c07d14e"
        let sha256 = String(strToHash: data, algo: .SHA256)
        XCTAssertEqual(expectedSHA256, sha256)
    }
    
    func testSign() {
        let key = "AWS4wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
        let data = "This is a test"
        
        let expectedMD5 = "4c3740d7f587afb92854acd0e8090906"
        let md5 = String(strToSign: data, algo: .MD5, key: key)
        XCTAssertEqual(expectedMD5, md5)
        
        let expectedSHA256 = "34eac1140c61af8a6c17277759e216588be35bfbe26639a0b01682f1ccd73eb8"
        let sha256 = String(strToSign: data, algo: .SHA256, key: key)
        XCTAssertEqual(expectedSHA256, sha256)
    }
    
}
