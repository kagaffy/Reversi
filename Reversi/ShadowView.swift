//
//  ShadowView.swift
//  Reversi
//
//  Created by Yoshiki Tsukada on 2021/01/04.
//

import UIKit

class ShadowView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = .systemBackground
        clipsToBounds = true
        layer.cornerRadius = 10
        layer.masksToBounds = false
        layer.shadowOffset = .init(width: 1, height: 1)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.6
        layer.shadowRadius = 2
    }
}
