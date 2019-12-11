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
    
    func compute(input: Int) -> [Int] {
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
                if outputs.count == 2 { return outputs }
            case .halt:
                return []
            }
        }
        
        return []
    }
}

struct Position: Hashable {
    var x: Int
    var y: Int
    
    mutating func move(_ direction: Direction) {
        switch direction {
        case .up:
            x -= 1
        case .right:
            y += 1
        case .down:
            x += 1
        case .left:
            y -= 1
        }
    }
}

enum Direction {
    case up
    case right
    case down
    case left
    
    mutating func turn(_ direction: Direction) {
        switch direction {
        case .left:
            switch self {
            case .up:
                self = .right
            case .right:
                self = .down
            case .down:
                self = .left
            case .left:
                self = .up
            }
        case .right:
            switch self {
            case .up:
                self = .left
            case .left:
                self = .down
            case .down:
                self = .right
            case .right:
                self = .up
            }
        default:
            break
        }
    }
}


/// 0 -> Black, 1 -> White
func paintLetters(_ inputProgram: [Int]) -> [[Int]] {
    let computer = IntcodeComputer(program: inputProgram)
    var graph = Array(repeating: Array(repeating: 0, count: 100), count: 100)
    var position = Position(x: graph.count/2, y: graph.count/2)
    var direction = Direction.up
    var outputs = [Int]()
    
    graph[position.x][position.y] = 1 // Paint initial position to white
    while true {
        outputs = computer.compute(input: graph[position.x][position.y])
        
        guard outputs.count == 2 else { break }

        let nextColor = outputs[0]
        let nextDirection = outputs[1]
        graph[position.x][position.y] = nextColor
        direction.turn(nextDirection == 0 ? .left : .right)
        position.move(direction)
    }
    
    return graph
}