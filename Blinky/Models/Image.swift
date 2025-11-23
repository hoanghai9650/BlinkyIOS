//
//  Image.swift
//  Blinky
//
//  Created by MacOS on 20/11/25.
//

import Foundation

struct PhotoImage: Identifiable{
    var id: UUID = UUID()
    var url: String
    var thumbnail: String
    
}

var photoImages = [
    PhotoImage( url: "img1", thumbnail: "img1"),
    PhotoImage( url: "img2", thumbnail: "img2"),
    PhotoImage( url: "img3", thumbnail: "img3"),
    PhotoImage( url: "img4", thumbnail: "img4")
    
]
