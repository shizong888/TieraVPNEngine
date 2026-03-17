//
// TieraVPNResponses.swift
// TieraVPNWrapper
//
// Copyright © 2025 Dmitry Ulyanov
//

import Foundation

/// Generic response wrapper for TieraVPN library responses
struct TieraVPNResponse<T: Decodable>: Decodable {
  let success: Bool
  let data: T?
  
  init(base64String: String) throws {
    let plainStr = base64String.fromBase64() ?? ""
    let selfCopy = try JSONDecoder().decode(TieraVPNResponse<T>.self, from: plainStr.data(using: .utf8) ?? Data())
    success = selfCopy.success
    data = selfCopy.data
  }
}

/// Response body for port allocation requests
struct TieraVPNPortsResponseBody: Codable {
  let ports: [Int]
}

/// Request structure for running TieraVPN
struct TieraVPNRunRequest: Codable {
  let datDir: String
  let configPath: String
  
  enum CodingKeys: String, CodingKey {
    case datDir = "datDir"
    case configPath = "configPath"
  }
}

// Type aliases for specific response types
typealias TieraVPNPortsResponse = TieraVPNResponse<TieraVPNPortsResponseBody>
typealias TieraVPNVersionResponse = TieraVPNResponse<String>
typealias TieraVPNBoolResponse = TieraVPNResponse<Bool>
