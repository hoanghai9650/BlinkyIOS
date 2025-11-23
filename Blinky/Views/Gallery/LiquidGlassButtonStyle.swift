//
//  LiquidGlassButtonStyle.swift
//  Blinky
//
//  Created by MacOS on 20/11/25.
//

import SwiftUI

struct LiquidGlassButtonStyle: ButtonStyle {
    var color: Color = .white
    var size: CGFloat = 44
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(color)
            .frame(width: size, height: size)
            .background(
                ZStack {
                    BlurView(style: .systemUltraThinMaterial)
                    Circle()
                        .stroke(color.opacity(0.8), lineWidth: 1)
                }
                .clipShape(Circle())
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
