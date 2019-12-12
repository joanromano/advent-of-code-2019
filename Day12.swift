struct Position {
    var x: Int
    var y: Int
    var z: Int
    
    init(_ x: Int, _ y: Int, _ z: Int) {
        self.x = x
        self.y = y
        self.z = z
    }
}

struct Moon {
    var position: Position
    var velocity: Position
    
    var xPositionAndVelocity: [Int] {
        return [position.x, velocity.x]
    }
    
    var yPositionAndVelocity: [Int] {
        return [position.y, velocity.y]
    }
    
    var zPositionAndVelocity: [Int] {
        return [position.z, velocity.z]
    }
    
    var totalEnergy: Int {
        return (abs(position.x) + abs(position.y) + abs(position.z)) *
               (abs(velocity.x) + abs(velocity.y) + abs(velocity.z))
    }
    
    init(position: Position) {
        self.position = position
        self.velocity = Position(0,0,0)
    }
    
    mutating func updatePosition() {
        position.x += velocity.x
        position.y += velocity.y
        position.z += velocity.z
    }
}

func stepsToReachInitialState(_ initialState: [Moon]) -> Int {
    func gcd(_ a: Int, _ b: Int) -> Int {
        let remainder = abs(a) % abs(b)
        if remainder != 0 {
            return gcd(abs(b), remainder)
        } else {
            return abs(b)
        }
    }

    func lcm(_ m: Int, _ n: Int) -> Int {
        guard (m & n) != 0 else { return -1 }
        return m / gcd(m, n) * n
    }
    
    let initialState = moons
    var stepCount = 0
    var stepCountX = 0
    var stepCountY = 0
    var stepCountZ = 0
    
    while true {
        for i in 0..<moons.count {
            for j in i+1..<moons.count {
                if moons[i].position.x > moons[j].position.x {
                    moons[i].velocity.x -= 1
                    moons[j].velocity.x += 1
                } else if moons[i].position.x < moons[j].position.x {
                    moons[i].velocity.x += 1
                    moons[j].velocity.x -= 1
                }
                if moons[i].position.y > moons[j].position.y {
                    moons[i].velocity.y -= 1
                    moons[j].velocity.y += 1
                } else if moons[i].position.y < moons[j].position.y {
                    moons[i].velocity.y += 1
                    moons[j].velocity.y -= 1
                }
                if moons[i].position.z > moons[j].position.z {
                    moons[i].velocity.z -= 1
                    moons[j].velocity.z += 1
                } else if moons[i].position.z < moons[j].position.z {
                    moons[i].velocity.z += 1
                    moons[j].velocity.z -= 1
                }
            }
        }
        for i in 0..<moons.count {
            moons[i].updatePosition()
        }
        
        stepCount += 1
        
        if stepCountX == 0, moons.map ({ $0.xPositionAndVelocity }) == initialState.map ({ $0.xPositionAndVelocity }) {
            stepCountX = stepCount
        }
        if stepCountY == 0, moons.map ({ $0.yPositionAndVelocity }) == initialState.map ({ $0.yPositionAndVelocity }) {
            stepCountY = stepCount
        }
        if stepCountZ == 0, moons.map ({ $0.zPositionAndVelocity }) == initialState.map ({ $0.zPositionAndVelocity }) {
            stepCountZ = stepCount
        }
        
        if stepCountX != 0, stepCountY != 0, stepCountZ != 0 {
            break
        }
        
    }

    return lcm(stepCountZ, lcm(stepCountX, stepCountY))
}