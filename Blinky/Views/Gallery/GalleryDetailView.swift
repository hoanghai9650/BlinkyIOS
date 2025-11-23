//
//  GalleryDetailView.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI

struct GalleryDetailView: View {
    let asset: PhotoAsset
    let namespace: Namespace.ID
    let onClose: () -> Void
    let onDelete: () -> Void
    @State private var dragOffset: CGFloat = 0
    @State private var polaroidWidth: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Backdrop blur background
            BlurView(style: .systemThinMaterial).ignoresSafeArea()
            VStack(spacing: 0) {
                // Header with share button
//                Color.clear
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(LiquidGlassButtonStyle(color: Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 1)))
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(LiquidGlassButtonStyle(color: Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 1)))
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        polaroidCard.padding(.top, 4)
                        metadataCard
                    }
                    .padding(.horizontal, 16)
                }
           
                
                Spacer(minLength: 0)
                
                bottomActions
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarHidden(true)
//        .offset(y: dragOffset)
//        .gesture(
//            DragGesture()
//                .onChanged { value in
//                    if value.translation.height > 0 {
//                        dragOffset = value.translation.height
//                    }
//                }
//                .onEnded { value in
//                    if value.translation.height > 120 {
//                        handleClose()
//                    } else {
//                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
//                            dragOffset = 0
//                        }
//                    }
//                }
//        )
    }
    
    private func handleClose() {
        dragOffset = 0
        onClose()
    }
    
    private func handleDelete() {
        dragOffset = 0
        onDelete()
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE dd MMM yyyy"
        return formatter
    }
    
    private var polaroidCard: some View {
        PolaroidView(
            asset: asset,
            namespace: namespace,
            onTap: onClose
        )
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: ViewWidthKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(ViewWidthKey.self) { width in
            polaroidWidth = width
        }
    }
    
    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Preset row
            HStack {
                Text("Preset: (ICON) \(asset.filterName)")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 1))
                Spacer()
                Text(asset.lens)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 1))
            }
            
            // Metrics row
            HStack {
                Text("ISO: \(Int(asset.iso))")
                    .font(.system(size: 8, weight: .regular))
                    .foregroundColor(Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 1))
                Spacer()
                Text("Aperture: f/\(String(format: "%.1f", asset.aperture))")
                    .font(.system(size: 8, weight: .regular))
                    .foregroundColor(Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 1))
                Spacer()
                Text("Shutter: \(asset.shutterSpeed)")
                    .font(.system(size: 8, weight: .regular))
                    .foregroundColor(Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 1))
            }
            
            // Divider
            Rectangle()
                .fill(Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 0.3))
                .frame(height: 0.5)
            
            // Location
            if let location = asset.locationDescription {
                Text("Location: \(location)")
                    .font(.system(size: 8, weight: .regular))
                    .foregroundColor(Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 1))
            }
            
            // Time
            Text("Time: \(timeFormatter.string(from: asset.capturedAt))")
                .font(.system(size: 8, weight: .regular))
                .foregroundColor(Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 1))
        }
        .padding(16)
        .frame(width: polaroidWidth > 0 ? polaroidWidth : nil, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(.sRGB, red: 247/255, green: 247/255, blue: 248/255, opacity: 1), lineWidth: 1)
                )
        )
    }
    
    private var bottomActions: some View {
        HStack(spacing: 64) {
            // Folder button
            Button(action: {}) {
                Image(systemName: "folder.fill")
            }
            .buttonStyle(LiquidGlassButtonStyle(color: Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 1)))
            
            // Delete button
            Button(action: handleDelete) {
                Image(systemName: "trash.fill")
            }
            .buttonStyle(LiquidGlassButtonStyle(color: Color(.sRGB, red: 232/255, green: 58/255, blue: 48/255, opacity: 1)))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 0)
        
            }
}
