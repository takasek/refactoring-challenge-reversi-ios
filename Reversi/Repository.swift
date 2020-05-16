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

class Repository {
    init() {}

    enum FileIOError: Error {
        case write(path: String, cause: Error?)
        case read(path: String, cause: Error?)
    }

    private var path: String {
        (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("Game")
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

        do {
            try output.write(toFile: path, atomically: true, encoding: .utf8)
        } catch let error {
            throw FileIOError.read(path: path, cause: error)
        }
    }

    // TODO: UIコンポーネントの参照をたらい回ししない
    func loadGame(playerControls: [UISegmentedControl], boardView: BoardView) throws -> Disk? {
        let turn: Disk?

        // 以下、ViewControllerのloadGameの内容を可能な限りそのままコピペ

        let input = try String(contentsOfFile: path, encoding: .utf8)
        var lines: ArraySlice<Substring> = input.split(separator: "\n")[...]

        guard var line = lines.popFirst() else {
            throw FileIOError.read(path: path, cause: nil)
        }

        do { // turn
            guard
                let diskSymbol = line.popFirst(),
                let disk = Optional<Disk>(symbol: diskSymbol.description)
                else {
                    throw FileIOError.read(path: path, cause: nil)
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
                    throw FileIOError.read(path: path, cause: nil)
            }
            playerControls[side.index].selectedSegmentIndex = player.rawValue
        }

        do { // board
            guard lines.count == boardView.height else {
                throw FileIOError.read(path: path, cause: nil)
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
                    throw FileIOError.read(path: path, cause: nil)
                }
                y += 1
            }
            guard y == boardView.height else {
                throw FileIOError.read(path: path, cause: nil)
            }
        }

        // 値渡しになるのはturnだけ
        return turn
    }
}
