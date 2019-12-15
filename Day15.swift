final class IntcodeComputer {
    enum Operation: Int {
        case add        = 1
        case multiply   = 2
        case input      = 3
        case output     = 4
        case jumpTrue   = 5
        case jumpFalse  = 6
        case lessThan   = 7
        case equals     = 8
        case relBaseAdj = 9
        case halt       = 99
    }
    
    enum ParameterMode: Int {
        case position   = 0
        case immediate  = 1
        case relative   = 2
        
        func computeIndex(from index: Int, relativeTo relativeIndex: Int, using memory: [Int:Int]) -> Int {
            switch self {
            case .immediate:
                return index
            case .position:
                return memory[index, default: 0]
            case .relative:
                return memory[index, default: 0] + relativeIndex
            }
        }
    }
    
    private let programCount: Int
    private var relativeIndex: Int
    private var memory: [Int:Int]
    private var i = 0
    
    init(program: [Int]) {
        self.programCount = program.count
        self.relativeIndex = 0
        self.memory = [:]
        for (index, value) in program.enumerated() { self.memory[index] = value }
    }
    
    func compute(_ input: Int) -> [Int] {
        var outputs = [Int]()
        while i < programCount {
            let instruction = memory[i, default: 0]
            let operation = Operation(rawValue: instruction % 100) ?? .halt
            
            switch operation {
            case .add, .multiply, .lessThan, .equals:
                let mode1 = ParameterMode(rawValue: (instruction / 100) % 10) ?? .position
                let mode2 = ParameterMode(rawValue: (instruction / 1000) % 10) ?? .position
                let mode3 = ParameterMode(rawValue: (instruction / 10000) % 10) ?? .position
                let index1 = mode1.computeIndex(from: i+1, relativeTo: relativeIndex, using: memory)
                let index2 = mode2.computeIndex(from: i+2, relativeTo: relativeIndex, using: memory)
                let index3 = mode3.computeIndex(from: i+3, relativeTo: relativeIndex, using: memory)
                
                if operation == .add {
                    memory[index3] = memory[index1, default: 0] + memory[index2, default: 0]
                } else if operation == .multiply {
                    memory[index3] = memory[index1, default: 0] * memory[index2, default: 0]
                } else if operation == .lessThan {
                    memory[index3] = (memory[index1, default: 0] < memory[index2, default: 0]) ? 1 : 0
                } else {
                    memory[index3] = (memory[index1, default: 0] == memory[index2, default: 0]) ? 1 : 0
                }
                i += 4
            case .jumpTrue, .jumpFalse:
                let mode1 = ParameterMode(rawValue: (instruction / 100) % 10) ?? .position
                let mode2 = ParameterMode(rawValue: (instruction / 1000) % 10) ?? .position
                let index1 = mode1.computeIndex(from: i+1, relativeTo: relativeIndex, using: memory)
                let index2 = mode2.computeIndex(from: i+2, relativeTo: relativeIndex, using: memory)

                if (operation == .jumpTrue && memory[index1, default: 0] != 0) || (operation == .jumpFalse && memory[index1, default: 0] == 0) {
                    i = memory[index2, default: 0]
                } else {
                    i += 3
                }
            case .input, .output, .relBaseAdj:
                let mode1 = ParameterMode(rawValue: (instruction / 100) % 10) ?? .position
                let index1 = mode1.computeIndex(from: i+1, relativeTo: relativeIndex, using: memory)
                
                if operation == .input {
                    memory[index1] = input
                } else if operation == .output {
                    outputs.append(memory[index1, default: 0])
                } else {
                    relativeIndex += memory[index1, default: 0]
                }
                
                i += 2
                
                if outputs.count == 1 { return outputs }
            case .halt:
                return []
            }
        }
        
        return []
    }
}

struct Position {
    let x: Int
    let y: Int
    let code: Int
    
    init(_ x: Int, _ y: Int, _ code: Int) {
        self.x = x
        self.y = y
        self.code = code
    }
    
    var neighbours: [Position] {
        return [Position(x-1,y,1), // up
                Position(x+1,y,2), // down
                Position(x,y-1,3), // left
                Position(x,y+1,4)] // right
    }
    
    var previous: Position {
        switch code {
        case 1:
            return Position(x+1,y,2)
        case 2:
            return Position(x-1,y,1)
        case 3:
            return Position(x,y+1,4)
        case 4:
            return Position(x,y-1,3)
        default:
            fatalError("wrong")
        }
    }
}

extension Position: Hashable {
    static func == (lhs: Position, rhs: Position) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

func minutesToFillWithOxygen(_ input: [Int]) -> Int {
    func dfs(_ position: Position,
             _ program: IntcodeComputer,
             _ graph: inout [[String]],
             _ path: inout Set<Position>,
             _ visited: inout Set<Position>) -> (movementCount: Int, position: Position)? {
        for neighbour in position.neighbours where !path.contains(neighbour) && !visited.contains(neighbour) {
            let compute = program.compute(neighbour.code)[0]
            if compute == 2 {
                graph[neighbour.x][neighbour.y] = "O"
                return (path.count + 1, neighbour)
            }
            if compute == 1 {
                graph[neighbour.x][neighbour.y] = "."
                path.insert(position)
                let next = dfs(neighbour, program, &graph, &path, &visited)
                path.remove(position)
                if let next = next { return next }
            }
            if compute == 0 {
                graph[neighbour.x][neighbour.y] = "#"
                visited.insert(neighbour)
            }
        }
        // Dead end, back track
        visited.insert(position)
        program.compute(position.previous.code)
        return nil
    }
    
    func bfs(_ position: Position, _ graph: inout [[String]]) -> Int {
        var queue = [position]
        var result = -1
        
        while !queue.isEmpty {
            let count = queue.count
            result += 1
            
            for _ in 0..<count {
                let next = queue.removeFirst()
                for neighbour in next.neighbours where graph[neighbour.x][neighbour.y] == "." {
                    graph[neighbour.x][neighbour.y] = "O"
                    queue.append(neighbour)
                }
            }
        }
        
        return result
    }
    
    var visited = Set<Position>()
    var path = Set<Position>()
    let program = IntcodeComputer(program: input)
    let count = 10000
    var graph = Array(repeating: Array(repeating: "", count: count), count: count)
    
    guard let oxygenSystemPosition = dfs(Position(count/2,count/2,0), program, &graph, &path, &visited)?.position else { return 0 }
    
    return bfs(oxygenSystemPosition, &graph)
}
