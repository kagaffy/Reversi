//
//  Disk.swift
//  Reversi
//
//  Created by Yoshiki Tsukada on 2021/01/04.
//

import UIKit

enum Disk {
    case dark
    case light
    
    var color: UIColor {
        switch self {
        case .dark: return .black
        case .light: return .white
        }
    }
    
    var flipped: Self {
        switch self {
        case .dark: return .light
        case .light: return .dark
        }
    }
    
    mutating func flip() {
        self = flipped
    }
}
