//
//  CameraSettingsService.swift
//  Blinky
//
//  Camera device parameter control service (SOLID - Single Responsibility)
//

import AVFoundation
import Combine

/// Service responsible for adjusting camera device parameters
final class CameraSettingsService {
    
    // MARK: - Types
    
    struct DeviceCapabilities {
        let minISO: Float
        let maxISO: Float
        let minExposureDuration: CMTime
        let maxExposureDuration: CMTime
        let minExposureTargetBias: Float
        let maxExposureTargetBias: Float
    }
    
    // MARK: - Properties
    
    private weak var device: AVCaptureDevice?
    private(set) var capabilities: DeviceCapabilities?
    
    // MARK: - Configuration
    
    func configure(with device: AVCaptureDevice) {
        self.device = device
        self.capabilities = DeviceCapabilities(
            minISO: device.activeFormat.minISO,
            maxISO: device.activeFormat.maxISO,
            minExposureDuration: device.activeFormat.minExposureDuration,
            maxExposureDuration: device.activeFormat.maxExposureDuration,
            minExposureTargetBias: device.minExposureTargetBias,
            maxExposureTargetBias: device.maxExposureTargetBias
        )
    }
    
    // MARK: - Exposure (EV Bias)
    
    func setExposureBias(_ bias: Float) {
        guard let device else { return }
        let clampedBias = min(max(bias, device.minExposureTargetBias), device.maxExposureTargetBias)
        
        configureDevice {
            device.setExposureTargetBias(clampedBias)
        }
    }
    
    func setAutoExposure() {
        guard let device else { return }
        configureDevice {
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
        }
    }
    
    // MARK: - ISO
    
    func setISO(_ iso: Float) {
        guard let device else { return }
        let clampedISO = min(max(iso, device.activeFormat.minISO), device.activeFormat.maxISO)
        
        configureDevice {
            if device.isExposureModeSupported(.custom) {
                device.setExposureModeCustom(
                    duration: device.exposureDuration,
                    iso: clampedISO
                )
            }
        }
    }
    
    func setAutoISO() {
        guard let device else { return }
        configureDevice {
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
        }
    }
    
    // MARK: - Shutter Speed (Exposure Duration)
    
    func setShutterSpeed(_ duration: CMTime) {
        guard let device else { return }
        let minDuration = device.activeFormat.minExposureDuration
        let maxDuration = device.activeFormat.maxExposureDuration
        
        let clampedDuration = CMTimeClampToRange(duration, range: CMTimeRange(start: minDuration, duration: maxDuration - minDuration))
        
        configureDevice {
            if device.isExposureModeSupported(.custom) {
                device.setExposureModeCustom(
                    duration: clampedDuration,
                    iso: device.iso
                )
            }
        }
    }
    
    func setAutoShutter() {
        setAutoExposure()
    }
    
    // MARK: - White Balance (Temperature)
    
    func setWhiteBalance(temperature: Float) {
        guard let device else { return }
        
        // Temperature in Kelvin (1800-9800) -> device temperatureAndTintValues
        let temperatureAndTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(
            temperature: temperature,
            tint: 0 // Neutral tint
        )
        
        let gains = device.deviceWhiteBalanceGains(for: temperatureAndTint)
        let normalizedGains = normalizeGains(gains, for: device)
        
        configureDevice {
            if device.isWhiteBalanceModeSupported(.locked) {
                device.setWhiteBalanceModeLocked(with: normalizedGains)
            }
        }
    }
    
    func setAutoWhiteBalance() {
        guard let device else { return }
        configureDevice {
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
        }
    }
    
    // MARK: - White Balance Presets
    
    enum WhiteBalancePreset: String, CaseIterable, Identifiable {
        case auto = "Auto"
        case daylight = "Daylight"      // ~5600K
        case cloudy = "Cloudy"          // ~6500K
        case tungsten = "Tungsten"      // ~3200K
        case fluorescent = "Fluorescent" // ~4000K
        case shade = "Shade"            // ~7500K
        
        var id: String { rawValue }
        
        var temperature: Float {
            switch self {
            case .auto: return 5600
            case .daylight: return 5600
            case .cloudy: return 6500
            case .tungsten: return 3200
            case .fluorescent: return 4000
            case .shade: return 7500
            }
        }
        
        var icon: String {
            switch self {
            case .auto: return "a.circle"
            case .daylight: return "sun.max.fill"
            case .cloudy: return "cloud.fill"
            case .tungsten: return "lightbulb.fill"
            case .fluorescent: return "light.strip.2"
            case .shade: return "building.fill"
            }
        }
    }
    
    func applyWhiteBalancePreset(_ preset: WhiteBalancePreset) {
        if preset == .auto {
            setAutoWhiteBalance()
        } else {
            setWhiteBalance(temperature: preset.temperature)
        }
    }
    
    // MARK: - Private Helpers
    
    private func configureDevice(_ configuration: () -> Void) {
        guard let device else { return }
        do {
            try device.lockForConfiguration()
            configuration()
            device.unlockForConfiguration()
        } catch {
            print("CameraSettingsService: Failed to lock device - \(error)")
        }
    }
    
    private func normalizeGains(_ gains: AVCaptureDevice.WhiteBalanceGains, for device: AVCaptureDevice) -> AVCaptureDevice.WhiteBalanceGains {
        let maxGain = device.maxWhiteBalanceGain
        return AVCaptureDevice.WhiteBalanceGains(
            redGain: min(max(gains.redGain, 1.0), maxGain),
            greenGain: min(max(gains.greenGain, 1.0), maxGain),
            blueGain: min(max(gains.blueGain, 1.0), maxGain)
        )
    }
}

// MARK: - CMTime Helper

private func CMTimeClampToRange(_ time: CMTime, range: CMTimeRange) -> CMTime {
    if CMTimeCompare(time, range.start) < 0 {
        return range.start
    }
    let end = CMTimeAdd(range.start, range.duration)
    if CMTimeCompare(time, end) > 0 {
        return end
    }
    return time
}

