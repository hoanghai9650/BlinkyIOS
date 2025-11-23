//
//  MasonryGrid.swift
//  Blinky
//
//  Created by Codex.
//

import SwiftUI

/// Lightweight masonry-style layout that keeps mutations on the main actor.
struct MasonryGrid<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    private let items: Data
    private let columns: Int
    private let spacing: CGFloat
    private let content: (Data.Element) -> Content
    
    init(columns: Int, spacing: CGFloat = 8, items: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.columns = max(columns, 1)
        self.spacing = spacing
        self.items = items
        self.content = content
    }
    
    var body: some View {
        let columnedItems = splitItems()
        HStack(alignment: .top, spacing: spacing) {
            ForEach(columnedItems.indices, id: \.self) { columnIndex in
                LazyVStack(spacing: spacing) {
                    ForEach(columnedItems[columnIndex]) { item in
                        content(item)
                    }
                }
            }
        }
    }
    
    private func splitItems() -> [[Data.Element]] {
        var columnsData: [[Data.Element]] = Array(repeating: [], count: columns)
        var columnIndex = 0
        for item in items {
            columnsData[columnIndex].append(item)
            columnIndex = (columnIndex + 1) % columns
        }
        return columnsData
    }
}
