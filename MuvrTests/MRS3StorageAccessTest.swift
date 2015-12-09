import Foundation
import XCTest
@testable import Muvr

class MRS3StorageAccessTest: XCTestCase {

    func testS3KeyGeneration() {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYYMMdd"
        let date = formatter.dateFromString("20151207")!
        let awsKey = AWSKey(secret: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY", region: "eu-west-1", service: "s3")
        
        let expectedKey = "9b0e543b45e139c2a6166cad3e1194be4f587035d675f1f86194c666c285b48c"
        let (signingKey, expiration) = awsKey.generateKey(date)
        
        XCTAssertEqual(String(digest: signingKey), expectedKey)
        XCTAssertEqual("20151214", formatter.stringFromDate(expiration))
    }
    
    func testSigningRequest() {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYYMMdd"
        let date = formatter.dateFromString("20151207")!
        let awsKey = AWSKey(secret: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY", region: "eu-west-1", service: "s3")
        let (signingKey, _) = awsKey.generateKey(date)
        
        let s3 = MRS3StorageAccess(accessKey: "AKIAIOSFODNN7EXAMPLE", secretKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY")
        let request = s3.createRequest(method: "GET", path: "/", params: nil, payload: nil, date: date, signingKey: signingKey)
        
        let expectedHeaders = [
            "x-amz-content-sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
            "x-amz-date": "20151207T000000Z",
            "Authorization": "AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20151207/eu-west-1/s3/aws4_request,SignedHeaders=host;x-amz-content-sha256;x-amz-date,Signature=704a8c7abb9d9e2938aa7bf8884708e71b4d9757b396da681cde38939544ccd2"]
        
        request.allHTTPHeaderFields!.forEach { name, value in
            if let expectedValue = expectedHeaders[name] {
                XCTAssertEqual(expectedValue, value)
            }
        }
    }
    
}
