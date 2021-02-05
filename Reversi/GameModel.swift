//
//  GameModel.swift
//  Reversi
//
//  Created by Yoshiki Tsukada on 2021/01/04.
//

import Combine
import Foundation

protocol GameModelProtocol {
    var boardPublisher: PassthroughSubject<[Disk?], Never> { get }
    var diskMovePublisher: PassthroughSubject<(put: (x: Int, y: Int), flip: [(x: Int, y: Int)]), Never> { get }
    var puttableCoordinatesPublisher: PassthroughSubject<[(x: Int, y: Int)], Never> { get }
    var turnPublisher: CurrentValueSubject<Disk?, Never> { get }
    var scorePublisher: PassthroughSubject<(dark: Int, light: Int), Never> { get }
    var passPublisher: PassthroughSubject<Void, Never> { get }
    func loadGame()
    func reset()
    func calculateScore()
    func tryPutDiskAndFlip(of side: Disk, atx x: Int, y: Int)
    func nextTurn()
}

/// UI以外のゲームの状態を保持し、ロジックや保存などを行う
class GameModel: GameModelProtocol {
    private var gameBoard: [Disk?] = []
    private let directions: [(x: Int, y: Int)] = [
        (x: -1, y: 0),
        (x: -1, y: -1),
        (x: 0, y: -1),
        (x: 1, y: -1),
        (x: 1, y: 0),
        (x: 1, y: 1),
        (x: 0, y: 1),
        (x: -1, y: 1),
    ]
    
    // MARK: Send
    var boardPublisher: PassthroughSubject<[Disk?], Never> = .init()
    var diskMovePublisher: PassthroughSubject<(put: (x: Int, y: Int), flip: [(x: Int, y: Int)]), Never> = .init()
    var puttableCoordinatesPublisher: PassthroughSubject<[(x: Int, y: Int)], Never> = .init()
    var turnPublisher: CurrentValueSubject<Disk?, Never> = .init(.dark)
    var scorePublisher: PassthroughSubject<(dark: Int, light: Int), Never> = .init()
    var passPublisher: PassthroughSubject<Void, Never> = .init()
    
    func loadGame() {
        do {
            let (turn, gameBoard) = try GameSaver.loadGame()
            self.gameBoard = gameBoard
            turnPublisher.send(turn)
            boardPublisher.send(gameBoard)
            if let turn = turnPublisher.value {
                puttableCoordinatesPublisher.send(validCoordinates(for: turn))
            }
            calculateScore()
        } catch {
            reset()
        }
    }
    
    func reset() {
        let d = AppConst.dimention
        turnPublisher.value = .dark
        gameBoard = .init(repeating: nil, count: d * d)
        put(.light, atX: d / 2 - 1, y: d / 2 - 1)
        put(.dark, atX: d / 2 - 1, y: d / 2)
        put(.dark, atX: d / 2, y: d / 2 - 1)
        put(.light, atX: d / 2, y: d / 2)
        boardPublisher.send(gameBoard)
        scorePublisher.send((2, 2))
        puttableCoordinatesPublisher.send(validCoordinates(for: .dark))
        GameSaver.save(turnPublisher.value, gameBoard)
    }
    
    private func put(_ disk: Disk, atX x: Int, y: Int) {
        guard (0..<AppConst.dimention).contains(x), (0..<AppConst.dimention).contains(y) else { preconditionFailure() }
        gameBoard[AppConst.dimention*x + y] = disk
    }
    
    private func flipDisk(atX x: Int, y: Int) {
        guard (0..<AppConst.dimention).contains(x), (0..<AppConst.dimention).contains(y) else { preconditionFailure() }
        guard disk(atX: x, y: y) != nil else { preconditionFailure()}
        gameBoard[AppConst.dimention*x + y]?.flip()
    }
    
    private func disk(atX x: Int, y: Int) -> Disk? {
        guard (0..<AppConst.dimention).contains(x), (0..<AppConst.dimention).contains(y) else { return nil }
        return gameBoard[AppConst.dimention*x + y]
    }
    
    /// `gameBoard`の`x`, `y`で与えられた座標に`side`のDiskを置いた場合に裏返せるセルの座標集合を返す
    private func flippableCoordinatesIfPutDisk(of side: Disk, atX x: Int, y: Int) -> [(x: Int, y: Int)] {
        guard (0..<AppConst.dimention).contains(x), (0..<AppConst.dimention).contains(y) else { return [] }
        guard disk(atX: x, y: y) == nil else { return [] }
        // 周囲8近傍に相手のDiskがなかったら空
        var validDirections: [(x: Int, y: Int)] = []
        directions.forEach {
            if disk(atX: x + $0.x, y: y + $0.y) == side.flipped {
                validDirections.append($0)
            }
        }
        if validDirections.isEmpty { return [] }
        // 周囲8近傍をまっすぐ辿っていき、自分のDiskにたどり着いたらOK
        var flippableCoordinates: [(x: Int, y: Int)] = []
        validDirections.forEach { direction in
            var coordinates: [(x: Int, y: Int)] = []
            var x = x
            var y = y
            repeat {
                x += direction.x
                y += direction.y
                coordinates.append((x: x, y: y))
            } while disk(atX: x, y: y) == side.flipped
            if disk(atX: x, y: y) == side {
                flippableCoordinates.append(contentsOf: coordinates.dropLast())
            }
        }
        return flippableCoordinates
    }
    
    /// `gameBoard`の`x`, `y`で与えられた座標に`side`のDiskを置けるかと、裏返せる座標集合を返す
    private func canPutDisk(of side: Disk, atX x: Int, y: Int) -> (Bool, [(x: Int, y: Int)]) {
        let flippableCoordinates = flippableCoordinatesIfPutDisk(of: side, atX: x, y: y)
        return (!flippableCoordinates.isEmpty, flippableCoordinates)
    }
    
    private func validCoordinates(for side: Disk) -> [(x: Int, y: Int)] {
        var coordinates: [(x: Int, y: Int)] = []
        for x in 0..<AppConst.dimention {
            for y in 0..<AppConst.dimention {
                let (canPut, _) = canPutDisk(of: side, atX: x, y: y)
                if canPut { coordinates.append((x: x, y: y)) }
            }
        }
        return coordinates
    }
    
    private func pass() {
        passPublisher.send()
    }
    
    func calculateScore() {
        var dark = 0
        var light = 0
        gameBoard.forEach {
            switch $0 {
            case .dark: dark += 1
            case .light: light += 1
            default: break
            }
        }
        scorePublisher.send((dark, light))
    }
    
    func tryPutDiskAndFlip(of side: Disk, atx x: Int, y: Int) {
        let (canPut, flippableCoordinates) = canPutDisk(of: side, atX: x, y: y)
        guard canPut else { return }
        
        put(side, atX: x, y: y)
        flippableCoordinates.forEach {
            flipDisk(atX: $0.x, y: $0.y)
        }
        diskMovePublisher.send((put: (x, y), flip: flippableCoordinates))
    }
    
    func nextTurn() {
        guard let turn = turnPublisher.value else { return }
        if validCoordinates(for: turn.flipped).isEmpty {
            if validCoordinates(for: turn).isEmpty {
                // TODO: ゲームセット
                turnPublisher.send(nil)
                puttableCoordinatesPublisher.send([])
                GameSaver.save(turnPublisher.value, gameBoard)
                return
            } else {
                // TODO: pass
                pass()
                puttableCoordinatesPublisher.send(validCoordinates(for: turn))
                GameSaver.save(turnPublisher.value, gameBoard)
                return
            }
        }
        // TODO: 次のターン
        turnPublisher.send(turn.flipped)
        puttableCoordinatesPublisher.send(validCoordinates(for: turn.flipped))
        GameSaver.save(turnPublisher.value, gameBoard)
    }
}
