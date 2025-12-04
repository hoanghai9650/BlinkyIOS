//
//  RootPagerView.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI
import SwiftData

enum RootPage: Int, Identifiable, CaseIterable {
    case library
    case camera
    
    var id: Int { rawValue }
    
    var systemImage: String {
        switch self {
        case .library: return "square.grid.2x2"
        case .camera: return "camera.fill"
        }
    }
}

struct RootPagerView: View {
    @State private var currentPage: RootPage = .library
    @State private var isCameraActive = false
    @Namespace private var zoomTransition
    @Environment(\.modelContext) private var modelContext
    @State private var safeAreaInsets: EdgeInsets = .init()
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                TabView(selection: $currentPage) {
                    GalleryContainerView(
                        onCameraRequest: {
                            withAnimation {
                                currentPage = .camera
                            }
                        },
                        namespace: zoomTransition,
                        safeArea: safeAreaInsets
                    )
                    .tag(RootPage.library)
                    
                    CameraView(isActive: isCameraActive)
                        .tag(RootPage.camera)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .background(Color.background.ignoresSafeArea())
                .onAppear {
                    // Capture safe area once on appear
//                    safeAreaInsets = geo.safeAreaInsets
                    UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
                    UIScrollView.appearance().automaticallyAdjustsScrollIndicatorInsets = false
                }
           
            }

            .navigationDestination(for: PhotoAsset.self) { asset in
                GalleryDetailView(
                    asset: asset,
                    namespace: zoomTransition,
                    onDelete: {
                        modelContext.delete(asset)
                    }
                )
//                .navigationBarBackButtonHidden(true)
//                .toolbarVisibility(.hidden, for: .navigationBar)
            }
            .onChange(of: currentPage) { _, newPage in
                updateCameraActivity(for: newPage)
            }
            .onAppear {
                updateCameraActivity(for: currentPage)
            }
        }
   
    }
    
    private func updateCameraActivity(for page: RootPage) {
        withAnimation(.easeInOut(duration: 0.15)) {
            isCameraActive = page == .camera
        }
    }
}

#Preview {
    RootPagerView()
}
