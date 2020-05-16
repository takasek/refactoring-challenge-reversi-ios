//
//  Repository.swift
//  Reversi
//
//  Created by Yoshitaka Seki on 2020/05/16.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

// TODO: UIKitに依存しないようにする。今はシグネチャをできるだけ変えないため許容
// import Foundation
import UIKit

enum FileIOError: Error {
    case write(path: String, cause: Error?)
    case read(path: String, cause: Error?)
}
protocol DataStore {
    mutating func write(string: String) throws
    func read() throws -> String
    func readError() -> Error
}
class DataStoreImpl: DataStore {
    private var path: String {
        (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Game")
    }
    func write(string: String) throws {
        do {
            try string.write(toFile: path, atomically: true, encoding: .utf8)
        } catch let error {
            throw FileIOError.read(path: path, cause: error)
        }
    }
    func read() throws -> String {
        try String(contentsOfFile: path, encoding: .utf8)
    }

    func readError() -> Error {
        FileIOError.read(path: path, cause: nil)
    }
}

class Repository {
    private(set) var dataStore: DataStore

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    // TODO: 事前条件を狭める
    func saveGame(turn: Disk?, playerControls: [UISegmentedControl], boardView: BoardView) throws {
        // 以下、ViewControllerのsaveGameの内容を可能な限りそのままコピペ

        var output: String = ""
        output += turn.symbol
        for side in Disk.sides {
            output += playerControls[side.index].selectedSegmentIndex.description
        }
        output += "\n"

        for y in boardView.yRange {
            for x in boardView.xRange {
                output += boardView.diskAt(x: x, y: y).symbol
            }
            output += "\n"
        }

        try dataStore.write(string: output)
    }

    // TODO: UIコンポーネントの参照をたらい回ししない
    func loadGame(playerControls: [UISegmentedControl], boardView: BoardView) throws -> Disk? {

        // デシリアライズはState.initに置きかえ可能

        guard let state = State(input: try dataStore.read()) else {
            throw dataStore.readError()
        }

        // UIへの適用

        for (side, player) in zip(Disk.sides, state.players) {
            playerControls[side.index].selectedSegmentIndex = player.rawValue
        }
        do { // board
            var boardSlice = ArraySlice(state.board)
            guard boardSlice.count == boardView.height else {
                throw dataStore.readError()
            }

            var y = 0
            while let boardLine = boardSlice.popFirst() {
                var x = 0
                for disk in boardLine {
                    boardView.setDisk(disk, atX: x, y: y, animated: false)
                    x += 1
                }
                guard x == boardView.width else {
                    throw dataStore.readError()
                }
                y += 1
            }
            guard y == boardView.height else {
                throw dataStore.readError()
            }
        }

        // 値渡しになるのはturnだけ
        return state.turn
    }
}
