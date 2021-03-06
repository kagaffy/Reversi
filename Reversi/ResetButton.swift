//
//  ResetButton.swift
//  Reversi
//
//  Created by Yoshiki Tsukada on 2021/01/04.
//

import UIKit

class ResetButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
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
        setTitle("Reset", for: .normal)
        setTitleColor(.link, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 25)
    }
}
