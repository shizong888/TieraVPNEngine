//
// TieraConnectionService.swift
// TieraVPNEngine
//
// Copyright © 2026 Tiera VPN
// Custom connection service wrapper for Tiera VPN Engine
//

import Foundation
import NetworkExtension

/// Tiera VPN connection service - provides a high-level API for establishing VPN connections
@MainActor
public class TieraConnectionService {

  // MARK: - Properties

  private let tunnel: TieraVPNTunnel
  private var connectionState: TieraConnectionState = .disconnected
  private var startTime: Date?

  /// Current connection state
  public var state: TieraConnectionState {
    connectionState
  }

  /// Connection duration (if connected)
  public var connectionDuration: TimeInterval? {
    guard let startTime = startTime else { return nil }
    return Date().timeIntervalSince(startTime)
  }

  /// Bytes transferred statistics
  public var statistics: TieraVPNStatistics {
    get async {
      let bytes = await tunnel.bytesTransferred
      return TieraVPNStatistics(
        bytesSent: bytes.sent,
        bytesReceived: bytes.received,
        connectionDuration: connectionDuration ?? 0
      )
    }
  }

  // MARK: - Initialization

  /// Initialize Tiera VPN Connection Service
  /// - Parameter packetFlow: NEPacketTunnelFlow for packet processing
  public init(packetFlow: NEPacketTunnelFlow) {
    self.tunnel = TieraVPNTunnel(packetFlow: packetFlow)
    TieraLogger.log("[TieraConnectionService] Service initialized")
  }

  // MARK: - Public Methods

  /// Establish secure Tiera VPN connection
  /// - Parameters:
  ///   - dataDir: Directory for Tiera VPN data files
  ///   - config: VPN configuration (JSON or URL)
  ///   - finalConfigPath: Path where final config will be written
  ///   - sniffing: Optional traffic sniffing configuration
  /// - Throws: TieraVPNError on failure
  public func establishSecureConnection(
    dataDir: URL,
    config: TieraVPNIntermediateConfig,
    finalConfigPath: URL,
    sniffing: TieraSniffingConfig? = nil
  ) async throws {

    guard connectionState != .connecting else {
      TieraLogger.warn("[TieraConnectionService] Connection already in progress")
      return
    }

    connectionState = .connecting
    TieraLogger.log("[TieraConnectionService] Establishing Tiera secure connection...")

    do {
      try await tunnel.run(
        dataDir: dataDir,
        config: config,
        finalConfigPath: finalConfigPath,
        inboundSniffing: sniffing
      )

      connectionState = .connected
      startTime = Date()
      TieraLogger.log("[TieraConnectionService] ✅ Tiera connection established successfully")

    } catch let error as TieraVPNError {
      connectionState = .failed(error)
      TieraLogger.error("[TieraConnectionService] ❌ Connection failed: \(error.localizedDescription)")
      throw error
    } catch {
      let tieraError = TieraVPNError.tieraConnectionFailed(error.localizedDescription)
      connectionState = .failed(tieraError)
      TieraLogger.error("[TieraConnectionService] ❌ Unexpected error: \(error)")
      throw tieraError
    }
  }

  /// Terminate Tiera VPN connection
  public func terminateConnection() async {
    TieraLogger.log("[TieraConnectionService] Terminating Tiera VPN connection...")

    await tunnel.stop()
    connectionState = .disconnected
    startTime = nil

    TieraLogger.log("[TieraConnectionService] Connection terminated")
  }

  /// Reset connection statistics
  public func resetStatistics() async {
    await tunnel.clearStats()
    TieraLogger.log("[TieraConnectionService] Statistics reset")
  }
}

// MARK: - Supporting Types

/// Tiera VPN connection state
public enum TieraConnectionState: Equatable {
  case disconnected
  case connecting
  case connected
  case failed(TieraVPNError)

  public var isConnected: Bool {
    if case .connected = self { return true }
    return false
  }
}

/// Tiera VPN connection statistics
public struct TieraVPNStatistics {
  public let bytesSent: UInt32
  public let bytesReceived: UInt32
  public let connectionDuration: TimeInterval

  public var totalBytes: UInt64 {
    UInt64(bytesSent) + UInt64(bytesReceived)
  }

  public var formattedBytesSent: String {
    ByteFormatter.format(bytes: bytesSent)
  }

  public var formattedBytesReceived: String {
    ByteFormatter.format(bytes: bytesReceived)
  }

  public var formattedDuration: String {
    let hours = Int(connectionDuration) / 3600
    let minutes = Int(connectionDuration) / 60 % 60
    let seconds = Int(connectionDuration) % 60

    if hours > 0 {
      return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%02d:%02d", minutes, seconds)
    }
  }
}

/// Tiera VPN logger - custom logging with Tiera branding
public enum TieraLogger {
  public static func log(_ message: String) {
    print("[Tiera VPN Engine] \(message)")
  }

  public static func warn(_ message: String) {
    print("[Tiera VPN Engine] ⚠️ \(message)")
  }

  public static func error(_ message: String) {
    print("[Tiera VPN Engine] ❌ \(message)")
  }

  public static func debug(_ message: String) {
    #if DEBUG
    print("[Tiera VPN Engine] 🔍 \(message)")
    #endif
  }
}

/// Byte formatter utility
private enum ByteFormatter {
  static func format(bytes: UInt32) -> String {
    let kb = Double(bytes) / 1024
    let mb = kb / 1024
    let gb = mb / 1024

    if gb >= 1 {
      return String(format: "%.2f GB", gb)
    } else if mb >= 1 {
      return String(format: "%.2f MB", mb)
    } else if kb >= 1 {
      return String(format: "%.2f KB", kb)
    } else {
      return "\(bytes) B"
    }
  }
}
