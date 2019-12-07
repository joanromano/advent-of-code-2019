func generateMaximumSignal(_ input: [Int]) -> Int {
    var maximum = Int.min
    for permutation in permutations([5,6,7,8,9]) {
        maximum = max(maximum, generateSignal(permutation, input))
    }
    return maximum
}

func generateSignal(_ phases: [Int], _ program: [Int]) -> Int {
    let programs = (0..<5).map { _ in Program(program) }
    
    var input = 0
    for (i, phase) in phases.enumerated() {
        input = programs[i].run([phase,input])
    }
    
    var nextInput = input
    while nextInput != -1 {
        input = max(input, nextInput)
        for i in 0..<5 {
            nextInput = programs[i].run([nextInput])
        }
    }
    
    return input
}

extension Array where Element == Int {
    subscript(index: Int, parameterMode: Int) -> Int {
        return parameterMode == 0 ? self[self[index]] : self[index]
    }
}

extension String {
    mutating func nextParameterMode() -> Int {
        return isEmpty ? 0 : Int(String(removeLast()))!
    }
}

final class Program {
    private var i: Int
    private var copy: [Int]
    
    init(_ intcodeProgram: [Int]) {
        self.copy = intcodeProgram
        self.i = 0
    }
    
    func run(_ inputs: [Int]) -> Int {
        var inputsCopy = inputs
        let count = copy.count
        
        while i < count {
            var operationString = String(copy[i])
            let parameterModeOn = operationString.count > 1
            let operation: Int
            if parameterModeOn {
                operation = Int(String(operationString.suffix(2)))!
                operationString.removeLast(2)
            } else {
                operation = copy[i]
            }
    
            switch operation {
            case 1:
                let paramMode1 = parameterModeOn ? operationString.nextParameterMode() : 0
                let paramMode2 = parameterModeOn ? operationString.nextParameterMode() : 0
                copy[copy[i+3]] = copy[i+1, paramMode1] + copy[i+2, paramMode2]
                i += 4
            case 2:
                let paramMode1 = parameterModeOn ? operationString.nextParameterMode() : 0
                let paramMode2 = parameterModeOn ? operationString.nextParameterMode() : 0
                copy[copy[i+3]] = copy[i+1, paramMode1] * copy[i+2, paramMode2]
                i += 4
            case 3:
                copy[copy[i+1]] = inputsCopy.removeFirst()
                i += 2
            case 4:
                let paramMode1 = parameterModeOn ? operationString.nextParameterMode() : 0
                let value1 = copy[i+1, paramMode1]
                i += 2
                return value1
            case 5:
                let paramMode1 = parameterModeOn ? operationString.nextParameterMode() : 0
                let paramMode2 = parameterModeOn ? operationString.nextParameterMode() : 0
                let value1 = copy[i+1, paramMode1]
                let value2 = copy[i+2, paramMode2]
                i = value1 != 0 ? value2 : i + 3
            case 6:
                let paramMode1 = parameterModeOn ? operationString.nextParameterMode() : 0
                let paramMode2 = parameterModeOn ? operationString.nextParameterMode() : 0
                let value1 = copy[i+1, paramMode1]
                let value2 = copy[i+2, paramMode2]
                i = value1 == 0 ? value2 : i + 3
            case 7:
                let paramMode1 = parameterModeOn ? operationString.nextParameterMode() : 0
                let paramMode2 = parameterModeOn ? operationString.nextParameterMode() : 0
                let value1 = copy[i+1, paramMode1]
                let value2 = copy[i+2, paramMode2]
                copy[copy[i+3]] = value1 < value2 ? 1 : 0
                i += 4
            case 8:
                let paramMode1 = parameterModeOn ? operationString.nextParameterMode() : 0
                let paramMode2 = parameterModeOn ? operationString.nextParameterMode() : 0
                let value1 = copy[i+1, paramMode1]
                let value2 = copy[i+2, paramMode2]
                copy[copy[i+3]] = value1 == value2 ? 1 : 0
                i += 4
            default:
                // Halt the program
                return -1
            }
        }
        
        return -1
    }
}

/// Generates all permutations of a given array
func permutations(_ nums: [Int]) -> [[Int]] {
    var solution = [[Int]]()
    var numsCopy = nums
    _permute(&numsCopy, &solution, nums.count, 0)
    return solution
}

func _permute(_ nums: inout [Int], _ solution: inout [[Int]], _ numsCount: Int, _ index: Int) {
    if index == numsCount {
        solution.append(nums)
    }
    
    for i in index..<numsCount {
        nums.swapAt(index, i)
        _permute(&nums, &solution, numsCount, index + 1)
        nums.swapAt(index, i)
    }
}