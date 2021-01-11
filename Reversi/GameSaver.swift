//
//  GameSaver.swift
//  Reversi
//
//  Created by Yoshiki Tsukada on 2021/01/11.
//

import Foundation

enum GameSaver {
    static let dimention: Int = 8
    static let path: URL = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("GameData")
    
    static func save(_ turn: Disk?, _ gameBoard: [Disk?]) {
        var output: String = ""
        output.append(turn.symbol)
        output.append("\n")
        gameBoard.forEach { output.append($0.symbol) }
        try? output.write(to: path, atomically: true, encoding: .utf8)
    }
    
    static func loadGame() throws -> (turn: Disk?, gameBoard: [Disk?]) {
        let input = try String(contentsOf: path, encoding: .utf8)
        let components = input.components(separatedBy: "\n")
        
        guard let turnString = components.first else {
            throw GameLoadingError.turn
        }
        let turn = Disk?(turnString)
        
        let component = components.dropFirst()
        guard let board = component.first else {
            throw GameLoadingError.gameBoard
        }
        var gameBoard: [Disk?] = []
        board.forEach {
            gameBoard.append(Disk?(String($0)))
        }
        
        return (turn, gameBoard)
    }
}

enum GameLoadingError: Error {
    case turn
    case gameBoard
}

fileprivate extension Optional where Wrapped == Disk {
    init(_ symbol: String) {
        switch symbol {
        case "x": self = .dark
        case "o": self = .light
        case "-": self = .none
        default: preconditionFailure()
        }
    }
    
    var symbol: String {
        switch self {
        case .dark: return "x"
        case .light: return "o"
        case .none: return "-"
        }
    }
}
