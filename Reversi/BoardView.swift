//
//  BoardView.swift
//  Reversi
//
//  Created by Yoshiki Tsukada on 2020/12/27.
//

import UIKit

class BoardView: UIView {
    private let borderWidth: CGFloat = 2
    private var cellViews: [CellView] = []
    
    var viewModel: BoardViewModelProtocol!
    
    init(viewModel: BoardViewModelProtocol, cellViewModels: [CellViewModelProtocol]) {
        func makeCellViews() -> [CellView] {
            cellViewModels.map { CellView(viewModel: $0) }
        }
        
        self.viewModel = viewModel
        cellViews = makeCellViews()
        super.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setShadow()
        viewModel = makeViewModel()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setShadow()
        viewModel = makeViewModel()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupLayout()
    }
    
    private func makeViewModel() -> BoardViewModelProtocol {
        let cellViewModels = cellViews.map { $0.viewModel! }
        return BoardViewModel(cellViewModels: cellViewModels)
    }
    
    private func setupViews() {
        backgroundColor = .black
        
        let vStack = UIStackView()
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis = .vertical
        vStack.distribution = .equalSpacing
        addSubview(vStack)
        for _ in 0..<AppConst.dimention {
            let hStack = UIStackView()
            hStack.translatesAutoresizingMaskIntoConstraints = false
            hStack.distribution = .equalSpacing
            for _ in 0..<AppConst.dimention {
                let cellView = CellView()
                cellView.translatesAutoresizingMaskIntoConstraints = false
                hStack.addArrangedSubview(cellView)
                cellViews.append(cellView)
            }
            vStack.addArrangedSubview(hStack)
        }
        
        NSLayoutConstraint.activate([
            vStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: borderWidth),
            vStack.topAnchor.constraint(equalTo: topAnchor, constant: borderWidth),
            vStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -borderWidth),
            vStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -borderWidth),
        ])
    }
    
    private func setupLayout() {
        let cellViewWidth: CGFloat = .init((bounds.width - borderWidth*(CGFloat(AppConst.dimention+1))) / CGFloat(AppConst.dimention))
        cellViews.forEach {
            NSLayoutConstraint.activate([
                $0.widthAnchor.constraint(equalToConstant: cellViewWidth),
                $0.heightAnchor.constraint(equalToConstant: cellViewWidth),
            ])
        }
    }
    
    private func setShadow() {
        layer.masksToBounds = false
        layer.shadowOffset = .init(width: 2, height: 2)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.6
        layer.shadowRadius = 10
    }
}
