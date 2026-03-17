# TieraVPNEngine

A custom Swift VPN framework for Tiera VPN, providing enterprise-grade VPN functionality for iOS and macOS applications with a unique API surface and enhanced features.

[![SPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![Swift 6.0](https://img.shields.io/badge/language-Swift6.0-orange.svg?style=flat)](https://developer.apple.com/swift)
[![Platform](https://img.shields.io/badge/platform-iOS%2015%2B%20%7C%20macOS%2013%2B-blue.svg)](https://github.com/shizong888/TieraVPNEngine)

## Overview

TieraVPNEngine provides a production-ready VPN solution with custom-built APIs specifically designed for Tiera VPN applications. Built on Xray-core 25.10.15, it offers:

- **TieraVPNTunnel**: Core VPN tunnel management
- **TieraConnectionService**: High-level connection API with state management
- **TieraLogger**: Branded logging system for debugging
- **Enhanced Error Handling**: Tiera-specific error types and recovery

## Features

✅ **Based on Xray-core 25.10.15** with xHTTP support
✅ **Custom TieraConnectionService API** - Unique wrapper for connection management
✅ **Enhanced Error Types** - Tiera-specific errors with detailed messaging
✅ **Connection State Management** - Track connection lifecycle
✅ **Statistics Tracking** - Real-time bandwidth and connection duration
✅ **Branded Logging** - `[Tiera VPN Engine]` prefixed logs
✅ **Port Allocation Management** - Automatic SOCKS5 port allocation
✅ **Share Link Support** - Convert VMess, VLESS, Trojan links to JSON
✅ **Geo-site & Geo-IP** - Built-in downloader for routing databases
✅ **iOS 15+ and macOS 13+** support

## Installation

### Swift Package Manager

Add TieraVPNEngine to your Xcode project:

```swift
dependencies: [
    .package(url: "https://github.com/shizong888/TieraVPNEngine.git", from: "1.2.1")
]
```

Or add via Xcode:
1. **File → Add Package Dependencies**
2. Enter: `https://github.com/shizong888/TieraVPNEngine`
3. Select version: **1.2.1** or later

## Quick Start

### Option 1: TieraConnectionService (Recommended)

High-level API with state management and statistics:

```swift
import NetworkExtension
import TieraVPNEngine

class PacketTunnelProvider: NEPacketTunnelProvider {

  var connectionService: TieraConnectionService?

  override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
    // Configure network settings first
    setTunnelNetworkSettings(networkSettings) { error in
      guard error == nil else {
        completionHandler(error)
        return
      }

      // Initialize Tiera connection service
      self.connectionService = TieraConnectionService(packetFlow: self.packetFlow)

      Task {
        do {
          let dataDir = FileManager.default.documentDirectory
          let configPath = dataDir.appendingPathComponent("config_final.json")

          // Read VPN configuration
          let configJson = try String(contentsOf: configPath, encoding: .utf8)

          // Establish secure connection
          try await self.connectionService?.establishSecureConnection(
            dataDir: dataDir,
            config: .json(configJson),
            finalConfigPath: configPath,
            sniffing: TieraSniffingConfig(
              destOverride: ["http", "tls", "quic"],
              enabled: true,
              routeOnly: false,
              domainsExcluded: [],
              metadataOnly: false
            )
          )

          TieraLogger.log("Tiera VPN connection established")
          completionHandler(nil)

        } catch let error as TieraVPNError {
          TieraLogger.error("Connection failed: \(error.localizedDescription)")
          completionHandler(error)
        }
      }
    }
  }

  override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
    Task {
      await connectionService?.terminateConnection()
      completionHandler()
    }
  }
}
```

### Option 2: TieraVPNTunnel (Direct Access)

Lower-level API for advanced use cases:

```swift
import NetworkExtension
import TieraVPNEngine

class PacketTunnelProvider: NEPacketTunnelProvider {

  var vpnTunnel: TieraVPNTunnel?

  override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
    setTunnelNetworkSettings(networkSettings) { error in
      guard error == nil else {
        completionHandler(error)
        return
      }

      self.vpnTunnel = TieraVPNTunnel(packetFlow: self.packetFlow)

      Task {
        do {
          let dataDir = FileManager.default.documentDirectory
          let config = try String(contentsOf: dataDir.appendingPathComponent("config.json"), encoding: .utf8)
          let finalPath = dataDir.appendingPathComponent("config_final.json")

          try await self.vpnTunnel?.run(
            dataDir: dataDir,
            config: .json(config),
            finalConfigPath: finalPath
          )

          completionHandler(nil)
        } catch {
          completionHandler(error)
        }
      }
    }
  }

  override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
    Task {
      await vpnTunnel?.stop()
      completionHandler()
    }
  }
}
```

## API Reference

### TieraConnectionService

High-level connection management with state tracking:

```swift
// Initialize
let service = TieraConnectionService(packetFlow: packetFlow)

// Connect
try await service.establishSecureConnection(
  dataDir: URL,
  config: TieraVPNIntermediateConfig,
  finalConfigPath: URL,
  sniffing: TieraSniffingConfig?
)

// Check state
let state = await service.state  // .connected, .connecting, .disconnected, .failed

// Get statistics
let stats = await service.statistics
print("Sent: \(stats.formattedBytesSent)")
print("Received: \(stats.formattedBytesReceived)")
print("Duration: \(stats.formattedDuration)")

// Disconnect
await service.terminateConnection()

// Reset stats
await service.resetStatistics()
```

### TieraVPNError

Enhanced error types with detailed messages:

```swift
public enum TieraVPNError: Error {
  case invalidResponse(String)           // Invalid server response
  case invalidConfig                     // Invalid configuration
  case portAllocationError               // Failed to allocate port
  case tunnelSetupError(String)         // Tunnel setup failed
  case tieraConnectionFailed(String)    // Connection failed
  case tieraNetworkUnreachable          // Network unreachable
  case tieraAuthenticationRequired      // Auth required
  case tieraServerUnavailable(String)   // Server unavailable
}
```

All errors include `[Tiera VPN Engine]` prefix in error descriptions.

### TieraLogger

Branded logging for debugging:

```swift
TieraLogger.log("Normal operation message")
TieraLogger.warn("Warning message")
TieraLogger.error("Error message")
TieraLogger.debug("Debug info (DEBUG builds only)")
```

Output format: `[Tiera VPN Engine] Your message`

### TieraVPNStatistics

Connection statistics tracking:

```swift
public struct TieraVPNStatistics {
  let bytesSent: UInt32
  let bytesReceived: UInt32
  let connectionDuration: TimeInterval

  var totalBytes: UInt64
  var formattedBytesSent: String      // "1.23 MB"
  var formattedBytesReceived: String  // "4.56 GB"
  var formattedDuration: String       // "01:23:45"
}
```

## Configuration

### VPN Configuration (JSON)

TieraVPNEngine accepts standard Xray JSON configuration:

```json
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "tag": "socks-in",
      "port": 1080,
      "listen": "127.0.0.1",
      "protocol": "socks"
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [{
          "address": "server.example.com",
          "port": 443,
          "users": [{ "id": "uuid-here", "encryption": "none" }]
        }]
      }
    }
  ]
}
```

### Sniffing Configuration

```swift
let sniffing = TieraSniffingConfig(
  destOverride: ["http", "tls", "quic"],  // Traffic types to detect
  enabled: true,                          // Enable sniffing
  routeOnly: false,                       // Route all traffic
  domainsExcluded: [],                    // Excluded domains
  metadataOnly: false                     // Full content inspection
)
```

## Requirements

- **iOS 15.0+** / **macOS 13.0+**
- **Swift 6.0+**
- **Xcode 15.0+**
- **Network Extension** entitlement
- **Packet Tunnel Provider** capability

## Dependencies

- **SwiftyXrayCore** 1.1.0+ (Xray-core binary framework)

## Migration from SwiftyXrayKit

Migrating from SwiftyXrayKit is straightforward:

```swift
// Before (SwiftyXrayKit)
import SwiftyXrayKit
var tunnel: XRayTunnel?
catch let error as SwiftyXRayError { }

// After (TieraVPNEngine)
import TieraVPNEngine
var tunnel: TieraVPNTunnel?
catch let error as TieraVPNError { }
```

See [MIGRATION.md](MIGRATION.md) for detailed migration guide.

## Examples

See the `Example/` directory for complete implementation examples.

## License

TieraVPNEngine is released under the **Apache 2.0 License**. See [LICENSE](LICENSE) for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/shizong888/TieraVPNEngine/issues)
- **Documentation**: This README
- **Source**: [GitHub Repository](https://github.com/shizong888/TieraVPNEngine)

## Credits

Built on [Xray-core](https://github.com/XTLS/Xray-core) v25.10.15

---

**Made with ❤️ for Tiera VPN**
