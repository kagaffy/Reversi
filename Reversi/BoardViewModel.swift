//
//  BoardViewModel.swift
//  Reversi
//
//  Created by Yoshiki Tsukada on 2021/01/04.
//

import Combine
import Foundation

protocol BoardViewModelProtocol {
    var tappedDiskPublisher: PassthroughSubject<(x: Int, y: Int), Never> { get }
    var onAnimating: CurrentValueSubject<Bool, Never> { get }
    func set(_ board: [Disk?])
    func highlight(_ puttableCoordinates: [(x: Int, y: Int)])
    func putAndFlipDisk<Flip: Collection>(of side: Disk, _ put: (x: Int, y: Int)?, _ flip: Flip, completion: ((Bool) -> Void)?) where Flip.Element == (x: Int, y: Int)
}

class BoardViewModel: BoardViewModelProtocol {
    let cellViewModels: [CellViewModelProtocol]

    // MARK: Send
    var tappedDiskPublisher: PassthroughSubject<(x: Int, y: Int), Never> = .init()
    var onAnimating: CurrentValueSubject<Bool, Never> = .init(false)

    // MARK: Receive
    var onWaitingInput: CurrentValueSubject<Bool, Never> = .init(true)
    var diskMovePublisher: PassthroughSubject<(put: (x: Int, y: Int), flip: [(x: Int, y: Int)]), Never> = .init()

    var disposables: Set<AnyCancellable> = []

    init(cellViewModels: [CellViewModelProtocol]) {
        self.cellViewModels = cellViewModels

        for (index, viewModel) in cellViewModels.enumerated() {
            let x: Int = index / AppConst.dimention
            let y: Int = index % AppConst.dimention
            viewModel.didTapButton
                .filter { [weak self] in
                    guard let self = self else { return false }
                    return !self.onAnimating.value
                }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    guard let self = self else { return }
                    self.tappedDisk(atX: x, y: y)
                }
                .store(in: &disposables)
        }
    }

    private func tappedDisk(atX x: Int, y: Int) {
        tappedDiskPublisher.send((x, y))
    }

    private func cellViewModel(atX x: Int, y: Int) -> CellViewModelProtocol {
        guard (0 ..< AppConst.dimention).contains(x), (0 ..< AppConst.dimention).contains(y) else { preconditionFailure() }
        return cellViewModels[AppConst.dimention * x + y]
    }

    func set(_ board: [Disk?]) {
        for (viewModel, disk) in zip(cellViewModels, board) {
            viewModel.putDisk(of: disk, animated: false)
        }
    }

    func highlight(_ puttableCoordinates: [(x: Int, y: Int)]) {
        cellViewModels.forEach { $0.highlight(false) }
        for (x, y) in puttableCoordinates {
            cellViewModel(atX: x, y: y).highlight(true)
        }
    }

    /// `Disk`を置いて裏返す
    /// すべてのアニメーションが完了したら`completion`が呼ばれる
    func putAndFlipDisk<Flip: Collection>(of side: Disk, _ put: (x: Int, y: Int)?, _ flip: Flip, completion: ((Bool) -> Void)? = nil) where Flip.Element == (x: Int, y: Int) {
        guard let (x, y) = flip.first else {
            Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [completion] _ in
                completion?(true)
            }
            return
        }
        guard let put = put else {
            cellViewModel(atX: x, y: y).flipDisk()
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.putAndFlipDisk(of: side, nil, flip.dropFirst(), completion: completion)
            }
            return
        }
        cellViewModel(atX: put.x, y: put.y).putDisk(of: side, animated: true)
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.putAndFlipDisk(of: side, nil, flip, completion: completion)
        }
    }
}
