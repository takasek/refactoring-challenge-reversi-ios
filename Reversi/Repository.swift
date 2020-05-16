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
        let turn: Disk?

        // 以下、ViewControllerのloadGameの内容を可能な限りそのままコピペ

        let input = try dataStore.read()
        var lines: ArraySlice<Substring> = input.split(separator: "\n")[...]

        guard var line = lines.popFirst() else {
            throw dataStore.readError()
        }

        do { // turn
            guard
                let diskSymbol = line.popFirst(),
                let disk = Optional<Disk>(symbol: diskSymbol.description)
                else {
                    throw dataStore.readError()
            }
            turn = disk
        }

        // players
        for side in Disk.sides {
            guard
                let playerSymbol = line.popFirst(),
                let playerNumber = Int(playerSymbol.description),
                let player = Player(rawValue: playerNumber)
                else {
                    throw dataStore.readError()
            }
            playerControls[side.index].selectedSegmentIndex = player.rawValue
        }

        do { // board
            guard lines.count == boardView.height else {
                throw dataStore.readError()
            }

            var y = 0
            while let line = lines.popFirst() {
                var x = 0
                for character in line {
                    let disk = Disk?(symbol: "\(character)").flatMap { $0 }
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
        return turn
    }
}
