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
    private let input: () -> Int
    private var relativeIndex: Int
    private var memory: [Int:Int]
    private var i = 0

    init(program: [Int], input: @escaping () -> Int) {
        self.programCount = program.count
        self.relativeIndex = 0
        self.memory = [:]
        self.input = input
        for (index, value) in program.enumerated() { self.memory[index] = value }
    }

    func compute() -> Int {
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
                    memory[index1] = input()
                } else if operation == .output {
                    i += 2
                    return memory[index1, default: 0]
                } else {
                    relativeIndex += memory[index1, default: 0]
                }

                i += 2
            case .halt:
                return Int.max
            }
        }

        return Int.max
    }
}

// Part 1

func alignmentParameterCount(_ input: [Int]) -> Int {
    let program = IntcodeComputer(program: input) { fatalError() }
    var result = program.compute()
    var matrix = ""
    
    while result != Int.max {
        matrix.append(Character(UnicodeScalar(result)!))
        result = program.compute()
    }
    
    let matrixLines = matrix.split(separator: "\n").map { $0.map { $0 } }
    var sum = 0
    for row in 1..<(matrixLines.count - 1) {
        for column in 1..<(matrixLines[row].count - 1) {
            if matrixLines[row][column] == "#",
               matrixLines[row][column - 1] == "#",
               matrixLines[row][column + 1] == "#",
               matrixLines[row - 1][column] == "#",
               matrixLines[row + 1][column] == "#" {
                sum += row * column
            }
        }
    }
    
    return sum
}

// Part 2

// R8, L10, R8, R12, R8, L8, L10, L12, R8, L10, R8, L12, L10, L8, R8, L10, R8, R12, R8, L8, L12, L12, L10, L8, L12, L10, L8, R8, L10, R8, R12, R8, L8, L12
func dustCollected(_ input: [Int]) -> Int {
    var index = -1
    var result = 0
    var theInput = input
    theInput[0] = 2
    
    let routine = """
    A,C,A,B,A,C,B,B,A,C
    R,8,L,10,R,8
    L,12,L,10,L,8
    R,12,R,8,L,8,L,12
    y\n
    """.utf8.map { Int($0) }
    let program = IntcodeComputer(program: theInput) {
        index += 1
        return routine[index]
    }
    
    while result < 127 {
        result = program.compute()
    }
    
    return result
}