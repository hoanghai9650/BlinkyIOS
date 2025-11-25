//
//  FilterSheetView.swift
//  Blinky
//
//  Bottom sheet with color swatches for filter selection
//

import SwiftUI

struct FilterSheetView: View {
    @Binding var selectedFilter: FilterLUT
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            // Title
            Text("Filters")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            
            // Filter grid
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(FilterLUT.allCases) { filter in
                    FilterSwatchButton(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        action: {
                            selectedFilter = filter
                            dismiss()
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(
            Color.secondaryBackground
                .clipShape(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
                .ignoresSafeArea(edges: .bottom)
        )
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
    }
}

// MARK: - Filter Swatch Button

struct FilterSwatchButton: View {
    let filter: FilterLUT
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Color swatch
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(filter.swatchGradient)
                    .frame(height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isSelected ? Color.primary : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    )
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white, Color.primary)
                        }
                    }
                
                // Label
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Color Swatches

extension FilterLUT {
    var swatchGradient: LinearGradient {
        switch self {
        case .none:
            return LinearGradient(
                colors: [Color(white: 0.5), Color(white: 0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cinematic:
            return LinearGradient(
                colors: [Color(hex: "#2C3E50"), Color(hex: "#4A4A4A"), Color(hex: "#D4A574")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .vivid:
            return LinearGradient(
                colors: [Color(hex: "#FF6B6B"), Color(hex: "#4ECDC4"), Color(hex: "#45B7D1")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .noir:
            return LinearGradient(
                colors: [Color.black, Color(white: 0.3), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .film:
            return LinearGradient(
                colors: [Color(hex: "#E8D5B7"), Color(hex: "#B8860B"), Color(hex: "#8B7355")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.background.ignoresSafeArea()
        
        FilterSheetView(selectedFilter: .constant(.cinematic))
    }
}

