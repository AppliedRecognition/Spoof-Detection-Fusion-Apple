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
        try XCTSkipIf(Self.cloudAPIKey == nil, "Set VERID_CLOUD_API_KEY to run the tests that call the cloud service.")
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
        // Constructed with whatever key is available, including none. Only the cloud test needs a
        // real key, and it skips itself. Skipping here would skip the whole class, because
        // `setUpWithError` calls this.
        return try FusionSpoofDetection(apiKey: Self.cloudAPIKey ?? "", url: url)
    }

    /// The cloud API key, taken from the environment.
    ///
    /// It used to sit in `Resources/config.json`, which is committed — and this repository is
    /// public — so a live key for a metered service was republished in every clone. The endpoint
    /// stays in the committed config; the key does not. Without one the cloud tests skip, which
    /// is what a test needing a credential should do on a machine that has none.
    private static var cloudAPIKey: String? {
        ProcessInfo.processInfo.environment["VERID_CLOUD_API_KEY"].flatMap { $0.isEmpty ? nil : $0 }
    }
}

fileprivate struct Config: Decodable {
    
    let url: String
    
}
