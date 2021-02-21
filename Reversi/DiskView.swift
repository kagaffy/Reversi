//
//  DiskView.swift
//  Reversi
//
//  Created by Yoshiki Tsukada on 2021/01/04.
//

import UIKit

class DiskView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        clipsToBounds = true
        layer.cornerRadius = bounds.width / 2
        setupViews()
    }

    private func setupViews() {
        layer.masksToBounds = false
        layer.shadowOffset = .init(width: 1, height: 1)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.6
        layer.shadowRadius = 2
    }
}
