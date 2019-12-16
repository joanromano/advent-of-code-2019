extension StringProtocol  {
    var digits: [Int] { compactMap{ $0.wholeNumberValue } }
}
extension LosslessStringConvertible {
    var string: String { .init(self) }
}
extension Numeric where Self: LosslessStringConvertible {
    var digits: [Int] { string.digits }
}

// Part 1

func fft(_ input: [Int], _ phases: Int) -> [Int] {
    let pattern = [0, 1, 0, -1]
    var inputDigits = input
    
    for _ in 1...phases {
        let inputDigitsCount = inputDigits.count
        var nextInputDigits = [Int]()
        
        for i in 1...inputDigitsCount {
            var numbers = pattern.flatMap { Array(repeating: $0, count: i) }
            numbers.append(numbers.removeFirst())

            var i = 0
            var totalSum = 0
            for digit in inputDigits {
                if i == numbers.count { i = 0 }
                totalSum += numbers[i] * digit
                i += 1
            }

            nextInputDigits.append(abs(totalSum % 10))
        }

        inputDigits = nextInputDigits
    }
    
    return Array(inputDigits.prefix(8))
}

// Part 2

func fft2(_ input: [Int], _ phases: Int) -> [Int] {
    var inputDigits = Array(repeating: input, count: 10000).flatMap { $0 }
    var toRemove = 0
    for number in inputDigits[0..<7] {
        toRemove = toRemove * 10 + number
    }
    inputDigits = Array(inputDigits[toRemove...])
    let count = inputDigits.count
    
    for _ in 1...phases {
        for i in (0..<count-1).reversed() {
            inputDigits[i] = (inputDigits[i] + inputDigits[i+1]) % 10
        }
    }
    
    return Array(inputDigits.prefix(8))
}