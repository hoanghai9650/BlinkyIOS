//
//  RootPagerView.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI
import SwiftUIPager

enum RootPage: Int, Identifiable {
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
    private let pagerPages: [RootPage] = [.library, .camera]
    @StateObject private var page = Page.withIndex(0)
    @State private var currentPage: RootPage = .library
    @State private var isCameraActive = false
    
    var body: some View {
        NavigationStack {
                Pager(page: page,
                      data: pagerPages,
                      id: \.id) { page in
                    switch page {
                    case .library:
                        GalleryContainerView {
                            self.page.update(.moveToLast)
                        }
                        
                    case .camera:
                        CameraView(isActive: isCameraActive)
//                            .navigationBarHidden(true)
                    }
                }
                      .pagingPriority(.simultaneous)
                      .sensitivity(.high)
                      .bounces(false)
                      .onPageWillChange { index in
                          guard pagerPages.indices.contains(index) else { return }
                          let newPage = pagerPages[index]
                          updateCameraActivity(for: newPage)
                      }
                      .onPageChanged { index in
                          guard pagerPages.indices.contains(index) else { return }
                          currentPage = pagerPages[index]
                          updateCameraActivity(for: currentPage)
                      }
 
                      .padding(1)
                      .edgesIgnoringSafeArea(.all)
                      .background(Color.blackKite.edgesIgnoringSafeArea(.all))
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


