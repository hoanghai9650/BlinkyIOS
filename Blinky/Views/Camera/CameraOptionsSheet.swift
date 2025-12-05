//
//  CameraOptionsSheet.swift
//  Blinky
//
//  Options menu: location toggle, grid toggle, level indicator toggle
//

import SwiftUI

struct CameraOptionsSheet: View {
    @Binding var storeLocation: Bool
    @Binding var showGrid: Bool
    @Binding var showLevelIndicator: Bool
    var namespace: Namespace.ID
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
                
                // Level Indicator
                OptionToggleRow(
                    icon: "level",
                    title: "Level Indicator",
                    subtitle: "Helps keep camera horizontal or vertical",
                    isOn: $showLevelIndicator
                )
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .presentationDetents([.height(320)])
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

// MARK: - Preview

struct CameraOptionsSheetPreview: View {
    @Namespace private var namespace
    
    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            CameraOptionsSheet(
                storeLocation: .constant(true),
                showGrid: .constant(false),
                showLevelIndicator: .constant(true),
                namespace: namespace
            )
        }
    }
}

#Preview {
    CameraOptionsSheetPreview()
}

