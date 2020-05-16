//
//  State.swift
//  Reversi
//
//  Created by Yoshitaka Seki on 2020/04/24.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import UIKit

struct Point: Equatable {
    let x: Int
    let y: Int

    init(_ x: Int, _ y: Int) { self.x = x; self.y = y }
}

struct State: Equatable {
    /// どちらの色のプレイヤーのターンかを表します。ゲーム終了時は `nil` です。
    var turn: Disk?

    let playerA: Player
    let playerB: Player
    let board: [[Disk?]]

    var yRange: Range<Int> { 0 ..< board.count }
    var xRange: Range<Int> { 0 ..< (board.first?.count ?? 0) }

    func diskAt(x: Int, y: Int) -> Disk? {
        guard xRange.contains(x) && yRange.contains(y) else { return nil }
        return board[y][x]
    }

    func countDisks(of side: Disk) -> Int {
        board.reduce(0) { acc, line in
            line.reduce(acc) { acc, disk in
                acc + (disk == side ? 1 : 0 )
            }
        }
    }
    func sideWithMoreDisks() -> Disk? {
        let darkCount = countDisks(of: .dark)
        let lightCount = countDisks(of: .light)
        if darkCount == lightCount {
            return nil
        } else {
            return darkCount > lightCount ? .dark : .light
        }
    }
    func flippedDiskCoordinatesByPlacingDisk(_ disk: Disk, atX x: Int, y: Int) -> [Point] {
        let directions = [
            Point(-1, -1),
            Point( 0, -1),
            Point( 1, -1),
            Point( 1,  0),
            Point( 1,  1),
            Point( 0,  1),
            Point(-1,  0),
            Point(-1,  1),
        ]

        guard diskAt(x: x, y: y) == nil else {
            return []
        }

        var diskCoordinates: [Point] = []

        for direction in directions {
            var x = x
            var y = y

            var diskCoordinatesInLine: [Point] = []
            flipping: while true {
                x += direction.x
                y += direction.y

                switch (disk, diskAt(x: x, y: y)) { // Uses tuples to make patterns exhaustive
                case (.dark, .some(.dark)), (.light, .some(.light)):
                    diskCoordinates.append(contentsOf: diskCoordinatesInLine)
                    break flipping
                case (.dark, .some(.light)), (.light, .some(.dark)):
                    diskCoordinatesInLine.append(Point(x, y))
                case (_, .none):
                    break flipping
                }
            }
        }

        return diskCoordinates
    }
    func canPlaceDisk(_ disk: Disk, atX x: Int, y: Int) -> Bool {
        !flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y).isEmpty
    }
    func validMoves(for side: Disk) -> [Point] {
        var coordinates: [Point] = []

        for y in yRange {
            for x in xRange {
                if canPlaceDisk(side, atX: x, y: y) {
                    coordinates.append(Point(x, y))
                }
            }
        }

        return coordinates
    }

    var description: String {
        var output: String = ""
        output += turn.symbol
        output += playerA.rawValue.description
        output += playerB.rawValue.description
        output += "\n"

        for line in board {
            for disk in line {
                output += disk.symbol
            }
            output += "\n"
        }
        return output
    }
}

extension State {
    static func new(size: Int) -> Self {
        assert(size.isMultiple(of: 2))
        assert(size >= 2)

        return self.init(turn: .dark, playerA: .manual, playerB: .manual, board: {
            var blankBoard = [[Disk?]](
                repeating: [Disk?](repeating: nil, count: size),
                count: size
            )
            let largerIndex = size / 2
            blankBoard[largerIndex][largerIndex] = .light
            blankBoard[largerIndex][largerIndex - 1] = .dark
            blankBoard[largerIndex - 1][largerIndex] = .dark
            blankBoard[largerIndex - 1][largerIndex - 1] = .light

            return blankBoard
        }())
    }
    init?(input: String) {
        var lines: ArraySlice<Substring> = input.split(separator: "\n")[...]

        guard var line = lines.popFirst() else {
            return nil
        }

        do { // turn
            guard
                let diskSymbol = line.popFirst(),
                let disk = Optional<Disk>(symbol: diskSymbol.description)
                else {
                    return nil
            }
            turn = disk
        }

        // players
        func popPlayerFromLine() -> Player? {
            line
                .popFirst()
                .flatMap { Int($0.description) }
                .flatMap { Player(rawValue: $0) }
        }
        guard let a = popPlayerFromLine() else { return nil }
        playerA = a
        guard let b = popPlayerFromLine() else { return nil }
        playerB = b

        var board: [[Disk?]] = []
        while let line = lines.popFirst() {
            var boardLine: [Disk?] = []
            for character in line {
                boardLine.append(Disk?(symbol: "\(character)").flatMap { $0 })
            }
            board.append(boardLine)
        }
        self.board = board
    }
}
