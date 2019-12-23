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
    private let output: (Int) -> Void
    private var relativeIndex: Int
    private var memory: [Int:Int]
    private var i = 0
    
    init(program: [Int], input: @escaping () -> Int, output: @escaping (Int) -> Void) {
        self.programCount = program.count
        self.relativeIndex = 0
        self.input = input
        self.output = output
        self.memory = [:]
        for (index, value) in program.enumerated() { self.memory[index] = value }
    }
    
    func compute() {
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
                    output(memory[index1, default: 0])
                } else {
                    relativeIndex += memory[index1, default: 0]
                }
                
                i += 2
            case .halt:
                return
            }
        }
        return
    }
}

func monitorPackets(_ input: [Int]) -> Int {
    let lock = DispatchQueue(label: "packetQueue")
    let group = DispatchGroup()

    var result = -1
    var lastNATpacket = [0, 0]
    var receivedYValues = Set<Int>()
    var packetQueues = (0..<50).map { [$0] }
    let computers = (0..<50).map { id -> IntcodeComputer in
        var outputBuffer = [Int]()
        return IntcodeComputer(program: input,
                               input: { lock.sync { packetQueues[id].isEmpty ? -1 : packetQueues[id].removeFirst() } }) { output in
            outputBuffer.append(output)
            if outputBuffer.count == 3 {
                let address = outputBuffer[0]
                let values = outputBuffer.dropFirst()
                lock.async {
                    if address == 255 {
                        lastNATpacket = Array(values)
                    } else {
                        packetQueues[address].append(contentsOf: values)
                    }
                }
                outputBuffer = []
            }
        }
    }

    DispatchQueue.global().async {
        repeat {
            sleep(1)
            lock.sync() {
                if packetQueues.allSatisfy({ $0.isEmpty }) {
                    if receivedYValues.contains(lastNATpacket[1]) {
                        result = lastNATpacket[1]
                        group.leave()
                    }
                    receivedYValues.insert(lastNATpacket[1])
                    packetQueues[0].append(contentsOf: lastNATpacket)
                }
            }
        } while true
    }

    group.enter()
    for computer in computers {
        DispatchQueue.global().async {
            computer.compute()
        }
    }
    group.wait()

    return result
}
