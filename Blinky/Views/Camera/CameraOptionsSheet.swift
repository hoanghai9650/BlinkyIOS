//
//  CameraOptionsSheet.swift
//  Blinky
//
//  Options menu: location toggle, grid toggle, white balance presets
//

import SwiftUI

struct CameraOptionsSheet: View {
    @Binding var storeLocation: Bool
    @Binding var showGrid: Bool
    @Binding var whiteBalancePreset: CameraSettingsService.WhiteBalancePreset
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            // Title
            HStack {
                Text("Camera Options")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            VStack(spacing: 12) {
                // Store Location
                OptionToggleRow(
                    icon: "location.fill",
                    title: "Store Location",
                    subtitle: "Save GPS coordinates with photos",
                    isOn: $storeLocation
                )
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                // Show Grid
                OptionToggleRow(
                    icon: "grid",
                    title: "Show Grid",
                    subtitle: "Display rule of thirds overlay",
                    isOn: $showGrid
                )
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                // White Balance
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.icon)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("White Balance")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            
                            Text("Color temperature preset")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    
                    // White Balance Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(CameraSettingsService.WhiteBalancePreset.allCases) { preset in
                                WhiteBalancePresetButton(
                                    preset: preset,
                                    isSelected: whiteBalancePreset == preset,
                                    action: { whiteBalancePreset = preset }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 14)
                }
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .background(
            Color.secondaryBackground
                .clipShape(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
                .ignoresSafeArea(edges: .bottom)
        )
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
    }
}

// MARK: - Option Toggle Row

struct OptionToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.icon)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - White Balance Preset Button

struct WhiteBalancePresetButton: View {
    let preset: CameraSettingsService.WhiteBalancePreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: preset.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? .white : Color.icon)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.primary : Color.white.opacity(0.08))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(isSelected ? Color.primary : Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                Text(preset.rawValue)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                    .lineLimit(1)
            }
            .frame(width: 56)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.background.ignoresSafeArea()
        
        CameraOptionsSheet(
            storeLocation: .constant(true),
            showGrid: .constant(false),
            whiteBalancePreset: .constant(.auto)
        )
    }
}

