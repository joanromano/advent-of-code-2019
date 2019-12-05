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

func run(_ intcodeProgram: [Int], _ input: Int) {
    var i = 0
    var copy = intcodeProgram
    let count = intcodeProgram.count
    
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
            copy[copy[i+1]] = input
            i += 2
        case 4:
            let paramMode1 = parameterModeOn ? operationString.nextParameterMode() : 0
            let value1 = copy[i+1, paramMode1]
            print("Output operation result: \(value1)")
            i += 2
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
            return
        }
    }
}