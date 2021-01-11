//
//  GameViewModel.swift
//  Reversi
//
//  Created by Yoshiki Tsukada on 2021/01/04.
//

import Combine
import Foundation

protocol GameViewModelProtocol {
    var gameModel: GameModelProtocol { get }
    var turn: CurrentValueSubject<Disk?, Never> { get }
    var score: CurrentValueSubject<(dark: Int, light: Int), Never> { get }
    var pass: PassthroughSubject<Void, Never> { get }
    func getWinner() -> String?
    func getTurn() -> String?
    func reset()
}

class GameViewModel: GameViewModelProtocol {
    var gameModel: GameModelProtocol
    var boardViewModel: BoardViewModelProtocol
    
    // MARK: Send
    var turn: CurrentValueSubject<Disk?, Never> = .init(.dark)
    var score: CurrentValueSubject<(dark: Int, light: Int), Never> = .init((0, 0))
    var pass: PassthroughSubject<Void, Never> = .init()
    
    var disposables: Set<AnyCancellable> = []
    
    init(gameModel: GameModelProtocol, boardViewModel: BoardViewModelProtocol) {
        self.gameModel = gameModel
        self.boardViewModel = boardViewModel
        
        boardViewModel.tappedDiskPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] x, y in
                guard let self = self else { return }
                self.tappedDisk(atX: x, y: y)
            }
            .store(in: &disposables)
        
        gameModel.boardPublisher
            .receive(on: DispatchQueue.main)
            .sink { board in
                boardViewModel.set(board)
            }
            .store(in: &disposables)
        
        gameModel.puttableCoordinatesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [boardViewModel] coordinates in
                boardViewModel.highlight(coordinates)
            }
            .store(in: &disposables)
        
        gameModel.diskMovePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] put, flip in
                guard let self = self else { return }
                guard let player = self.turn.value else { return }
                boardViewModel.onAnimating.send(true)
                boardViewModel.putAndFlipDisk(of: player, put, flip) { [gameModel, boardViewModel] _ in
                    gameModel.calculateScore()
                    gameModel.nextTurn()
                    boardViewModel.onAnimating.send(false)
                }
            }
            .store(in: &disposables)
        
        gameModel.turnPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] turn in
                guard let self = self else { return }
                self.turn.send(turn)
            }
            .store(in: &disposables)
        
        gameModel.scorePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dark, light in
                guard let self = self else { return }
                self.score.send((dark, light))
            }
            .store(in: &disposables)
        
        gameModel.passPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.pass.send()
            }
            .store(in: &disposables)
        
        gameModel.loadGame()
    }
    
    private func tappedDisk(atX x: Int, y: Int) {
        // TODO: 入力受付中でなかったら何もしない
        guard let player = turn.value else { return }
        gameModel.tryPutDiskAndFlip(of: player, atx: x, y: y)
    }
    
    func getWinner() -> String? {
        let (dark, light) = score.value
        if dark == light { return nil }
        if dark > light { return "Dark" }
        return "Light"
    }
    
    func getTurn() -> String? {
        guard let player = turn.value else { return nil }
        if player == .dark { return "Dark" }
        return "Light"
    }
    
    func reset() {
        gameModel.reset()
    }
}
