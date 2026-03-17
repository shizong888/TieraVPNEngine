//
// TieraVPNIntermediateConfig.swift
// TieraVPNWrapper
//
// Copyright © 2025 Dmitry Ulyanov
//

import Foundation

/// Configuration input format for TieraVPN tunnel
public enum TieraVPNIntermediateConfig {
  /// Direct JSON configuration string
  case json(String)
  
  /// URL/share link that will be converted to JSON configuration
  case url(String)
}
