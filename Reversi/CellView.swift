//
//  CellView.swift
//  Reversi
//
//  Created by Yoshiki Tsukada on 2021/01/04.
//

import UIKit
import Combine

class CellView: UIView {
    private let button: UIButton = .init()
    private let diskView: DiskView = .init()
    
    private let normalColor: UIColor = #colorLiteral(red: 0.3529411765, green: 0.4549019608, blue: 0.3098039216, alpha: 1)
    private let puttableColor: UIColor = #colorLiteral(red: 0.4431372549, green: 0.568627451, blue: 0.3882352941, alpha: 1)
    
    var viewModel: CellViewModelProtocol!
    private var disposables: Set<AnyCancellable> = []
    
    init(viewModel: CellViewModelProtocol) {
        self.viewModel = viewModel
        super.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        viewModel = makeViewModel()
        setupViews()
        bind(viewModel)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        viewModel = makeViewModel()
        setupViews()
        bind(viewModel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupLayout()
    }
    
    private func makeViewModel() -> CellViewModelProtocol {
        CellViewModel()
    }
    
    private func bind(_ viewModel: CellViewModelProtocol) {
        viewModel.diskState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] old, new, animated in
                guard let self = self else { return }
                switch (old, new) {
                case let (.none, .some(side)):
                    // TODO: completion
                    self.putDisk(of: side, animated: animated, completion: nil)
                case let (.some, .some(side)):
                    // TODO: completion
                    self.flip(to: side, animated: animated, completion: nil)
                case (.some, .none):
                    self.reset()
                default: break
                }
            }
            .store(in: &disposables)
        
        viewModel.canPutState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canPut in
                guard let self = self else { return }
                self.setBackgroundImage(color: canPut ? self.puttableColor : self.normalColor)
            }
            .store(in: &disposables)
    }
    
    private func setupViews() {
        backgroundColor = normalColor
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        diskView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(diskView)
        diskView.isUserInteractionEnabled = false
        diskView.alpha = 0
    }
    
    private func setupLayout() {
        let diskViewWidth: CGFloat = bounds.width * 0.7
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            diskView.widthAnchor.constraint(equalToConstant: diskViewWidth),
            diskView.heightAnchor.constraint(equalToConstant: diskViewWidth),
            diskView.centerXAnchor.constraint(equalTo: centerXAnchor),
            diskView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        diskView.clipsToBounds = true
        diskView.layer.cornerRadius = diskViewWidth / 2
    }
    
    private func setBackgroundImage(color: UIColor) {
        UIGraphicsBeginImageContext(.init(width: 1, height: 1))
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(.init(x: 0, y: 0, width: 1, height: 1))
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        button.setBackgroundImage(image, for: .normal)
    }
    
    @objc func buttonTapped() {
        viewModel.buttonTapped()
    }
    
    /// セルを初期状態に戻す
    func reset() {
        diskView.alpha = 0
    }
    
    func putDisk(of side: Disk, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        diskView.backgroundColor = side.color
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.diskView.alpha = 1
            }, completion: { finished in
                completion?(finished)
            })
        } else {
            diskView.alpha = 1
            completion?(true)
        }
    }
    
    func flip(to side: Disk, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        if animated {
            UIView.transition(with: diskView, duration: 0.3, options: [.transitionFlipFromLeft], animations: {
                self.diskView.backgroundColor = side.color
            }, completion: { finished in
                completion?(finished)
            })
        } else {
            diskView.backgroundColor = side.color
            completion?(true)
        }
    }
}
