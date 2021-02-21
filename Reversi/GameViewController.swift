//
//  GameViewController.swift
//  Reversi
//
//  Created by Yoshiki Tsukada on 2020/12/27.
//

import UIKit
import Combine

final class GameViewController: UIViewController {
    private let boardView: BoardView
    private lazy var scoreLabels: [UILabel] = makeScoreLabels()
    private lazy var turnLabels: [UILabel] = makeTurnLabels()
    private let resetButton: ResetButton = .init()
    
    private let viewModel: GameViewModelProtocol
    private var disposables: Set<AnyCancellable> = []
    
    init(viewModel: GameViewModelProtocol, boardViewModel: BoardViewModelProtocol, cellViewModels: [CellViewModelProtocol]) {
        func makeBoardView() -> BoardView {
            let boardView = BoardView(viewModel: boardViewModel, cellViewModels: cellViewModels)
            boardView.translatesAutoresizingMaskIntoConstraints = false
            return boardView
        }
        
        self.viewModel = viewModel
        boardView = makeBoardView()
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bind(viewModel)
    }
    
    private func bind(_ viewModel: GameViewModelProtocol) {
        viewModel.turn
            .receive(on: DispatchQueue.main)
            .sink { [weak self, viewModel] turn in
                guard let self = self else { return }
                if turn == nil {
                    if let winner = viewModel.getWinner() {
                        self.showAlert(title: "\(winner) wins.", message: "The game is over.")
                    } else {
                        self.showAlert(title: "Draw.", message: "The game is over.")
                    }
                }
                self.turnLabels[0].isHidden = turn != .dark
                self.turnLabels[1].isHidden = turn != .light
            }
            .store(in: &disposables)
        
        viewModel.score
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dark, light in
                guard let self = self else { return }
                self.scoreLabels[0].text = String(dark)
                self.scoreLabels[1].text = String(light)
            }
            .store(in: &disposables)
        
        viewModel.pass
            .receive(on: DispatchQueue.main)
            .sink { [weak self, viewModel] in
                guard let self = self else { return }
                guard let player = viewModel.getTurn() else { return }
                self.showAlert(title: "Pass.", message: "\(player)'s turn.")
            }
            .store(in: &disposables)
    }
    
    private func showAlert(title: String, message: String, shouldShowCancel: Bool = false, handler: ((UIAlertAction) -> Void)? = nil) {
        let alertController: UIAlertController = .init(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(.init(title: "OK", style: .default, handler: handler))
        if shouldShowCancel {
            alertController.addAction(.init(title: "Cancel", style: .cancel))
        }
        present(alertController, animated: true)
    }
    
    @objc func resetButtonTapped() {
        showAlert(title: "Confirmation.", message: "Do you really want to reset the game?", shouldShowCancel: true) { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.reset()
        }
    }
}

// MARK: Views
extension GameViewController {
    private func setupViews() {
        // view
        view.backgroundColor = .systemBackground
        // boardView
        view.addSubview(boardView)
        // dark turn
        let darkSideContainerView = makePlayerSideContainerView(side: .dark, scoreLabel: scoreLabels[0], turnLabel: turnLabels[0])
        view.addSubview(darkSideContainerView)
        // light turn
        let lightSideContainerView = makePlayerSideContainerView(side: .light, scoreLabel: scoreLabels[1], turnLabel: turnLabels[1])
        view.addSubview(lightSideContainerView)
        // resetButton
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        view.addSubview(resetButton)
        // constraint
        NSLayoutConstraint.activate([
            // boardView
            boardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            boardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            boardView.heightAnchor.constraint(equalTo: boardView.widthAnchor),
            boardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            // dark turn
            darkSideContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            darkSideContainerView.bottomAnchor.constraint(equalTo: boardView.topAnchor, constant: -30),
            // light turn
            lightSideContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25),
            lightSideContainerView.topAnchor.constraint(equalTo: boardView.bottomAnchor, constant: 30),
            // resetButton
            resetButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resetButton.widthAnchor.constraint(equalToConstant: 100),
        ])
    }
    
    private func makeScoreLabels() -> [UILabel] {
        let labels: [UILabel] = [.init(), .init()]
        labels.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        return labels
    }
    
    private func makeTurnLabels() -> [UILabel] {
        let labels: [UILabel] = [.init(), .init()]
        labels.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.text = "Your turn."
        }
        return labels
    }
    
    private func makePlayerSideContainerView(side: Disk, scoreLabel: UILabel, turnLabel: UILabel) -> ShadowView {
        let color: UIColor = {
            switch side {
            case .dark: return .black
            case .light: return .white
            }
        }()
        
        // diskView
        let diskView = DiskView()
        diskView.translatesAutoresizingMaskIntoConstraints = false
        diskView.backgroundColor = color
        // stackView
        let stackView = UIStackView(arrangedSubviews: [
            diskView,
            scoreLabel,
            turnLabel,
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.spacing = 10
        // containerView
        let containerView = ShadowView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)
        // constraint
        NSLayoutConstraint.activate([
            // stackView
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
            // diskView
            diskView.widthAnchor.constraint(equalToConstant: 30),
            diskView.heightAnchor.constraint(equalToConstant: 30),
        ])
        
        return containerView
    }
}
