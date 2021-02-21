//
//  GameDependencyContainer.swift
//  Reversi
//
//  Created by Yoshiki Tsukada on 2021/02/06.
//

protocol GameDependencyContainerProtocol {
    func makeGameViewController() -> GameViewController
}

final class GameDependencyContainer: GameDependencyContainerProtocol {
    private let cellViewModels: [CellViewModelProtocol]
    private let boardViewModel: BoardViewModelProtocol
    private let gameModel: GameModelProtocol
    private let gameViewModel: GameViewModelProtocol

    init() {
        func makeCellViewModels() -> [CellViewModelProtocol] {
            (0 ..< AppConst.dimention * AppConst.dimention).map { _ in CellViewModel() }
        }
        func makeBoardViewModel(cellViewModels: [CellViewModelProtocol]) -> BoardViewModelProtocol {
            BoardViewModel(cellViewModels: cellViewModels)
        }
        func makeGameModel() -> GameModelProtocol {
            GameModel()
        }
        func makeGameViewModel(gameModel: GameModelProtocol, boardViewModel: BoardViewModelProtocol) -> GameViewModelProtocol {
            GameViewModel(gameModel: gameModel, boardViewModel: boardViewModel)
        }

        cellViewModels = makeCellViewModels()
        boardViewModel = makeBoardViewModel(cellViewModels: cellViewModels)
        gameModel = makeGameModel()
        gameViewModel = makeGameViewModel(gameModel: gameModel, boardViewModel: boardViewModel)
    }

    func makeGameViewController() -> GameViewController {
        return .init(viewModel: gameViewModel, boardViewModel: boardViewModel, cellViewModels: cellViewModels)
    }
}
