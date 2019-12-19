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
    
    
    init(program: [Int]) {
        self.programCount = program.count
        self.relativeIndex = 0
        self.memory = [:]
        for (index, value) in program.enumerated() { self.memory[index] = value }
    }
    
    func compute(input: [Int]) -> Int {
        var inputs = input
        var i = 0
        
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
                    memory[index1] = inputs.removeFirst()
                } else if operation == .output {
                    i += 2
                    return memory[index1, default: 0]
                } else {
                    relativeIndex += memory[index1, default: 0]
                }
                
                i += 2
            case .halt:
                return -1
            }
        }
        return -1
    }
}

func affectedPoints(_ input: [Int], _ squareSize: Int) -> Int {
    var count = 0
    for i in 0..<squareSize {
        for j in 0..<squareSize {
            let intcode = IntcodeComputer(program: input)
            if intcode.compute(input: [i,j]) == 1 {
                count += 1
            } 
        }
    }
    return count
}

func closestSquareValue(_ input: [Int]) -> Int {
    func get(_ x: Int, _ y: Int) -> Int {
        let intcode = IntcodeComputer(program: input)
        return intcode.compute(input: [x,y])
    }
    var y = 101
    var x = 0
    while true {
        x = max(x - 5, 0)
        while true {
            if get(x, y) == 1 {
                break
            }
            x += 1
        }
        let vals = (get(x + 99, y), get(x, y - 99), get(x + 99, y - 99))
        if vals == (1, 1, 1) {
            return (x * 10000 + (y - 99))
        }
            
        y += 1
    }
    return -1
}