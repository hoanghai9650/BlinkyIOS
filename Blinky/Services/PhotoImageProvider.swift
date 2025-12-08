//
//  PhotoImageProvider.swift
//  Blinky
//
//  Created by Codex.
//

import UIKit

enum PhotoImageProvider {
    private static let cache = NSCache<NSURL, UIImage>()
    
    static func image(at url: URL) -> UIImage? {
        let key = url as NSURL
        if let cached = cache.object(forKey: key) {
            return cached
        }
        if let image = loadImage(at: url, cacheKey: key) {
            return image
        }
        guard let fallbackURL = fallbackURL(for: url) else { return nil }
        return loadImage(at: fallbackURL, cacheKey: key)
    }
    
    /// Async version for loading images on background thread
    static func imageAsync(at url: URL) async -> UIImage? {
        let key = url as NSURL
        
        // Check cache first on main actor
        if let cached = cache.object(forKey: key) {
            return cached
        }
        
        // Load on background thread
        return await Task.detached(priority: .userInitiated) {
            if let image = UIImage(contentsOfFile: url.path) {
                await MainActor.run {
                    cache.setObject(image, forKey: key)
                }
                return image
            }
            
            // Try fallback
            guard let fallbackURL = fallbackURL(for: url) else { return nil }
            if let image = UIImage(contentsOfFile: fallbackURL.path) {
                await MainActor.run {
                    cache.setObject(image, forKey: key)
                }
                return image
            }
            return nil
        }.value
    }
    
    private static func loadImage(at url: URL, cacheKey: NSURL) -> UIImage? {
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache.setObject(image, forKey: cacheKey)
        return image
    }
    
    private static func fallbackURL(for url: URL) -> URL? {
        let filename = url.lastPathComponent
        guard !filename.isEmpty else { return nil }
        let fallbackURL = PhotoStorageService.fileURL(for: filename)
        return fallbackURL == url ? nil : fallbackURL
    }
}
