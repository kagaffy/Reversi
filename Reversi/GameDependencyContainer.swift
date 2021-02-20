//
//  GameDependencyContainer.swift
//  Reversi
//
//  Created by Yoshiki Tsukada on 2021/02/06.
//

protocol GameDependencyContainerProtocol {
    func makeGameViewController() -> GameViewController
}

class GameDependencyContainer: GameDependencyContainerProtocol {
    func makeGameViewController() -> GameViewController {
        let cellViewModels = makeCellViewModels()
        let boardViewModel = makeBoardViewModel(cellViewModels: cellViewModels)
        let gameViewModel = makeGameViewModel(gameModel: GameModel(), boardViewModel: boardViewModel)
        return .init(viewModel: gameViewModel, boardViewModel: boardViewModel, cellViewModels: cellViewModels)
    }
    
    func makeGameViewModel(gameModel: GameModelProtocol, boardViewModel: BoardViewModelProtocol) -> GameViewModelProtocol {
        GameViewModel(gameModel: gameModel, boardViewModel: boardViewModel)
    }
    
    func makeBoardViewModel(cellViewModels: [CellViewModelProtocol]) -> BoardViewModelProtocol {
        BoardViewModel(cellViewModels: cellViewModels)
    }
    
    func makeCellViewModels() -> [CellViewModelProtocol] {
        (0 ..< AppConst.dimention * AppConst.dimention).map { _ in CellViewModel() }
    }
}
