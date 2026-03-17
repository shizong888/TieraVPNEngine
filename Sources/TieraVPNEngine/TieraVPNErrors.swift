//
// TieraVPNErrors.swift
// TieraVPNWrapper
//
// Copyright © 2025 Dmitry Ulyanov
//

import Foundation

/// Errors that can occur during Tiera VPN Engine operations
public enum TieraVPNError: Error, LocalizedError {
  /// Invalid response received from Tiera VPN Engine
  case invalidResponse(String)

  /// Invalid Tiera VPN configuration provided
  case invalidConfig

  /// Failed to allocate a free port for SOCKS5
  case portAllocationError

  /// Tiera VPN tunnel setup error with detailed message
  case tunnelSetupError(String)

  /// Tiera VPN connection failed
  case tieraConnectionFailed(String)

  /// Tiera VPN network unreachable
  case tieraNetworkUnreachable

  /// Tiera VPN authentication required
  case tieraAuthenticationRequired

  /// Tiera VPN server unavailable
  case tieraServerUnavailable(String)

  public var errorDescription: String? {
    switch self {
    case .invalidResponse(let response):
      return "[Tiera VPN Engine] Invalid response: \(response)"
    case .invalidConfig:
      return "[Tiera VPN Engine] Invalid configuration provided"
    case .portAllocationError:
      return "[Tiera VPN Engine] Failed to allocate SOCKS5 port"
    case .tunnelSetupError(let message):
      return "[Tiera VPN Engine] Tunnel setup failed: \(message)"
    case .tieraConnectionFailed(let reason):
      return "[Tiera VPN Engine] Connection failed: \(reason)"
    case .tieraNetworkUnreachable:
      return "[Tiera VPN Engine] Network unreachable - check your internet connection"
    case .tieraAuthenticationRequired:
      return "[Tiera VPN Engine] Authentication required to establish connection"
    case .tieraServerUnavailable(let server):
      return "[Tiera VPN Engine] Server unavailable: \(server)"
    }
  }
}
