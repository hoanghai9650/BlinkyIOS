//
//  ScrollableHeader.swift
//  Blinky
//
//  Reusable header with linear blur effect on scroll
//

import SwiftUI

struct ScrollableHeader<Actions: View>: View {
    let safeAreaTop: CGFloat
    let isScrolled: Bool
    let title: String?
    let trailingSpaceing: CGFloat = 40
    @ViewBuilder let actions: () -> Actions
    
    init(
        safeAreaTop: CGFloat,
        isScrolled: Bool,
        title: String? = nil,
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.safeAreaTop = safeAreaTop
        self.isScrolled = isScrolled
        self.title = title
        self.actions = actions
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Safe area spacer
            Color.clear.frame(height: safeAreaTop)
            
            // Header content
            HStack {
                // Title (if provided)
                if let title {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.text)
                }
                
                Spacer()
                
                // Action buttons with glass effect
                GlassEffectContainer(spacing: trailingSpaceing) {
                    HStack(spacing: trailingSpaceing) {
                        actions()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
            }
            .frame(height: 44)
           
        }
        .background {
            // Linear blur background
            LinearBlurBackground(isVisible: isScrolled)
                .ignoresSafeArea(edges: .top)
        }
    }
}

// MARK: - Linear Blur Background

private struct LinearBlurBackground: View {
    let isVisible: Bool
    
    var body: some View {
        Rectangle()
            .fill(.clear)
            .background {
                // Gradient blur effect
                LinearGradient(
                    stops: [
                        .init(color: Color.background.opacity(isVisible ? 0.95 : 0), location: 0),
                        .init(color: Color.background.opacity(isVisible ? 0.8 : 0), location: 0.5),
                        .init(color: Color.background.opacity(0), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .animation(.easeInOut(duration: 0.25), value: isVisible)
    }
}

// MARK: - Convenience init without actions

extension ScrollableHeader where Actions == EmptyView {
    init(safeAreaTop: CGFloat, isScrolled: Bool, title: String? = nil) {
        self.safeAreaTop = safeAreaTop
        self.isScrolled = isScrolled
        self.title = title
        self.actions = { EmptyView() }
    }
}

#Preview {
    ZStack {
        Color.background.ignoresSafeArea()
        
        VStack {
            ScrollableHeader(
                safeAreaTop: 59,
                isScrolled: true,
                title: nil
            ) {
                Button {
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                }
                
                Button {
                } label: {
                    Text("Select")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.text)
                }
            }
            
            Spacer()
        }
    }
}

