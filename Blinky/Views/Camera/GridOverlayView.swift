//
//  GridOverlayView.swift
//  Blinky
//
//  Rule-of-thirds grid overlay for camera preview
//

import SwiftUI

struct GridOverlayView: View {
    let lineColor: Color
    let lineWidth: CGFloat
    
    init(
        lineColor: Color = .white.opacity(0.4),
        lineWidth: CGFloat = 0.5
    ) {
        self.lineColor = lineColor
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            
            Canvas { context, size in
                // Vertical lines (rule of thirds)
                let x1 = width / 3
                let x2 = width * 2 / 3
                
                // Horizontal lines (rule of thirds)
                let y1 = height / 3
                let y2 = height * 2 / 3
                
                // Draw vertical lines
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: x1, y: 0))
                        path.addLine(to: CGPoint(x: x1, y: height))
                    },
                    with: .color(lineColor),
                    lineWidth: lineWidth
                )
                
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: x2, y: 0))
                        path.addLine(to: CGPoint(x: x2, y: height))
                    },
                    with: .color(lineColor),
                    lineWidth: lineWidth
                )
                
                // Draw horizontal lines
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y1))
                        path.addLine(to: CGPoint(x: width, y: y1))
                    },
                    with: .color(lineColor),
                    lineWidth: lineWidth
                )
                
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y2))
                        path.addLine(to: CGPoint(x: width, y: y2))
                    },
                    with: .color(lineColor),
                    lineWidth: lineWidth
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray
        GridOverlayView()
    }
    .frame(width: 300, height: 400)
}

