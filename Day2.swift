func run(_ intcodeProgram: [Int]) -> [Int] {
    var i = 0
    var copy = intcodeProgram
    let count = intcodeProgram.count
    
    while i < count {
        let operation = copy[i]
        
        guard operation == 1 || operation == 2 else {
            break
        }
        
        let value1Index = copy[i+1]
        let value2Index = copy[i+2]
        let resultIndex = copy[i+3]
        copy[resultIndex] = operation == 1 ? copy[value1Index] + copy[value2Index] : copy[value1Index] * copy[value2Index]
        
        i += 4
    }
    
    return copy
}