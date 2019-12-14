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
    private var getInput: () -> Int
    
    init(program: [Int], getInput: @escaping () -> Int) {
        self.programCount = program.count
        self.relativeIndex = 0
        self.memory = [:]
        self.getInput = getInput
        for (index, value) in program.enumerated() { self.memory[index] = value }
    }
    
    func compute() -> [Int] {
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
                    memory[index1] = getInput()
                } else if operation == .output {
                    outputs.append(memory[index1, default: 0])
                } else {
                    relativeIndex += memory[index1, default: 0]
                }
                
                i += 2
                if outputs.count == 3 { return outputs }
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
 
 init(_ x: Int, _ y: Int) {
     self.x = x
     self.y = y
 }
}
  
func playGame(program: [Int]) -> Int {
    var hash = [Int:Position]()
    var copy = program
    var finalScore = 0
    copy[0] = 2 // Set to 2 to play for free

    let program = IntcodeComputer(program: copy) {
      let paddle: Position = hash[3]!
      let ball: Position = hash[4]!
      
      // Tilt the joystick based on the ball's position to move the paddle
      if ball.x < paddle.x { return -1 }
      else if ball.x > paddle.x { return 1 }
      else { return 0 }
    }

    while true {
        let output = program.compute()

        if output.count != 3 {
            print("Done!")
            break
        }
        
        if output[0] == -1, output[1] == 0 {
            finalScore = output[2]
            print(output[2])
        }

        if output[2] == 3 || output[2] == 4 {
            hash[output[2]] = Position(output[0],output[1])
        }
    }

    return finalScore
}