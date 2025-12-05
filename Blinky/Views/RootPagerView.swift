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
                    
                    CameraView(isActive: currentPage == .camera)
                        .tag(RootPage.camera)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .background(Color.background.ignoresSafeArea())
                .onAppear {
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
            }
        }
   
    }
}

#Preview {
    RootPagerView()
}
