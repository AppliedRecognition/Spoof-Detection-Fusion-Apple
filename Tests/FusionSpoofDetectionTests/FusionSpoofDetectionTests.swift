import XCTest
import VerIDCommonTypes
@testable import FusionSpoofDetection

final class FusionSpoofDetectionTests: XCTestCase {
    
    var spoofDetection: FusionSpoofDetection!
    lazy var testImage: Image? = {
        guard let imageUrl = Bundle.module.url(forResource: "face_on_iPad_001", withExtension: "jpg", subdirectory: nil) else {
            return nil
        }
        guard let imageData = try? Data(contentsOf: imageUrl) else {
            return nil
        }
        guard let cgImage = UIImage(data: imageData)?.cgImage else {
            return nil
        }
        guard let image = Image(cgImage: cgImage, orientation: .up, depthData: nil) else {
            return nil
        }
        return image
    }()
    let testImageFaceRect = CGRect(x: 1020, y: 1420, width: 1070, height: 1350)
    
    override func setUpWithError() throws {
        self.spoofDetection = try self.createSpoofDetection()
    }
    
    func testDetectSpoofInCloud() async throws {
        guard let image = self.testImage else {
            XCTFail()
            return
        }
        let result = try await self.spoofDetection.detectSpoofUsingFusionInImage(image, regionOfInterest: self.testImageFaceRect)
        XCTAssertNotNil(result.fused)
        XCTAssertGreaterThanOrEqual(result.fused!, self.spoofDetection.confidenceThreshold)
    }
    
    private func createSpoofDetection() throws -> FusionSpoofDetection {
        guard let configUrl = Bundle.module.url(forResource: "config", withExtension: "json") else {
            throw XCTSkip()
        }
        guard let configData = try? Data(contentsOf: configUrl) else {
            throw XCTSkip()
        }
        guard let config = try? JSONDecoder().decode(Config.self, from: configData) else {
            throw XCTSkip()
        }
        guard let url = URL(string: config.url) else {
            throw XCTSkip()
        }
        return try FusionSpoofDetection(apiKey: config.apiKey, url: url)
    }
}

fileprivate struct Config: Decodable {
    
    let apiKey: String
    let url: String
    
}
