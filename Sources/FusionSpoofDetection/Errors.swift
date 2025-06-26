//
//  Errors.swift
//  
//
//  Created by Jakub Dolejs on 26/06/2025.
//

import Foundation

public enum FusionSpoofDetectionError: LocalizedError {
    case networkRequestFailed(url: URL), imageProcessingFailed
    
    public var errorDescription: String? {
        switch self {
        case .networkRequestFailed(url: let url):
            return NSLocalizedString("Network request to \(url) failed", comment: "")
        case .imageProcessingFailed:
            return NSLocalizedString("Image processing failed", comment: "")
        }
    }
}
