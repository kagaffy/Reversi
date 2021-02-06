//
//  GameViewController.swift
//  Reversi
//
//  Created by Yoshiki Tsukada on 2020/12/27.
//

import UIKit
import Combine

final class GameViewController: UIViewController {
    @IBOutlet private var boardView: BoardView!
    @IBOutlet private var scoreLabels: [UILabel]!
    @IBOutlet private var turnLabels: [UILabel]!
    
    private var viewModel: GameViewModelProtocol!
    private var disposables: Set<AnyCancellable> = []
    
    init(viewModel: GameViewModelProtocol, boardViewModel: BoardViewModelProtocol, cellViewModels: [CellViewModelProtocol]) {
        func makeBoardView() -> BoardView {
            .init(viewModel: boardViewModel, cellViewModels: cellViewModels)
        }
        
        self.viewModel = viewModel
        boardView = makeBoardView()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = makeViewModel()
        bind(viewModel)
    }
    
    private func makeViewModel() -> GameViewModelProtocol {
        GameViewModel(gameModel: GameModel(), boardViewModel: boardView.viewModel!)
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
    
    @IBAction func resetButtonTapped(_ sender: Any) {
        showAlert(title: "Confirmation.", message: "Do you really want to reset the game?", shouldShowCancel: true) { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.reset()
        }
    }
}
