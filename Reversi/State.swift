//
//  State.swift
//  Reversi
//
//  Created by Yoshitaka Seki on 2020/04/24.
//  Copyright © 2020 Yuta Koshizawa. All rights reserved.
//

import UIKit

struct State: Equatable {
    let turn: Disk?
    let players: [Player]
    let board: [[Disk?]]

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
