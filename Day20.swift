struct Position: Hashable {
    let x: Int
    let y: Int
    
    var neighbours: [Position] {
        return [Position(x+1,y),Position(x-1,y),Position(x,y+1),Position(x,y-1)]
    }
    
    var topLeft: [Position] {
        return [Position(x,y-1),Position(x-1,y-1),Position(x-1,y)]
    }
    
    var topRight: [Position] {
        return [Position(x-1,y),Position(x-1,y+1),Position(x,y+1)]
    }
    
    var bottomLeft: [Position] {
        return [Position(x,y-1),Position(x+1,y-1),Position(x+1,y)]
    }
    
    var bottomRight: [Position] {
        return [Position(x,y+1),Position(x+1,y+1),Position(x+1,y)]
    }
    
    var letterNeighbours: [Position] {
        return [Position(x+1,y),Position(x,y+1)]
    }
    
    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }
    
    func isInBounds(_ matrix: [[Character]]) -> Bool {
        return x >= 0 && y >= 0 && x < matrix.count && y < matrix[x].count
    }
    
    func isValid(_ matrix: [[Character]]) -> Bool {
        return isInBounds(matrix) && matrix[x][y] != "#" && matrix[x][y] != " "
    }
    
    func containedIn(_ maxLeft: Position, _ maxRight: Position, _ minLeft: Position, _ minRight: Position) -> Bool {
        return maxLeft.x <= x && maxLeft.y <= y && maxRight.x <= x && maxRight.y >= y &&
               minLeft.x >= x && minLeft.y <= y && minRight.x >= x && minRight.y >= y
    }
}

struct Level: Hashable {
    let position: Position
    var level: Int
    
    init(_ position: Position, _ level: Int) {
        self.position = position
        self.level = level
    }
}

struct Label: Hashable {
    let position: Position
    let inner: Bool
    
    init(_ position: Position, _ inner: Bool) {
        self.position = position
        self.inner = inner
    }
}

func numberOfSteps(_ graph: [[Character]]) -> Int {
    func computeEdges() -> (topLeft: Position, topRight: Position, bottomLeft: Position, bottomRight: Position) {
        var topLeftPosition = Position(0,0)
        var topRightPosition = Position(0,0)
        var bottomLeftPosition = Position(0,0)
        var bottomRightPosition = Position(0,0)
        for i in 0..<graph.count {
            for j in 0..<graph[i].count {
                let position = Position(i,j)
                let character = graph[position.x][position.y]
                if character == " " {
                    if position.topLeft.allSatisfy({ $0.isInBounds(matrix) && matrix[$0.x][$0.y] == "#" }) {
                        topLeftPosition = position
                    }
                    if position.topRight.allSatisfy({ $0.isInBounds(matrix) && matrix[$0.x][$0.y] == "#" }) {
                        topRightPosition = position
                    }
                    if position.bottomLeft.allSatisfy({ $0.isInBounds(matrix) && matrix[$0.x][$0.y] == "#" }) {
                        bottomLeftPosition = position
                    }
                    if position.bottomRight.allSatisfy({ $0.isInBounds(matrix) && matrix[$0.x][$0.y] == "#" }) {
                        bottomRightPosition = position
                    }
                }
            }
        }
        return (topLeftPosition, topRightPosition, bottomLeftPosition, bottomRightPosition)
    }
    
    func computeHash(topLeft: Position,
                     topRight: Position,
                     bottomLeft: Position,
                     bottomRight: Position) -> (initialPosition: Position,
                                                finalPosition: Position,
                                                hash: [[Character]:Set<Label>],
                                                labelMap: [Position:Label]) {
        var hash = [[Character]:Set<Label>]()
        var labelMap = [Position:Label]()
        var initialPosition = Position(0,0)
        var finalPosition = Position(0,0)
        
        for i in 0..<matrix.count {
            for j in 0..<matrix[i].count {
                let position = Position(i,j)
                let character = graph[position.x][position.y]
                if character.isUppercase {
                    for neighbour in position.letterNeighbours where neighbour.isValid(matrix) {
                        let innerCharacter = graph[neighbour.x][neighbour.y]
                        if innerCharacter.isUppercase {
                            for innerNeighbour in (position.neighbours + neighbour.neighbours) where innerNeighbour.isValid(matrix) {
                                if graph[innerNeighbour.x][innerNeighbour.y] == "." {
                                    if "\(character)\(innerCharacter)" == "AA" {
                                        initialPosition = innerNeighbour
                                    } else if "\(character)\(innerCharacter)" == "ZZ" {
                                        finalPosition = innerNeighbour
                                    } else {
                                        let inner = position.containedIn(topLeft, topRight, bottomLeft, bottomRight)
                                        let label = Label(innerNeighbour,inner)
                                        hash[[character,innerCharacter]] = hash[[character,innerCharacter], default: []].union([label])
                                        labelMap[innerNeighbour] = label
                                    }
                                    
                                    break
                                }
                            }
                            break
                        }
                    }
                }
            }
        }
                                                    
        return (initialPosition, finalPosition, hash, labelMap)
    }
    
    func computePositionToPositionMap(_ hash: [[Character]:Set<Label>]) -> [Position:Position] {
        var map = [Position:Position]()
        for value in hash.values {
            let array = Array(value)
            guard array.count == 2 else { fatalError("Wrong warps format") }

            map[array[0].position] = array[1].position
            map[array[1].position] = array[0].position
        }
        return map
    }
    
    func bfs(_ initialPosition: Position, _ finalPosition: Position, _ map: [Position:Position], _ labelMap: [Position:Label]) -> Int {
        var queue = [Level(initialPosition,0)]
        var visited = Set<Level>()
        var found = false
        var result = -1

        while !found {
            let count = queue.count
            result += 1

            for _ in 0..<count {
                let next = queue.removeFirst()
                let nextPosition = next.position
                visited.insert(next)

                if nextPosition == finalPosition, next.level == 0 {
                    found = true
                    break
                }

                var neighbours = nextPosition.neighbours.map { Level($0,next.level) }
                if let mapped = map[nextPosition], let label = labelMap[nextPosition] {
                    if next.level == 0 {
                        if label.inner {
                            neighbours.append(Level(mapped,next.level+1))
                        }
                    } else {
                        if label.inner {
                            neighbours.append(Level(mapped,next.level+1))
                        } else {
                            neighbours.append(Level(mapped,next.level-1))
                        }
                    }
                }
                for neighbour in neighbours where neighbour.position.isValid(matrix) && !visited.contains(neighbour) {
                    queue.append(neighbour)
                }
            }
        }

        return result
    }
    
    let (topLeft, topRight, bottomLeft, bottomRight) = computeEdges()
    let (initialPosition, finalPosition, hash, labelMap) = computeHash(topLeft: topLeft,
                                                                       topRight: topRight,
                                                                       bottomLeft: bottomLeft,
                                                                       bottomRight: bottomRight)
    let map = computePositionToPositionMap(hash)
    
    
    return bfs(initialPosition, finalPosition, map, labelMap)
}