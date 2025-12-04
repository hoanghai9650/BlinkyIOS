//
//  ScrollableFooter.swift
//  Blinky
//
//  Reusable footer with linear blur effect on scroll
//

import SwiftUI

struct ScrollableFooter<Content: View>: View {
    let safeAreaBottom: CGFloat
    let isScrolled: Bool
    @ViewBuilder let content: () -> Content
    
    init(
        safeAreaBottom: CGFloat,
        isScrolled: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.safeAreaBottom = safeAreaBottom
        self.isScrolled = isScrolled
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Footer content
            content()
            
            // Safe area spacer
            Color.clear.frame(height: safeAreaBottom)
        }
        .background {
            // Linear blur background (bottom to top)
            LinearBlurFooterBackground(isVisible: isScrolled)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Linear Blur Footer Background

private struct LinearBlurFooterBackground: View {
    let isVisible: Bool
    
    var body: some View {
        Rectangle()
            .fill(.clear)
            .background {
                // Gradient blur effect (reversed - from bottom)
                LinearGradient(
                    stops: [
                        .init(color: Color.background.opacity(0), location: 0),
                        .init(color: Color.background.opacity(isVisible ? 0.7 : 0), location: 0.5),
                        .init(color: Color.background.opacity(isVisible ? 0.95 : 0), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .animation(.easeInOut(duration: 0.25), value: isVisible)
    }
}

#Preview {
    ZStack {
        Color.background.ignoresSafeArea()
        
        VStack {
            Spacer()
            
            ScrollableFooter(
                safeAreaBottom: 34,
                isScrolled: true
            ) {
                HStack(spacing: 16) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: "folder")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 42, height: 42)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .glassEffect(.regular.interactive())
            }
        }
    }
}

