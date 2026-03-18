//
// TieraVPN.swift
// TieraVPNKit
//
// Copyright © 2025 Dmitry Ulyanov
//

import Foundation
import Swift
import SwiftyXrayCore

/// Main wrapper class for TieraVPN functionality
public class TieraVPN {
  /// Allocates the specified number of free ports
  /// - Parameter count: Number of ports to allocate
  /// - Returns: Array of allocated port numbers
  /// - Throws: TieraVPNError if port allocation fails
  public static func getFreePorts(_ count: Int) throws -> [Int] {
    let base64JsonResponse = LibSwiftyXRayGetFreePorts(count)
    let portsResponse = try TieraVPNPortsResponse(base64String: base64JsonResponse)
    if let ports = portsResponse.data?.ports {
      return ports
    } else {
      throw TieraVPNError.invalidResponse(base64JsonResponse)
    }
  }
  
  /// Runs TieraVPN with the specified configuration.
  /// Run this method only if you have your own socks5 proxy setup or any other inbound.
  ///
  /// - Parameters:
  ///   - dataDir: Directory for TieraVPN data files
  ///   - configPath: Path to the TieraVPN configuration file
  /// - Throws: TieraVPNError if TieraVPN fails to start
  public static func run(dataDir: String, configPath: String) throws {
    let jsonRequest = try JSONEncoder().encode(TieraVPNRunRequest(datDir: dataDir, configPath: configPath))
    let base64JsonResponse = LibSwiftyXRayRunXRay(jsonRequest.base64EncodedString())
    
    let runResponse = try TieraVPNBoolResponse(base64String: base64JsonResponse)
    if !runResponse.success {
      throw TieraVPNError.invalidResponse(base64JsonResponse)
    }
  }
  
  /// Stops the running TieraVPN instance
  /// - Throws: TieraVPNError if stopping fails
  public static func stop() throws {
    let base64JsonResponse = LibSwiftyXRayStopXRay()
    let runResponse = try TieraVPNBoolResponse(base64String: base64JsonResponse)
    if !runResponse.success {
      throw TieraVPNError.invalidResponse(base64JsonResponse)
    }
  }
  
  /// Gets the current TieraVPN version
  /// - Returns: Version string
  /// - Throws: TieraVPNError if version retrieval fails
  public static func xrayVersion() throws -> String {
    let base64JsonResponse = LibSwiftyXRayXRayVersion()
    let runResponse = try TieraVPNVersionResponse(base64String: base64JsonResponse)
    guard let version = runResponse.data else {
      throw TieraVPNError.invalidResponse(base64JsonResponse)
    }
    
    if !runResponse.success {
      throw TieraVPNError.invalidResponse(base64JsonResponse)
    }
    
    return version
  }
  
  /// Converts an TieraVPN share link URL to JSON configuration
  /// - Parameter url: Share link URL to convert
  /// - Returns: JSON configuration string
  /// - Throws: TieraVPNError if conversion fails
  public static func xrayShareLinkToJson(url: String) throws -> String {
    let base64JsonResponse = LibSwiftyXRayConvertShareLinksToXRayJson(Data(url.utf8).base64EncodedString())
    
    guard let jsonResponse = base64JsonResponse.fromBase64(),
          let respData = jsonResponse.data(using: .utf8) else {
      throw TieraVPNError.invalidResponse(base64JsonResponse)
    }
    
    guard let json = try JSONSerialization.jsonObject(with: respData, options: []) as? [String: Any] else {
      throw TieraVPNError.invalidResponse(base64JsonResponse)
    }
    
    guard (json["success"] as? Bool) == true else {
      throw TieraVPNError.invalidResponse(json.description)
    }
    
    guard let nestedObj = json["data"] as? Dictionary<String, Any> else {
      throw TieraVPNError.invalidResponse(json.description)
    }
    
    guard let dt = try? JSONSerialization.data(withJSONObject: nestedObj),
          let str = String(data: dt, encoding: .utf8) else {
      throw TieraVPNError.invalidResponse(base64JsonResponse)
    }
    
    return str
  }
}
