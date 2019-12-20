struct Position: Hashable {
    let x: Int
    let y: Int
    var state: Set<Character>
    
    var neighbours: [Position] {
        return [Position(x+1, y, state),Position(x-1, y, state),Position(x, y+1, state),Position(x, y-1, state)]
    }
    
    init(_ x: Int, _ y: Int, _ state: Set<Character>) {
        self.x = x
        self.y = y
        self.state = state
    }
    
    func isValid(_ matrix: [[Character]]) -> Bool {
        let inBounds = x >= 0 && y >= 0 && x < matrix.count && y < matrix[x].count
        guard inBounds else { return false }
        guard matrix[x][y] != "#" else { return false }
        
        if matrix[x][y] == "." || matrix[x][y] == "@" { return true }
        if matrix[x][y].isLowercase { return true }
        return state.contains(Character(matrix[x][y].lowercased()))
    }
}

func fewestNecessarySteps(_ graph: [[Character]]) -> Int {
    func computeKeys() -> (initialPositions: [Position], keySets: [Set<Character>]) {
        var initialPositions = [Position]()

        for i in 0..<graph.count {
            for j in 0..<graph[i].count {
                if graph[i][j] == "@" {
                    initialPositions.append(Position(i,j,[]))
                }
            }
        }

        var keys1 = Set<Character>()
        for i in 0...initialPositions[0].x {
            for j in 0...initialPositions[0].y {
                if graph[i][j].isLowercase {
                    keys1.insert(graph[i][j])
                }
            }
        }

        var keys2 = Set<Character>()
        for i in 0...initialPositions[1].x {
            for j in initialPositions[1].y..<graph[i].count {
                if graph[i][j].isLowercase {
                    keys2.insert(graph[i][j])
                }
            }
        }

        var keys3 = Set<Character>()
        for i in initialPositions[2].x..<graph.count {
            for j in 0...initialPositions[2].y {
                if graph[i][j].isLowercase {
                    keys3.insert(graph[i][j])
                }
            }
        }

        var keys4 = Set<Character>()
        for i in initialPositions[3].x..<graph.count {
            for j in initialPositions[3].y..<graph[i].count {
                if graph[i][j].isLowercase {
                    keys4.insert(graph[i][j])
                }
            }
        }
        
        return (initialPositions, [keys1,keys2,keys3,keys4])
    }
    
    func bfs(_ position: Position, _ allKeys: Set<Character>) -> Int {
        var visited = Set<Position>()
        var result = -1
        var queue = [position]
        
        while !queue.isEmpty {
            let count = queue.count
            result += 1
            
            for _ in 0..<count {
                var nextPosition = queue.removeFirst()
                if visited.contains(nextPosition) { continue }
                let character = graph[nextPosition.x][nextPosition.y]
                if character.isLowercase {
                    nextPosition.state.insert(character)
                    if nextPosition.state == allKeys {
                        return result
                    }
                }
                
                visited.insert(nextPosition)
                let nextNeighbours = nextPosition.neighbours.filter { $0.isValid(matrix) }
                for nextNeighbour in nextNeighbours { queue.append(nextNeighbour) }
            }
        }
        
        return -1
    }
    
    let (initialPositions, keySets) = computeKeys()
    let allKeys = keySets[0].union(keySets[1]).union(keySets[2]).union(keySets[3])
    
    var result = 0
    for (index,position) in initialPositions.enumerated() {
        var nextSet = Set<Character>()
        for (subIndex,set) in keySets.enumerated() {
            if subIndex == index { continue }
            nextSet = nextSet.union(set)
        }
        result += bfs(Position(position.x, position.y, nextSet), allKeys)
    }
    
    return result
}