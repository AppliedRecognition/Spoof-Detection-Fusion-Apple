// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import UIKit
import FASnetSpoofDetectionCore
import SpoofDeviceDetectionCore
import VerIDCommonTypes

public class FusionSpoofDetection: SpoofDetection {
    
    public var confidenceThreshold: Float = 0.5
    
    let apiKey: String
    let url: URL
    let fasNetSpoofDetection: FASnetSpoofDetectionCore
    let spoofDeviceDetection: SpoofDeviceDetectionCore
    
    public init(apiKey: String, url: URL) throws {
        self.apiKey = apiKey
        self.url = url
        self.fasNetSpoofDetection = try FASnetSpoofDetectionCore()
        self.spoofDeviceDetection = try SpoofDeviceDetectionCore()
    }
    
    public func detectSpoofInImage(_ image: VerIDCommonTypes.Image, regionOfInterest: CGRect?) async throws -> Float {
        guard let roi = regionOfInterest else {
            return 0
        }
        let responseBody = try await self.detectSpoofUsingFusionInImage(image, regionOfInterest: roi)
        if let fusedScore = responseBody.fused {
            return fusedScore
        } else if let spoofDeviceScore = responseBody.spoof_devices.map({ $0.confidence }).max() {
            return max(responseBody.fasnet, spoofDeviceScore)
        } else {
            return responseBody.fasnet
        }
    }
    
    func detectSpoofUsingFusionInImage(_ image: Image, regionOfInterest roi: CGRect) async throws -> SpoofDetectionResult {
        let transform = self.spoofDeviceDetection.createImageTransformForImageSize(image.size)
        let body = try self.createRequestBody(image: image, roi: roi, transform: transform)
        let json = try JSONEncoder().encode(body)
        var request = URLRequest(url: self.url)
        request.httpMethod = "POST"
        request.setValue(self.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.upload(for: request, from: json)
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode < 400 else {
            throw FusionSpoofDetectionError.networkRequestFailed(url: self.url)
        }
        let responseBody = try JSONDecoder().decode(SpoofDetectionResult.self, from: data)
        let reverseTransform = self.spoofDeviceDetection.createImageTransformForImageSize(image.size).inverted()
        let spoofDevices = responseBody.spoof_devices.map {
            DetectedSpoof(boundingBox: $0.boundingBox.applying(reverseTransform), confidence: $0.confidence)
        }
        return SpoofDetectionResult(fasnet: responseBody.fasnet, spoof_devices: spoofDevices, fused: responseBody.fused)
    }
    
    func scaleImageForSpoofDeviceDetector(_ image: Image, transform: CGAffineTransform) -> UIImage? {
        guard let cgImage = image.toCGImage() else {
            return nil
        }
        let spoofDeviceDetectionImageSize = CGSize(width: self.spoofDeviceDetection.imageLongerSideLength, height: self.spoofDeviceDetection.imageLongerSideLength)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let rect = CGRect(origin: .zero, size: image.size).applying(transform)
        return UIGraphicsImageRenderer(size: spoofDeviceDetectionImageSize, format: format).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: spoofDeviceDetectionImageSize))
            UIImage(cgImage: cgImage).draw(in: rect)
        }
    }
    
    private func createRequestBody(image: Image, roi: CGRect, transform: CGAffineTransform) throws -> RequestBody {
        let fasnet = try self.createFasNetImages(image: image, roi: roi)
        guard let spoofDeviceImage = self.scaleImageForSpoofDeviceDetector(image, transform: transform), let spoofDeviceImageData = spoofDeviceImage.jpegData(compressionQuality: 1.0) else {
            throw FusionSpoofDetectionError.imageProcessingFailed
        }
        let faceRect = roi.applying(transform)
        let spoofDeviceBody = SpoofDeviceBody(image: spoofDeviceImageData, roi: Rect(cgRect: faceRect))
        return RequestBody(fasnet: fasnet, spoof_device: spoofDeviceBody)
    }
    
    private func createFasNetImages(image: Image, roi: CGRect) throws -> [Data] {
        let fasNetImages = try self.fasNetSpoofDetection.createInferenceImagesFromImage(image, roi: roi)
        return fasNetImages.compactMap {
            UIImage(cgImage: $0).jpegData(compressionQuality: 1.0)
        }
    }
    
}

fileprivate struct Rect: Encodable {
    let x: Float
    let y: Float
    let width: Float
    let height: Float
    init(cgRect: CGRect) {
        self.x = Float(cgRect.minX)
        self.y = Float(cgRect.minY)
        self.width = Float(cgRect.width)
        self.height = Float(cgRect.height)
    }
}

fileprivate struct FasnetBody: Encodable {
    let images: [Data]
}

fileprivate struct SpoofDeviceBody: Encodable {
    let image: Data
    let roi: Rect
}

fileprivate struct RequestBody: Encodable {
    let fasnet: FasnetBody
    let spoof_device: SpoofDeviceBody
    init(fasnet: [Data], spoof_device: SpoofDeviceBody) {
        self.fasnet = FasnetBody(images: fasnet)
        self.spoof_device = spoof_device
    }
}

struct SpoofDetectionResult: Codable {
    let fasnet: Float
    let spoof_devices: [DetectedSpoof]
    let fused: Float?
}
