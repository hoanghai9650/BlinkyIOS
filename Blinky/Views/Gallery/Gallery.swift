//
//  Gallery.swift
//  Blinky
//
//  Created by MacOS on 20/11/25.
//

import Foundation
import SwiftUI

struct Gallery: View {
    
    @State private var images: [PhotoImage] = photoImages
    @State private var selectedImage: PhotoImage? = nil
    @State private var showDetail: Bool = false
    @Namespace private var animation
    
    let columns = Array(repeating: GridItem(.flexible()), count: 3)
    
    @State private var isExpanded: Bool = false
    @Namespace private var namespace
    
    var body: some View {
   
        GlassEffectContainer(spacing: 40.0) {
//            Color.red
            HStack{
                Spacer()
                    HStack(spacing: 40.0) {
                        if isExpanded {
                            Button{} label: {
                                Image(systemName: "eraser.fill")
                                    .frame(width: 80.0, height: 80.0)
                                    .font(.system(size: 36))
                                    .glassEffect()
                                    .glassEffectID("eraser", in: namespace)
                            }
                           
                        }
                        Button{withAnimation {
                            isExpanded.toggle()
                        }} label: {
                            Text("expand")
                                .font(.system(size: 16, weight: .medium))
                                                                   .foregroundColor(Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 1))
                                                                   .padding(.horizontal, 24)
                                                                   .padding(.vertical, 12)
                                .glassEffect()
                                .glassEffectID("pencil", in: namespace)
                        }
                      
                    }
            }
            
            }
      
//        ZStack() {
//            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
//            VStack {
//                ScrollView {
//                    LazyVGrid(columns: columns, spacing: 30) {
//                        ForEach(images) { image in
//                            Image(image.url)
//                                .resizable()
//                                .scaledToFit()
////                                .aspectRatio(1, contentMode: .fit)
////                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100, maxHeight: 100)
//                                .cornerRadius(10)
//                                .shadow(radius: 10)
//                                // Use a stable id from the image itself
//                                .matchedGeometryEffect(id: image.id, in: animation)
//                                .onTapGesture {
//                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
//                                        selectedImage = image
//                                        showDetail = true
//                                    }
//                                }
//                        }
//                    }
//                }
//            }
//            .padding(.horizontal, 16)
//            .overlay{
//                if(showDetail){
//                    BlurView(style: .regular).ignoresSafeArea()
//                }
//                
//            }
//            
//            if showDetail, let selectedImage {
//                DetailView(
//                    selectedImage: .constant(selectedImage),
//                    showDetail: $showDetail,
//                    animation: animation,
//                    onClose: {
//                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
//                            self.selectedImage = nil
//                            self.showDetail = false
//                        }
//                    }
//                )
//            }
//        }
    }
}

struct DetailView: View {
    // Keep the selected image immutable inside detail; closing is handled via onClose
    @Binding var selectedImage: PhotoImage
    @Binding var showDetail: Bool
    let animation: Namespace.ID
    var onClose: () -> Void
    
    var body: some View {
        ZStack {
            // Central popup stack
            VStack(spacing: 20) {
                polaroidCard
                infoPanel
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: 393) // iPhone width target from design
            
            // Header share button
            VStack {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(LiquidGlassButtonStyle(color: cream))
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(LiquidGlassButtonStyle(color: cream))
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
                
                Spacer()
            }
            
            // Bottom action bar
            VStack {
                Spacer()
                HStack(spacing: 64) {
                    Button(role: .destructive, action: {}) {
                        Image(systemName: "trash.fill")
                    }
                    .buttonStyle(LiquidGlassButtonStyle(color: danger))
                    
                    Button(action: {}) {
                        Image(systemName: "folder.fill")
                    }
                    .buttonStyle(LiquidGlassButtonStyle(color: cream))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(height: 64)
                .frame(maxWidth: 361)
                .ignoresSafeArea()
                
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var polaroidCard: some View {
        // PolaroidView signature changed to use PhotoAsset for production.
        // This experimental view is now deprecated.
        Text("Polaroid View moved to production")
            .foregroundColor(.white)
        // PolaroidView(photo: selectedImage, namespace: animation, onTap: onClose)
    }
    
    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Preset: (ICON) Fujifilm Classic Chrome")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(cream)
                    .textCase(.none)
                Spacer()
                Text("35mm")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(cream)
            }
            
            HStack {
                Text("ISO: 200")
                Spacer()
                Text("Aperture: f/2.0")
                Spacer()
                Text("Shutter: 1/120")
            }
            .font(.system(size: 10, weight: .regular))
            .foregroundColor(cream)
            
            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(height: 0.5)
                .opacity(0.4)
            
            Text("Location: Ho Chi Minh city")
                .font(.system(size: 10))
                .foregroundColor(cream)
            Text("Time: \(timeStamp)")
                .font(.system(size: 10))
                .foregroundColor(cream)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cream.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        )
    }
    
    // MARK: - Tokens
    private var cream: Color {
        Color(.sRGB, red: 245/255, green: 245/255, blue: 237/255, opacity: 1)
    }
    private var pri: Color {
        Color(.sRGB, red: 255/255, green: 96/255, blue: 56/255, opacity: 1)
    }
    private var danger: Color {
        Color(.sRGB, red: 232/255, green: 58/255, blue: 48/255, opacity: 1)
    }
    
    // MARK: - Helpers
    private var dateStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: Date())
    }
    private var timeStamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM yyyy"
        return formatter.string(from: Date())
    }
}

#Preview {
    Gallery()
}
