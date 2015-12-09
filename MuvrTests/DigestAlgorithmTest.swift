import Foundation
import XCTest
@testable import Muvr

class DigestAlgorithmTest: XCTestCase {
    
    func testHash() {
        let data = "This is a test"
    
        let expectedMD5 = "ce114e4501d2f4e2dcea3e17b546f339"
        let md5 = String(strToHash: data, algo: .MD5)
        XCTAssertEqual(expectedMD5, md5)
        
        let expectedSHA1 = "a54d88e06612d820bc3be72877c74f257b561b19"
        let sha1 = String(strToHash: data, algo: .SHA1)
        XCTAssertEqual(expectedSHA1, sha1)
        
        let expectedSHA256 = "c7be1ed902fb8dd4d48997c6452f5d7e509fbcdbe2808b16bcf4edce4c07d14e"
        let sha256 = String(strToHash: data, algo: .SHA256)
        XCTAssertEqual(expectedSHA256, sha256)
        
        let expectedSHA512 = "a028d4f74b602ba45eb0a93c9a4677240dcf281a1a9322f183bd32f0bed82ec72de9c3957b2f4c9a1ccf7ed14f85d73498df38017e703d47ebb9f0b3bf116f69"
        let sha512 = String(strToHash: data, algo: .SHA512)
        XCTAssertEqual(expectedSHA512, sha512)
    }
    
    func testSign() {
        let key = "AWS4wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
        let data = "This is a test"
        
        let expectedMD5 = "4c3740d7f587afb92854acd0e8090906"
        let md5 = String(strToSign: data, algo: .MD5, key: key)
        XCTAssertEqual(expectedMD5, md5)
        
        let expectedSHA1 = "2f71a8c98f85ae0eb4f20386fb901daafe1a080f"
        let sha1 = String(strToSign: data, algo: .SHA1, key: key)
        XCTAssertEqual(expectedSHA1, sha1)
        
        let expectedSHA256 = "34eac1140c61af8a6c17277759e216588be35bfbe26639a0b01682f1ccd73eb8"
        let sha256 = String(strToSign: data, algo: .SHA256, key: key)
        XCTAssertEqual(expectedSHA256, sha256)
        
        let expectedSHA512 = "0b8e5ad17ad9bd67898656c49345043fe7d685ccdafa3e6bd7d252613d219f812cdc529860b92ebf8945e741dc9375c54e30be281f5961366804044ddc0e7ccf"
        let sha512 = String(strToSign: data, algo: .SHA512, key: key)
        XCTAssertEqual(expectedSHA512, sha512)
    }
    
}
