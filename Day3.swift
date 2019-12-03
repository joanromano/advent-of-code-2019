// Really expensive solution in terms of time complexity, but since there's no penalty on that regard this does the job :P

struct Point: Hashable {
    var x: Int
    var y: Int
    
    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }
}

func generatePoints(_ points: [String], _ stepsHash: inout [Point:Int]) -> Set<Point> {
    var currentPoint = Point(0,0)
    var hash = Set<Point>()
    var currentSteps = 0
    
    for point in points {
        let direction = point.first!
        let units = Int(point.dropFirst())!
        
        switch direction {
        case "U":
            for _ in 0..<units {
                currentPoint.y -= 1
                currentSteps += 1
                hash.insert(currentPoint)
                stepsHash[currentPoint] = (stepsHash[currentPoint] ?? 0) + currentSteps
            }
        case "R":
            for _ in 0..<units {
                currentPoint.x += 1
                currentSteps += 1
                hash.insert(currentPoint)
                stepsHash[currentPoint] = (stepsHash[currentPoint] ?? 0) + currentSteps
            }
        case "D":
            for _ in 0..<units {
                currentPoint.y += 1
                currentSteps += 1
                hash.insert(currentPoint)
                stepsHash[currentPoint] = (stepsHash[currentPoint] ?? 0) + currentSteps
            }
        case "L":
            for _ in 0..<units {
                currentPoint.x -= 1
                currentSteps += 1
                hash.insert(currentPoint)
                stepsHash[currentPoint] = (stepsHash[currentPoint] ?? 0) + currentSteps
            }
        default:
            continue
        }
    }
    
    return hash
}

func minimumStepsDistance(_ firstPath: [String], _ secondPath: [String]) -> Int {
    var stepsHash = [Point:Int]()
    let firstSet = generatePoints(firstPath, &stepsHash)
    let secondSet = generatePoints(secondPath, &stepsHash)
    
    var minimum = Int.max
    for point in firstSet.intersection(secondSet) {
        // First part was based on manhattan distance instead of actual steps - 
        // So just replace `stepsHash[point] ?? 0` by `(abs(0 - point.x) + abs(0 - point.y))`
        minimum = min(minimum, stepsHash[point] ?? 0)
    }
    
    return minimum
}