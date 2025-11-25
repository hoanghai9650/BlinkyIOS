//
//  PolaroidView.swift
//  Blinky
//
//  Created by MacOS on 20/11/25.
//

import SwiftUI
import SwiftData

struct PolaroidView: View {
    let asset: PhotoAsset
    let namespace: Namespace.ID
    var isSelectionMode: Bool = false
    var isSelected: Bool = false
    var onTap: () -> Void
    
    var body: some View {
        Group {
            if let image = PhotoImageProvider.image(at: asset.thumbnailURL) {
                Image(uiImage: image)
                    .resizable()
//                    .matchedGeometryEffect(
//                        id: asset.id,
//                        in: namespace,
//                        isSource: true
//                    )
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .onTapGesture { onTap() }
            } else {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.gray.opacity(0.3))
                    .matchedGeometryEffect(id: asset.id, in: namespace, isSource: true)
                    .aspectRatio(1, contentMode: .fit)
                    .onTapGesture { onTap() }
            }
        }
        .padding(12)
        .padding(.bottom, 28)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cream.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
        )
        .overlay(alignment: .bottomTrailing) {
            Text(dateStamp)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(pri)
                .padding(.trailing, 12)
                .padding(.bottom, 12)
        }
        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 6)
        .overlay(alignment: .topTrailing) {
            if isSelectionMode {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                }
                .padding(12)
            }
        }
    }
    
    // MARK: - Helpers & Tokens
    // Note: In a real app, these might be shared constants or passed in.
    // For now, duplicating/localizing them to keep the view self-contained as per the original file.
    
    private var cream: Color {
        Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 1)
    }
    private var pri: Color {
        Color.primary
    }
    
    private var dateStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: asset.capturedAt)
    }
}

#Preview {
    Gallery()
}
