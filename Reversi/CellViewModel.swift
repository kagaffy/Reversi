//
//  CellViewModel.swift
//  Reversi
//
//  Created by Yoshiki Tsukada on 2021/01/04.
//

import Combine

protocol CellViewModelProtocol {
    var diskState: CurrentValueSubject<(oldState: Disk?, newState: Disk?, animated: Bool), Never> { get }
    var didTapButton: PassthroughSubject<Void, Never> { get }
    func putDisk(of side: Disk?, animated: Bool)
    func flipDisk()
    func reset()
    func buttonTapped()
}

class CellViewModel: CellViewModelProtocol {
    var diskState: CurrentValueSubject<(oldState: Disk?, newState: Disk?, animated: Bool), Never> = .init((nil, nil, false))
    var didTapButton: PassthroughSubject<Void, Never> = .init()
    
    func putDisk(of side: Disk?, animated: Bool) {
        let state = (oldState: diskState.value.newState, newState: side, animated: animated)
        diskState.send(state)
    }
    
    func flipDisk() {
        let state = (oldState: diskState.value.newState, newState: diskState.value.newState?.flipped, animated: true)
        diskState.send(state)
    }
    
    func reset() {
        diskState.send((nil, nil, false))
    }
    
    func buttonTapped() {
        didTapButton.send()
    }
}
