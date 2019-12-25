extension Array where Element == Character {
    var bugCount: Int {
        return self.filter { $0 == "#" }.count
    }
}

extension Array where Element == [Character] {
    var hasOutBugs: Bool {
        for i in 0..<5 {
            if self[0][i] == "#" { return true }
            if self[4][i] == "#" { return true }
            if self[i][0] == "#" { return true }
            if self[i][4] == "#" { return true }
        }
        
        return false
    }
    
    var hasInBugs: Bool {
        return self[1][1] == "#" || self[1][2] == "#" || self[1][3] == "#" ||
               self[3][1] == "#" || self[3][2] == "#" || self[3][3] == "#" ||
               self[2][1] == "#" || self[2][3] == "#"
    }
    
    var bugCount: Int {
        return self.reduce(0) { $0 + $1.bugCount }
    }
}

extension Array where Element == [[Character]] {
    var bugCount: Int {
        return self.reduce(0) { $0 + $1.bugCount }
    }
}

struct Position: Hashable {
    let level: Int
    let x: Int
    let y: Int
    
    var neighbours: [Position] {
        var result = [Position]()
        switch (x,y) {
        // Next level neighbours
        case (1,2):
            result.append(contentsOf: [Position(level+1,0,0),Position(level+1,0,1),Position(level+1,0,2),Position(level+1,0,3),Position(level+1,0,4)])
        case (2,1):
            result.append(contentsOf: [Position(level+1,0,0),Position(level+1,1,0),Position(level+1,2,0),Position(level+1,3,0),Position(level+1,4,0)])
        case (3,2):
            result.append(contentsOf: [Position(level+1,4,0),Position(level+1,4,1),Position(level+1,4,2),Position(level+1,4,3),Position(level+1,4,4)])
        case (2,3):
            result.append(contentsOf: [Position(level+1,0,4),Position(level+1,1,4),Position(level+1,2,4),Position(level+1,3,4),Position(level+1,4,4)])
        // Previous level neighbours
        case (0,0):
            result.append(contentsOf: [Position(level-1,1,2), Position(level-1,2,1)])
        case (0,4):
            result.append(contentsOf: [Position(level-1,1,2), Position(level-1,2,3)])
        case (4,0):
            result.append(contentsOf: [Position(level-1,2,1), Position(level-1,3,2)])
        case (4,4):
            result.append(contentsOf: [Position(level-1,3,2), Position(level-1,2,3)])
        case (0,1),(0,2),(0,3):
            result.append(Position(level-1,1,2))
        case (1,0),(2,0),(3,0):
            result.append(Position(level-1,2,1))
        case (4,1),(4,2),(4,3):
            result.append(Position(level-1,3,2))
        case (1,4),(2,4),(3,4):
            result.append(Position(level-1,2,3))
        default:
            break
        }
        
        return result + [Position(level,x+1,y),Position(level,x-1,y),Position(level,x,y+1),Position(level,x,y-1)]
    }
    
    init(_ level: Int, _ x: Int, _ y: Int) {
        self.level = level
        self.x = x
        self.y = y
    }
    
    func isBug(_ matrix: [[[Character]]]) -> Bool {
        return matrix[level][x][y] == "#"
    }
    
    func isEmpty(_ matrix: [[[Character]]]) -> Bool {
        return matrix[level][x][y] == "."
    }
    
    func isValid(_ matrix: [[[Character]]]) -> Bool {
        if x == 2 && y == 2 {
            // Tile in the middle is only to navigate to next level thus not a valid position to check for bug or empty
            return false
        }
        // Position is valid iff not out of bounds
        return level >= 0 && x >= 0 && y >= 0 && level < matrix.count && x < matrix[level].count && y < matrix[level][x].count
    }
}

/*
 Example input: """
 .###.
 ..#.#
 ...##
 #.###
 ..#..
 """
 */
func numberOfBugs(_ input: String, _ minutes: Int) -> Int {
    let inputs: [[[Character]]] = [input.split(separator: "\n").map { Array<Character>($0) }]
    var state = inputs
    var minute = 0

    while minute < minutes {
        if let first = state.first, first.hasOutBugs {
            state = [Array(repeating: Array(repeating: ".", count: 5), count: 5)] + state
        }
        if let last = state.last, last.hasInBugs {
            state = state + [Array(repeating: Array(repeating: ".", count: 5), count: 5)]
        }
        
        var nextState = state
        for i in 0..<state.count {
            for j in 0..<5 {
                for k in 0..<5 {
                    if j == 2, k == 2 { continue }
                    let position = Position(i,j,k)
                    let adjacentBugs = position.neighbours.filter { $0.isValid(state) && $0.isBug(state) }
                    if position.isBug(state) && adjacentBugs.count != 1 {
                        // A bug dies (becoming an empty space) unless there is exactly one bug adjacent to it.
                        nextState[i][j][k] = "."
                    } else if position.isEmpty(state) && (adjacentBugs.count == 1 || adjacentBugs.count == 2) {
                        // An empty space becomes infested with a bug if exactly one or two bugs are adjacent to it.
                        nextState[i][j][k] = "#"
                    }
                }
            }
        }
        
        state = nextState
        minute += 1
    }
    
    return state.bugCount
}