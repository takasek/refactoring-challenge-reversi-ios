import UIKit

class ViewController: UIViewController {
    @IBOutlet private var boardView: BoardView!

    @IBOutlet private var messageDiskView: DiskView!
    @IBOutlet private var messageLabel: UILabel!
    @IBOutlet private var messageDiskSizeConstraint: NSLayoutConstraint!
    /// Storyboard 上で設定されたサイズを保管します。
    /// 引き分けの際は `messageDiskView` の表示が必要ないため、
    /// `messageDiskSizeConstraint.constant` を `0` に設定します。
    /// その後、新しいゲームが開始されたときに `messageDiskSize` を
    /// 元のサイズで表示する必要があり、
    /// その際に `messageDiskSize` に保管された値を使います。
    private var messageDiskSize: CGFloat!

    func setMessageDiskViewHidden(_ isHidden: Bool) {
        messageDiskSizeConstraint.constant = isHidden
            ? 0
            : messageDiskSize
    }

    @IBOutlet private var playerControls: [UISegmentedControl]!
    @IBOutlet private var countLabels: [UILabel]!
    @IBOutlet private var playerActivityIndicators: [UIActivityIndicatorView]!

    private let repository = Repository(dataStore: DataStoreImpl())

    var currentState = State.new(size: 8)

    private var animationCanceller: Canceller?
    private var isAnimating: Bool { animationCanceller != nil }

    private var playerCancellers: [Disk: Canceller] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        boardView.delegate = self
        messageDiskSize = messageDiskSizeConstraint.constant

        do {
            let state = try loadGame()
            try runSideEffect_loadGame(state: state)
        } catch _ {
            let state = newGame()
            runSideEffect_newGame(state: state)
        }
    }

    private var viewHasAppeared: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if viewHasAppeared { return }
        viewHasAppeared = true
        waitForPlayer()
    }
}

// MARK: Reversi logics

extension ViewController {
    /// `x`, `y` で指定されたセルに `disk` を置きます。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    /// - Parameter isAnimated: ディスクを置いたりひっくり返したりするアニメーションを表示するかどうかを指定します。
    /// - Parameter completion: アニメーション完了時に実行されるクロージャです。
    ///     このクロージャは値を返さず、アニメーションが完了したかを示す真偽値を受け取ります。
    ///     もし `animated` が `false` の場合、このクロージャは次の run loop サイクルの初めに実行されます。
    /// - Throws: もし `disk` を `x`, `y` で指定されるセルに置けない場合、 `DiskPlacementError` を `throw` します。
    func placeDisk(_ disk: Disk, atX x: Int, y: Int, animated isAnimated: Bool, completion: ((Bool) -> Void)? = nil) throws {
        let diskCoordinates = currentState.flippedDiskCoordinatesByPlacingDisk(disk, atX: x, y: y)
        if diskCoordinates.isEmpty {
            throw DiskPlacementError(disk: disk, x: x, y: y)
        }

        if isAnimated {
            let cleanUp: () -> Void = { [weak self] in
                self?.animationCanceller = nil
            }
            animationCanceller = Canceller(cleanUp)
            animateSettingDisks(at: [Point(x, y)] + diskCoordinates, to: disk) { [weak self] finished in
                guard let self = self else { return }
                guard let canceller = self.animationCanceller else { return }
                if canceller.isCancelled { return }
                cleanUp()

                completion?(finished)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.boardView.setDisk(disk, atX: x, y: y, animated: false)
                for p in diskCoordinates {
                    self.boardView.setDisk(disk, atX: p.x, y: p.y, animated: false)
                }
                completion?(true)
            }
        }
    }

    private func animateSettingDisks<C: Collection>(at coordinates: C, to disk: Disk, completion: @escaping (Bool) -> Void)
        where C.Element == Point
    {
        guard let p = coordinates.first else {
            completion(true)
            return
        }

        let animationCanceller = self.animationCanceller!
        boardView.setDisk(disk, atX: p.x, y: p.y, animated: true) { [weak self] finished in
            guard let self = self else { return }
            if animationCanceller.isCancelled { return }
            if finished {
                self.animateSettingDisks(at: coordinates.dropFirst(), to: disk, completion: completion)
            } else {
                for p in coordinates {
                    self.boardView.setDisk(disk, atX: p.x, y: p.y, animated: false)
                }
                completion(false)
            }
        }
    }
}

// MARK: Game management

extension ViewController {
    /// ゲームの状態を初期化し、新しいゲームを開始します。
    func newGame() -> State {
        let state = State.new(size: 8)

        return state
    }
    func runSideEffect_newGame(state: State) {
        currentState = state
        try! boardView.applyWithoutAnimation(state.board)
        playerControls[0].apply(player: state.playerA)
        playerControls[1].apply(player: state.playerB)
        updateMessageViews(state: state)
        updateCountLabels(state: state)
    }

    /// プレイヤーの行動を待ちます。
    func waitForPlayer() {
        guard let turn = currentState.turn else { return }
        switch Player(rawValue: playerControls[turn.index].selectedSegmentIndex)! {
        case .manual:
            break
        case .computer:
            playTurnOfComputer()
        }
    }

    /// プレイヤーの行動後、そのプレイヤーのターンを終了して次のターンを開始します。
    /// もし、次のプレイヤーに有効な手が存在しない場合、パスとなります。
    /// 両プレイヤーに有効な手がない場合、ゲームの勝敗を表示します。
    func nextTurn() {
        guard var turn = currentState.turn else { return }

        turn.flip()

        let state = currentState

        if state.validMoves(for: turn).isEmpty {
            if state.validMoves(for: turn.flipped).isEmpty {
                self.currentState.turn = nil
                updateMessageViews(state: currentState)
            } else {
                self.currentState.turn = turn
                updateMessageViews(state: currentState)

                let alertController = UIAlertController(
                    title: "Pass",
                    message: "Cannot place a disk.",
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .default) { [weak self] _ in
                    self?.nextTurn()
                })
                present(alertController, animated: true)
            }
        } else {
            self.currentState.turn = turn
            updateMessageViews(state: currentState)
            waitForPlayer()
        }
    }

    /// "Computer" が選択されている場合のプレイヤーの行動を決定します。
    func playTurnOfComputer() {
        guard let turn = self.currentState.turn else { preconditionFailure() }
        let p = currentState.validMoves(for: turn).randomElement()!

        playerActivityIndicators[turn.index].startAnimating()

        let cleanUp: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.playerActivityIndicators[turn.index].stopAnimating()
            self.playerCancellers[turn] = nil
        }
        let canceller = Canceller(cleanUp)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            if canceller.isCancelled { return }
            cleanUp()

            try! self.placeDisk(turn, atX: p.x, y: p.y, animated: true) { [weak self] _ in
                guard let state = self?.currentState else { fatalError() }
                try? self?.saveGame(state: state)
                self?.updateCountLabels(state: state)
                self?.nextTurn()
            }
        }

        playerCancellers[turn] = canceller
    }
}

// MARK: Views

extension ViewController {
    /// 各プレイヤーの獲得したディスクの枚数を表示します。
    func updateCountLabels(state: State) {
        for side in Disk.sides {
            countLabels[side.index].text = "\(state.countDisks(of: side))"
        }
    }

    /// 現在の状況に応じてメッセージを表示します。
    func updateMessageViews(state: State) {
        switch state.turn {
        case .some(let side):
            setMessageDiskViewHidden(false)
            messageDiskView.disk = side
            messageLabel.text = "'s turn"
        case .none:
            if let winner = state.sideWithMoreDisks() {
                setMessageDiskViewHidden(true)
                messageDiskView.disk = winner
                messageLabel.text = " won"
            } else {
                setMessageDiskViewHidden(true)
                messageLabel.text = "Tied"
            }
        }
    }
}

// MARK: Inputs

extension ViewController {
    /// リセットボタンが押された場合に呼ばれるハンドラーです。
    /// アラートを表示して、ゲームを初期化して良いか確認し、
    /// "OK" が選択された場合ゲームを初期化します。
    @IBAction func pressResetButton(_ sender: UIButton) {
        let alertController = UIAlertController(
            title: "Confirmation",
            message: "Do you really want to reset the game?",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in })
        alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }

            self.animationCanceller?.cancel()
            self.animationCanceller = nil

            for side in Disk.sides {
                self.playerCancellers[side]?.cancel()
                self.playerCancellers.removeValue(forKey: side)
            }

            let state = self.newGame()
            try? self.saveGame(state: state)
            self.runSideEffect_newGame(state: state)
            self.waitForPlayer()
        })
        present(alertController, animated: true)
    }

    /// プレイヤーのモードが変更された場合に呼ばれるハンドラーです。
    @IBAction func changePlayerControlSegment(_ sender: UISegmentedControl) {
        let side: Disk = Disk(index: playerControls.firstIndex(of: sender)!)

        let state = currentState

        try? saveGame(state: state)

        if let canceller = playerCancellers[side] {
            canceller.cancel()
        }

        if !isAnimating, side == currentState.turn, case .computer = Player(rawValue: sender.selectedSegmentIndex)! {
            playTurnOfComputer()
        }
    }
}

extension ViewController: BoardViewDelegate {
    /// `boardView` の `x`, `y` で指定されるセルがタップされたときに呼ばれます。
    /// - Parameter boardView: セルをタップされた `BoardView` インスタンスです。
    /// - Parameter x: セルの列です。
    /// - Parameter y: セルの行です。
    func boardView(_ boardView: BoardView, didSelectCellAtX x: Int, y: Int) {
        guard let turn = currentState.turn else { return }
        if isAnimating { return }
        guard case .manual = Player(rawValue: playerControls[turn.index].selectedSegmentIndex)! else { return }
        // try? because doing nothing when an error occurs
        try? placeDisk(turn, atX: x, y: y, animated: true) { [weak self] _ in
            guard let state = self?.currentState else { fatalError() }
            try? self?.saveGame(state: state)
            self?.updateCountLabels(state: state)
            self?.nextTurn()
        }
    }
}

// MARK: Save and Load

extension ViewController {
    /// ゲームの状態をファイルに書き出し、保存します。
    func saveGame(state: State) throws {
        try repository.saveGame(state: state)
    }

    /// ゲームの状態をファイルから読み込み、復元します。
    func loadGame() throws -> State {
        try repository.loadGame()
    }
    func runSideEffect_loadGame(state: State) throws {
        currentState = state

        playerControls[0].apply(player: state.playerA)
        playerControls[1].apply(player: state.playerB)

        try boardView.applyWithoutAnimation(state.board)

        updateMessageViews(state: state)
        updateCountLabels(state: state)
    }
}

extension UISegmentedControl {
    func apply(player: Player) {
        selectedSegmentIndex = player.rawValue
    }
    func player() -> Player {
        Player(rawValue: selectedSegmentIndex)!
    }
}

extension BoardView {
    struct ApplicationError: Error { let reason: String }

    func applyWithoutAnimation(_ board: [[Disk?]]) throws {
        var boardSlice = ArraySlice(board)
        guard boardSlice.count == height else {
            throw ApplicationError(reason: "縦違う: \(boardSlice.count)")
        }

        var y = 0
        while let boardLine = boardSlice.popFirst() {
            var x = 0
            for disk in boardLine {
                setDisk(disk, atX: x, y: y, animated: false)
                x += 1
            }
            guard x == width else {
                throw ApplicationError(reason: "\(y)行目の横: \(x)")
            }
            y += 1
        }
        guard y == height else {
            throw ApplicationError(reason: "縦大杉: \(y)")
        }
    }
    func board() -> [[Disk?]] {
        var board: [[Disk?]] = []
        for y in yRange {
            var line: [Disk?] = []
            for x in xRange {
                line.append(diskAt(x: x, y: y))
            }
            board.append(line)
        }
        return board
    }
}
// MARK: Additional types

enum Player: Int {
    case manual = 0
    case computer = 1
}

final class Canceller {
    private(set) var isCancelled: Bool = false
    private let body: (() -> Void)?

    init(_ body: (() -> Void)?) {
        self.body = body
    }

    func cancel() {
        if isCancelled { return }
        isCancelled = true
        body?()
    }
}

struct DiskPlacementError: Error {
    let disk: Disk
    let x: Int
    let y: Int
}

// MARK: File-private extensions

extension Disk {
    init(index: Int) {
        for side in Disk.sides {
            if index == side.index {
                self = side
                return
            }
        }
        preconditionFailure("Illegal index: \(index)")
    }

    var index: Int {
        switch self {
        case .dark: return 0
        case .light: return 1
        }
    }
}

extension Optional where Wrapped == Disk {
    init?<S: StringProtocol>(symbol: S) {
        switch symbol {
        case "x":
            self = .some(.dark)
        case "o":
            self = .some(.light)
        case "-":
            self = .none
        default:
            return nil
        }
    }

    var symbol: String {
        switch self {
        case .some(.dark):
            return "x"
        case .some(.light):
            return "o"
        case .none:
            return "-"
        }
    }
}

