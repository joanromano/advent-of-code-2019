import Dispatch

extension Numeric where Self: LosslessStringConvertible {
    var digits: [Int] {
        String(self).compactMap { $0.wholeNumberValue }
    }

    var isValidPassword: Bool {
        var digits = self.digits
        var previous = digits.removeFirst()
        var sameAdjacentCount = 0
        var onlyTwoAdjacentExist = false
        
        for digit in digits {
            guard digit >= previous else {
                return false
            }
            
            if digit == previous {
                sameAdjacentCount = sameAdjacentCount == 0 ? 2 : sameAdjacentCount + 1
            } else {
                if sameAdjacentCount == 2 {
                    onlyTwoAdjacentExist = true
                }
                sameAdjacentCount = 0
            }
            previous = digit
        }
        
        // Edge case check for two equal digits
        if sameAdjacentCount == 2 {
            onlyTwoAdjacentExist = true
        }
        
        return onlyTwoAdjacentExist
    }
}

func numberOfValidPasswords(from minValue: Int, to maxValue: Int, result: @escaping (Int) -> Void) {
    let group = DispatchGroup()
    var minBound = minValue
    var totalResult = 0
    
    while minBound < maxValue {
        let nextRange = minBound...min(minBound + 50000, maxValue)
        group.enter()
        DispatchQueue.global().async {
            let result = nextRange.filter { $0.isValidPassword }.count
            DispatchQueue.main.async {
                totalResult += result
                group.leave()
            }
        }
        minBound += 50001
    }
    
    group.notify(queue: .main) {
        result(totalResult)
    }
}