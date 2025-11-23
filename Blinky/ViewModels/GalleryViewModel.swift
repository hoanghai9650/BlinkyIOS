//
//  GalleryViewModel.swift
//  Blinky
//
//  Created by Codex.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
final class GalleryViewModel: ObservableObject {

    @Published var isSelectionMode = false
    @Published private(set) var selectedAssetIDs: Set<PhotoAsset.ID> = []
    
    private let storageService: PhotoStorageService
    
    init(storageService: PhotoStorageService? = nil) {
        self.storageService = storageService ?? PhotoStorageService()
    }
    
    func toggleSelectionMode() {
        
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedAssetIDs.removeAll()
        }
    }
    
    func isSelected(_ asset: PhotoAsset) -> Bool {
        selectedAssetIDs.contains(asset.id)
    }
    
    func toggleSelection(for asset: PhotoAsset) {
        if isSelected(asset) {
            selectedAssetIDs.remove(asset.id)
        } else {
            selectedAssetIDs.insert(asset.id)
        }
    }
    
    func delete(_ asset: PhotoAsset, context: ModelContext) {
        storageService.deleteFiles(for: asset)
        context.delete(asset)
        try? context.save()
        selectedAssetIDs.remove(asset.id)
    }
    
    func deleteSelected(from assets: [PhotoAsset], context: ModelContext) {
        let assetsToDelete = assets.filter { selectedAssetIDs.contains($0.id) }
        for asset in assetsToDelete {
            delete(asset, context: context)
        }
        selectedAssetIDs.removeAll()
        isSelectionMode = false
    }
}
