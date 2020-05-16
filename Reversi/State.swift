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
    let turn: Disk?
    let players: [Player]
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
        output += players.reduce("") { $0 + $1.rawValue.description }
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
        var players: [Player] = []
        for _ in Disk.sides {
            guard
                let playerSymbol = line.popFirst(),
                let playerNumber = Int(playerSymbol.description),
                let player = Player(rawValue: playerNumber)
                else {
                    return nil
            }
            players.append(player)
        }
        self.players = players

        do { // board
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
}
