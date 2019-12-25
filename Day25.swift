import Foundation

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

func droidMove(_ input: [Int]) {
    var currentInstruction = [Int]()
    var scanline = ""

    let intcode = IntcodeComputer(program: input, input: { () -> Int in
        if currentInstruction.isEmpty {
            currentInstruction = (readLine() ?? "").utf8.map { Int($0) } + [10]
        }
        return currentInstruction.removeFirst()
    }) { result in
        if result >= 127 {
            print(result)
        }
        if result == 10 {
            print(scanline)
            scanline = ""
        }
        else {
            scanline.append(Character(UnicodeScalar(result)!))
        }
    }
    intcode.compute()
}

/*
For my input, the items needed to pass security check were:

   - planetoid
   - mutex
   - antenna
   - fuel cell
*/

droidMove([109,4796,21101,3124,0,1,21101,13,0,0,1106,0,1424,21102,166,1,1,21102,1,24,0,1105,1,1234,21101,0,31,0,1105,1,1
984,1106,0,13,6,4,3,2,52,51,21,4,28,56,55,3,19,-9,-10,47,89,88,90,90,6,77,73,85,71,1,76,68,63,65,22,-27,70,76,81,87,5,10
5,105,107,108,95,4,97,92,109,109,5,110,105,110,108,95,4,115,96,109,109,13,-3,59,101,85,92,97,13,84,80,92,78,34,-15,26,-1
6,46,88,72,79,84,0,72,76,-3,85,74,79,75,-8,64,68,75,57,65,70,64,66,72,8,-41,32,-22,56,77,82,-4,60,76,62,70,-2,74,-11,55,
52,68,67,73,56,60,52,-20,44,56,66,-24,48,58,42,49,54,-16,-53,10,0,56,99,96,95,82,94,83,45,-9,23,-13,61,85,88,74,71,82,73
,79,73,89,67,65,-4,62,73,70,69,56,68,57,2,-35,24,-14,64,85,90,4,70,67,79,7,83,-2,68,75,-5,78,65,57,75,-10,76,53,76,0,-37
,31,-21,57,78,83,-3,64,74,72,0,76,-9,73,58,57,-13,70,57,49,67,-18,54,64,48,55,-23,48,44,56,42,-14,-51,14,-4,74,95,100,14
,97,77,86,79,9,92,79,75,5,27,-17,61,82,87,1,68,78,76,4,80,-5,66,58,78,60,-10,73,60,52,70,-15,57,67,51,58,-6,-43,14,-4,74
,95,100,14,81,94,90,90,9,92,79,75,5,60,-50,23,42,38,-32,38,39,30,42,47,-38,30,36,28,25,41,38,34,31,18,23,29,19,33,-52,20
,29,-55,27,27,27,8,15,-61,22,16,-64,24,13,18,-54,-69,-70,-14,7,12,-74,-8,-11,1,-71,5,-80,-4,-3,3,-15,-84,-85,-109,29,-19
,59,80,85,-1,82,62,71,64,-6,77,64,60,-10,62,66,57,59,63,57,67,51,-19,56,58,57,57,-10,-47,44,-34,39,58,54,-16,60,61,57,64
,48,56,-23,52,40,60,38,-28,44,53,-31,55,32,55,-35,48,42,41,-39,32,38,42,-42,-44,12,33,38,-48,28,19,25,32,-52,-76,-77,59,
-49,13,55,-30,42,51,-33,49,50,32,31,31,39,36,48,-42,24,35,32,34,29,21,35,19,25,37,-53,14,10,26,18,-57,-59,-3,18,23,-63,1
,17,3,-67,1,-4,14,-2,6,-73,-8,14,-76,-12,-78,-40,2,4,-13,-82,-106,-107,35,-25,53,74,79,0,74,60,-10,65,53,72,64,52,56,52,
50,-19,53,57,62,56,-24,58,54,38,39,40,-29,-31,2,56,35,-34,-58,-59,138,-128,-74,-108,-33,-31,-26,-44,-101,-114,-33,-37,-5
1,-39,-35,-47,-54,-122,-37,-45,-52,-59,-58,-128,-46,-65,-42,-49,-133,-132,-102,-60,-68,-56,-55,-139,-141,-106,-61,-65,-7
2,-78,-64,-148,-70,-72,-151,-68,-81,-81,-72,-156,-74,-86,-86,-80,-161,-97,-81,-95,-165,-94,-98,-103,-83,-97,-102,-90,-17
3,-90,-103,-111,-99,-178,-95,-108,-112,-182,-115,-115,-101,-117,-120,-104,-120,-122,-191,-106,-128,-118,-110,-127,-196,-
196,-199,-135,-123,-134,-203,-115,-126,-121,-207,-143,-127,-141,-211,-143,-139,-145,-148,-132,-148,-150,-219,-154,-156,-
155,-148,-224,-141,-147,-227,-144,-157,-161,-231,-165,-161,-165,-168,-161,-157,-159,-166,-162,-157,-228,-265,138,-128,-7
4,-108,-33,-31,-26,-44,-101,-114,-33,-37,-51,-39,-35,-47,-54,-122,-37,-45,-52,-59,-58,-128,-46,-65,-42,-49,-133,-132,-10
2,-60,-68,-56,-55,-139,-141,-106,-61,-65,-72,-78,-64,-148,-70,-72,-151,-68,-81,-81,-72,-156,-74,-86,-86,-80,-161,-97,-81
,-95,-165,-90,-94,-97,-97,-86,-102,-90,-173,-90,-103,-111,-99,-178,-95,-108,-112,-182,-115,-115,-101,-117,-120,-104,-120
,-122,-191,-106,-128,-118,-110,-127,-196,-196,-199,-135,-123,-134,-203,-115,-126,-121,-207,-143,-127,-141,-211,-143,-139
,-145,-148,-132,-148,-150,-219,-154,-156,-155,-148,-224,-141,-147,-227,-144,-157,-161,-231,-165,-161,-165,-168,-161,-157
,-159,-166,-162,-157,-228,-265,263,-253,-199,-233,-158,-156,-151,-169,-226,-239,-158,-162,-176,-164,-160,-172,-179,-247,
-162,-170,-177,-184,-183,-253,-171,-190,-167,-174,-258,-257,-227,-183,-197,-187,-175,-182,-193,-184,-268,-202,-191,-194,
-192,-197,-205,-191,-207,-276,-278,-222,-201,-196,-282,-206,-219,-196,-286,-207,-206,-210,-223,-222,-223,-225,-280,-293,
-296,-232,-220,-231,-300,-212,-223,-218,-304,-236,-228,-223,-239,-227,-310,-227,-240,-244,-314,-248,-237,-250,-243,-239,
-247,-237,-308,-345,-273,-260,-248,-243,-263,-329,-252,-252,-248,-260,-267,-266,-253,-337,-249,-260,-255,-259,-342,-260,
-267,-280,-270,-271,-348,-281,-268,-272,-279,-285,-342,-355,-280,-278,-279,-284,-277,-361,-282,-278,-274,-275,-290,-298,
-300,-369,-300,-292,-290,-373,-309,-375,-299,-298,-301,-310,-302,-297,-370,-383,-302,-316,-321,-311,-315,-299,-321,-308,
-392,-306,-322,-330,-312,-397,-326,-334,-317,-401,-330,-338,-324,-325,-337,-329,-339,-341,-398,-411,-347,-335,-346,-415,
-334,-352,-350,-346,-341,-338,-422,-334,-345,-340,-344,-427,-345,-357,-357,-351,-432,-365,-361,-353,-367,-370,-354,-363,
-351,-427,-464,-441,-397,-373,-434,-447,-376,-380,-374,-375,-373,-452,-454,-398,-377,-372,-458,-376,-388,-382,-377,-387,
-396,-465,-400,-398,-468,-404,-404,-395,-403,-473,-390,-396,-476,-406,-409,-395,-480,-408,-404,-483,-418,-396,-486,-403,
-399,-409,-417,-413,-421,-493,37,-5,73,71,-8,75,62,58,-12,62,55,74,64,48,50,-19,45,63,-22,61,48,44,-26,50,37,44,48,-31,3
3,40,48,41,43,30,37,-25,-38,-63,0,0,109,7,21102,1,0,-2,22208,-2,-5,-1,1205,-1,1169,22202,-2,-4,1,22201,1,-6,1,22102,1,-2
,2,21101,1162,0,0,2106,0,-3,21201,-2,1,-2,1105,1,1136,109,-7,2105,1,0,109,6,1202,-5,1,1182,20102,1,0,-2,21101,0,0,-3,212
01,-5,1,-5,22208,-3,-2,-1,1205,-1,1229,2201,-5,-3,1205,20102,1,0,1,21201,-3,0,2,22102,1,-2,3,21101,0,1222,0,2106,0,-4,21
201,-3,1,-3,1105,1,1192,109,-6,2106,0,0,109,2,21202,-1,1,1,21101,0,1256,2,21102,1251,1,0,1105,1,1174,109,-2,2105,1,0,109
,5,22201,-4,-3,-1,22201,-2,-1,-1,204,-1,109,-5,2106,0,0,109,3,2101,0,-2,1280,1006,0,1303,104,45,104,32,1201,-1,66,1291,2
1002,0,1,1,21102,1301,1,0,1106,0,1234,104,10,109,-3,2105,1,0,0,0,109,2,1201,-1,0,1309,1101,0,0,1308,21102,1,4601,1,21101
,0,13,2,21102,4,1,3,21102,1353,1,4,21102,1,1343,0,1106,0,1130,20102,1,1308,-1,109,-2,2105,1,0,63,109,3,1201,-2,0,1360,20
008,0,1309,-1,1206,-1,1419,1005,1308,1398,1102,1,1,1308,21008,1309,-1,-1,1206,-1,1387,21101,0,106,1,1106,0,1391,21102,92
,1,1,21101,0,1398,0,1105,1,1234,104,45,104,32,1201,-2,1,1407,21001,0,0,1,21101,1417,0,0,1105,1,1234,104,10,109,-3,2105,1
,0,109,3,2102,1,-2,1128,21101,0,34,1,21101,1441,0,0,1106,0,1234,1001,1128,0,1447,20101,0,0,1,21101,1456,0,0,1105,1,1234,
21102,41,1,1,21102,1,1467,0,1105,1,1234,1001,1128,1,1473,20101,0,0,1,21102,1,1482,0,1105,1,1234,21102,1,46,1,21102,1,149
3,0,1105,1,1234,21001,1128,3,1,21102,4,1,2,21102,1,1,3,21101,0,1273,4,21102,1516,1,0,1106,0,1130,20102,1,1128,1,21102,1,
1527,0,1105,1,1310,1001,1128,2,1533,20101,0,0,-1,1206,-1,1545,21101,1545,0,0,2105,1,-1,109,-3,2105,1,0,109,0,99,109,2,11
01,0,0,1550,21101,4601,0,1,21101,13,0,2,21101,4,0,3,21102,1,1664,4,21102,1,1582,0,1106,0,1130,2,2486,1352,1551,1101,0,0,
1552,20102,1,1550,1,21101,33,0,2,21101,1702,0,3,21102,1609,1,0,1106,0,2722,21007,1552,0,-1,1205,-1,1630,20107,0,1552,-1,
1205,-1,1637,21102,1,1630,0,1105,1,1752,21102,1,548,1,1105,1,1641,21102,1,687,1,21101,1648,0,0,1106,0,1234,21102,4457,1,
1,21102,1,1659,0,1106,0,1424,109,-2,2106,0,0,109,4,21202,-2,-1,-2,1201,-3,0,1675,21008,0,-1,-1,1206,-1,1697,1201,-3,2,16
87,20101,-27,0,-3,22201,-3,-2,-3,2001,1550,-3,1550,109,-4,2106,0,0,109,5,21008,1552,0,-1,1206,-1,1747,1201,-3,1901,1716,
21001,0,0,-2,1205,-4,1736,20207,-2,1551,-1,1205,-1,1747,1101,0,-1,1552,1106,0,1747,22007,1551,-2,-1,1205,-1,1747,1102,1,
1,1552,109,-5,2105,1,0,109,1,21101,826,0,1,21102,1,1765,0,1105,1,1234,21002,1550,1,1,21101,0,1776,0,1105,1,2863,21101,10
90,0,1,21101,0,1787,0,1106,0,1234,99,1105,1,1787,109,-1,2105,1,0,109,1,21101,512,0,1,21101,0,1809,0,1105,1,1234,99,1106,
0,1809,109,-1,2105,1,0,109,1,1101,0,1,1129,109,-1,2106,0,0,109,1,21101,377,0,1,21102,1842,1,0,1105,1,1234,1106,0,1831,10
9,-1,2106,0,0,109,1,21102,1,407,1,21102,1863,1,0,1106,0,1234,99,1106,0,1863,109,-1,2106,0,0,109,1,21102,452,1,1,21101,18
85,0,0,1105,1,1234,99,1106,0,1885,109,-1,2105,1,0,1941,1947,1953,1958,1965,1972,1978,3343,3160,3226,3641,3558,3084,3499,
3219,3740,2968,3266,3584,3543,3318,3618,3588,3208,3659,3356,3564,3486,3157,3617,3264,3088,3305,3691,3610,3341,3073,3018,
3246,3684,2281,2468,2418,2450,2487,2125,2505,5,95,108,104,104,23,5,96,91,108,108,1,4,101,105,112,3,6,104,104,106,107,94,
-1,6,109,104,109,107,94,-1,5,111,91,100,93,23,5,114,95,108,108,1,109,3,21101,0,1993,0,1105,1,2634,1006,1129,2010,21101,3
16,0,1,21101,0,2007,0,1106,0,1234,1105,1,2076,21101,0,0,-1,1201,-1,1894,2019,21002,0,1,1,21101,0,0,2,21101,0,0,3,21101,0
,2037,0,1105,1,2525,1206,1,2054,1201,-1,1934,2050,21102,1,2051,0,106,0,0,1105,1,2076,21201,-1,1,-1,21207,-1,7,-2,1205,-2
,2014,21101,177,0,1,21102,2076,1,0,1106,0,1234,109,-3,2106,0,0,109,3,2001,1128,-2,2089,20102,1,0,-1,1205,-1,2108,21102,1
,201,1,21101,0,2105,0,1106,0,1234,1106,0,2119,21202,-1,1,1,21102,1,2119,0,1106,0,1424,109,-3,2106,0,0,0,109,1,1101,0,0,2
124,21101,0,4601,1,21102,13,1,2,21102,4,1,3,21102,2173,1,4,21102,2154,1,0,1105,1,1130,1005,2124,2168,21102,226,1,1,21102
,1,2168,0,1105,1,1234,109,-1,2106,0,0,109,3,1005,2124,2275,1201,-2,0,2183,20008,0,1128,-1,1206,-1,2275,1201,-2,1,2194,21
002,0,1,-1,21202,-1,1,1,21102,1,5,2,21102,1,1,3,21101,2216,0,0,1105,1,2525,1206,1,2275,21101,258,0,1,21101,2230,0,0,1105
,1,1234,22101,0,-1,1,21102,2241,1,0,1105,1,1234,104,46,104,10,1102,1,1,2124,1201,-2,0,2256,1101,0,-1,0,1201,-2,3,2263,20
102,1,0,-1,1206,-1,2275,21102,2275,1,0,2105,1,-1,109,-3,2106,0,0,0,109,1,1102,1,0,2280,21101,0,4601,1,21102,1,13,2,21102
,4,1,3,21102,2329,1,4,21101,2310,0,0,1105,1,1130,1005,2280,2324,21102,273,1,1,21102,1,2324,0,1105,1,1234,109,-1,2106,0,0
,109,3,1005,2280,2413,1201,-2,0,2339,21008,0,-1,-1,1206,-1,2413,1201,-2,1,2350,21002,0,1,-1,21202,-1,1,1,21101,0,5,2,211
01,1,0,3,21101,2372,0,0,1105,1,2525,1206,1,2413,21102,301,1,1,21101,0,2386,0,1106,0,1234,21201,-1,0,1,21101,0,2397,0,110
6,0,1234,104,46,104,10,1102,1,1,2280,1201,-2,0,2412,101,0,1128,0,109,-3,2106,0,0,109,1,21102,1,-1,1,21102,1,2431,0,1106,
0,1310,1205,1,2445,21102,133,1,1,21101,2445,0,0,1105,1,1234,109,-1,2105,1,0,109,1,21102,3,1,1,21101,2463,0,0,1106,0,2081
,109,-1,2106,0,0,109,1,21102,1,4,1,21101,2481,0,0,1105,1,2081,109,-1,2105,1,0,58,109,1,21102,5,1,1,21101,0,2500,0,1106,0
,2081,109,-1,2105,1,0,109,1,21102,6,1,1,21102,2518,1,0,1106,0,2081,109,-1,2106,0,0,0,0,109,5,1201,-3,0,2523,1102,1,1,252
4,21201,-4,0,1,21101,2585,0,2,21101,2550,0,0,1105,1,1174,1206,-2,2576,2101,0,-4,2558,2001,0,-3,2566,101,3094,2566,2566,2
1008,0,-1,-1,1205,-1,2576,1101,0,0,2524,20102,1,2524,-4,109,-5,2106,0,0,109,5,22201,-4,-3,-4,22201,-4,-2,-4,21208,-4,10,
-1,1206,-1,2606,21102,-1,1,-4,201,-3,2523,2616,1001,2616,3094,2616,20102,1,0,-1,22208,-4,-1,-1,1205,-1,2629,1102,1,0,252
4,109,-5,2106,0,0,109,4,21102,1,3094,1,21101,0,30,2,21101,1,0,3,21101,0,2706,4,21102,2659,1,0,1106,0,1130,21101,0,0,-3,2
03,-2,21208,-2,10,-1,1205,-1,2701,21207,-2,0,-1,1205,-1,2663,21207,-3,29,-1,1206,-1,2663,2101,3094,-3,2693,1201,-2,0,0,2
1201,-3,1,-3,1106,0,2663,109,-4,2106,0,0,109,2,2102,1,-1,2715,1101,-1,0,0,109,-2,2105,1,0,0,109,5,2101,0,-2,2721,21207,-
4,0,-1,1206,-1,2739,21102,0,1,-4,21202,-4,1,1,21201,-3,0,2,21102,1,1,3,21101,2758,0,0,1105,1,2763,109,-5,2105,1,0,109,6,
21207,-4,1,-1,1206,-1,2786,22207,-5,-3,-1,1206,-1,2786,21201,-5,0,-5,1105,1,2858,21202,-5,1,1,21201,-4,-1,2,21202,-3,2,3
,21102,2805,1,0,1106,0,2763,22101,0,1,-5,21101,0,1,-2,22207,-5,-3,-1,1206,-1,2824,21101,0,0,-2,22202,-3,-2,-3,22107,0,-4
,-1,1206,-1,2850,22101,0,-2,1,21201,-4,-1,2,21101,0,2850,0,105,1,2721,21202,-3,-1,-3,22201,-5,-3,-5,109,-6,2106,0,0,109,
3,21208,-2,0,-1,1205,-1,2902,21207,-2,0,-1,1205,-1,2882,1106,0,2888,104,45,21202,-2,-1,-2,22101,0,-2,1,21101,2899,0,0,11
05,1,2909,1106,0,2904,104,48,109,-3,2106,0,0,109,4,21202,-3,1,1,21102,1,10,2,21102,2926,1,0,1106,0,3010,21202,1,1,-2,221
02,1,2,-1,1206,-2,2948,22102,1,-2,1,21102,2948,1,0,1105,1,2909,22101,48,-1,-1,204,-1,109,-4,2105,1,0,1,2,4,8,16,32,64,12
8,256,512,1024,2048,4096,8192,16384,32768,65536,131072,262144,524288,1048576,2097152,4194304,8388608,16777216,33554432,6
7108864,134217728,268435456,536870912,1073741824,2147483648,4294967296,8589934592,17179869184,34359738368,68719476736,13
7438953472,274877906944,549755813888,1099511627776,2199023255552,4398046511104,8796093022208,17592186044416,351843720888
32,70368744177664,140737488355328,281474976710656,562949953421312,1125899906842624,109,8,21101,0,0,-4,21101,0,0,-3,21101
,0,51,-2,21201,-2,-1,-2,1201,-2,2959,3033,21002,0,1,-1,21202,-3,2,-3,22207,-7,-1,-5,1205,-5,3059,21201,-3,1,-3,22102,-1,
-1,-5,22201,-7,-5,-7,22207,-3,-6,-5,1205,-5,3078,22102,-1,-6,-5,22201,-3,-5,-3,22201,-1,-4,-4,1205,-2,3024,21201,-4,0,-7
,22102,1,-3,-6,109,-8,2105,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3131,3143,0,3325,0,4050,3252,
11,61,105,95,94,17,50,97,83,78,79,83,108,-19,2,7,-79,-9,-2,2,-83,-11,-7,-86,-3,-16,-7,-11,-6,-21,-21,-94,-30,-96,-25,-19
,-23,-31,-101,-29,-25,-104,-21,-34,-38,-108,-39,-34,-32,-33,-31,-114,-43,-47,-35,-49,-105,-120,-69,-43,-123,-49,-56,-57,
-47,-128,-40,-51,-46,-50,-133,-51,-63,-63,-57,-138,-69,-58,-62,-65,-143,-79,-69,-63,-68,-148,-79,-68,-82,-83,-63,-81,-77
,-85,-145,-158,-75,-88,-92,-162,-91,-85,-89,-97,-167,-96,-104,-87,-171,-106,-104,-105,-97,-176,-94,-109,-114,-104,-112,-
114,-169,3259,3268,0,3553,3124,0,3417,8,64,102,98,100,88,88,85,92,56,27,54,51,42,51,49,39,-31,51,36,35,42,47,-37,46,40,-
40,31,23,43,25,-45,30,22,22,35,-50,22,32,-53,25,23,-56,27,14,10,-60,-22,11,2,14,19,-66,-28,14,4,-2,-71,11,-4,10,9,-3,1,-
7,-65,3332,3340,0,3489,0,3124,3628,7,65,89,99,98,108,85,108,76,8,27,27,36,-48,16,32,18,13,-53,18,10,27,-57,8,10,9,17,-62
,16,16,19,7,10,5,21,-1,-3,-72,-3,5,7,-76,6,1,-2,-11,3,-10,-10,-6,-14,-59,-87,1,-10,-5,-84,-10,-24,-94,-21,-11,-14,-14,-9
9,-22,-22,-18,-103,-23,-20,-33,-23,-39,-109,-27,-26,-30,-44,-114,-28,-44,-52,-34,-105,3424,3433,0,0,3252,3767,3717,8,72,
88,105,104,85,90,87,100,55,29,48,44,63,-20,54,40,-30,34,-32,43,39,49,48,39,31,-39,44,46,31,40,40,44,-46,18,30,19,-50,32,
32,12,28,29,17,21,13,-59,24,18,-62,13,15,14,9,-67,-3,7,6,-71,-7,3,-1,0,-7,-63,3496,3504,0,0,0,3325,0,7,76,108,102,104,86
,91,88,48,36,55,51,-19,46,58,66,46,59,-25,48,58,55,55,-30,36,47,45,50,30,37,41,-38,38,39,41,27,-43,22,34,42,22,35,-35,-5
0,-51,-2,16,13,30,26,26,15,27,9,15,27,-49,3560,3572,0,0,4180,3252,0,11,72,87,92,87,95,83,84,14,57,77,77,55,34,55,60,-26,
56,41,40,-30,38,54,40,34,34,42,30,31,-39,32,28,40,26,-44,34,24,-47,32,33,29,33,27,31,35,25,13,-57,22,20,16,28,15,6,18,-6
5,2,2,15,4,1,7,-72,14,5,7,-1,-63,3635,3644,0,0,3325,3847,0,8,75,96,89,96,20,53,83,106,72,11,44,38,37,35,37,38,36,-48,17,
29,33,20,-53,-4,14,12,-44,-12,20,23,8,6,-63,-14,4,7,11,0,0,-1,11,-72,4,-5,-7,-3,-10,-5,-1,-11,-81,-17,-5,-16,-85,-4,-18,
-17,-4,-14,-26,-10,-93,-12,-26,-23,-19,-30,-30,-31,-19,-102,-26,-35,-37,-33,-40,-35,-31,-41,-97,3724,3732,0,0,3417,0,0,7
,76,108,88,88,97,89,102,34,48,66,69,73,62,62,61,73,3,72,61,77,55,53,-2,-17,34,53,49,68,-15,59,45,-25,39,49,48,-29,39,46,
48,51,55,-21,3774,3786,0,3417,0,0,0,11,68,86,102,87,99,102,80,98,92,94,100,60,24,43,39,51,37,-33,31,47,33,-37,27,-39,30,
28,45,-43,40,24,30,22,35,18,29,29,17,30,-27,-55,28,15,11,30,-53,21,7,-63,1,11,10,-67,-2,10,6,13,-3,-5,-74,-7,3,10,0,-67,
-80,3,-10,-4,1,-14,-14,-73,3854,3862,0,3628,3889,0,3985,7,68,97,107,89,93,89,97,26,43,91,73,85,91,85,72,72,76,68,3,78,-6
,63,74,60,59,79,57,0,54,67,57,52,50,-5,3896,3907,0,0,4292,4121,3847,10,68,86,106,92,89,82,100,88,93,91,77,6,38,18,36,36,
33,-25,-52,-2,30,27,9,21,10,10,8,-47,-62,-15,12,4,-1,16,1,-69,13,14,8,7,2,14,-76,0,-9,-14,3,4,0,-14,-7,-16,-8,-3,-5,-89,
-20,-9,-13,-16,-94,-25,-23,-27,-14,-10,-100,-18,-18,-38,-22,-22,-106,-23,-29,-109,-28,-42,-45,-48,-38,-42,-50,-35,-53,-3
5,-51,-107,3992,4015,0,0,3847,0,0,22,65,74,90,87,6,41,86,76,88,70,0,44,63,70,74,79,63,71,57,69,57,58,34,39,81,-4,60,74,7
3,61,56,72,72,-12,71,65,-15,50,52,-18,68,59,61,53,50,54,46,-26,51,51,53,47,34,44,43,55,-21,4057,4069,0,3124,0,0,0,11,58,
98,90,91,95,85,84,96,86,90,82,51,38,59,64,-22,60,45,44,-26,38,-28,58,42,42,52,36,32,44,29,45,30,-39,47,32,42,29,-44,35,3
0,18,30,34,-50,19,27,29,-54,-4,24,25,15,19,11,7,20,16,9,3,-66,19,-50,-55,4128,4151,0,3889,0,4361,4235,22,50,88,92,7,41,7
7,83,70,81,77,65,83,67,-3,34,74,79,71,76,56,63,67,28,55,82,79,70,72,78,85,9,-4,68,78,0,75,-9,73,73,61,63,62,-15,71,62,64
,56,53,57,49,-9,4187,4194,0,0,0,0,3553,6,59,107,91,88,90,90,40,38,70,68,58,-12,66,56,-15,68,55,51,-19,47,44,44,50,54,44,
58,56,-28,54,39,38,45,-33,50,44,-36,35,27,47,29,-41,38,36,43,24,36,-33,4242,4256,0,0,4121,0,0,13,54,100,86,103,15,63,98,
77,93,94,78,90,90,35,49,68,64,-6,59,61,59,73,-11,53,69,55,-15,49,59,58,-19,64,58,57,-23,59,52,39,49,48,-29,40,48,50,-33,
55,44,49,-23,4299,4320,0,0,0,0,3889,20,51,84,80,93,8,62,88,70,84,83,75,79,71,-1,33,66,74,79,63,75,40,32,70,77,-11,57,63,
69,54,-16,51,61,-19,69,58,63,-23,63,57,39,53,-28,51,52,38,51,36,44,49,47,-37,41,39,-40,43,30,26,-44,26,33,-16,4368,4377,
0,4121,4457,0,0,8,59,102,104,103,93,87,97,99,79,5,24,20,-50,26,17,31,11,21,-56,30,7,17,16,22,-62,2,14,3,-66,17,4,0,-70,6
,-3,11,-9,1,-76,-7,-2,0,-1,1,-82,-18,-2,-16,-86,-4,-12,-16,-19,-19,-8,-17,-5,-95,-28,-24,-28,-29,-31,-19,-33,-25,-20,-10
5,-39,-28,-32,-30,-28,-28,-98,-113,-67,-33,-116,-52,-36,-50,-120,-37,-50,-54,-35,-94,4464,4484,0,4556,0,0,4361,19,64,81,
78,95,91,81,91,95,5,39,75,71,68,75,79,77,70,74,79,71,2,38,-41,42,29,25,-45,32,22,40,35,-50,31,27,26,23,-43,-56,8,-58,21,
22,8,21,20,21,17,3,-54,15,0,8,12,1,11,-1,11,-7,-77,-8,-3,-1,-2,0,-83,3,-12,-10,-11,-88,-3,-21,-9,-19,-23,-5,-95,-7,-18,-
13,-17,-100,-28,-34,-34,-26,-21,-33,-23,-19,-95,4563,4588,1553,0,0,4457,0,24,56,89,75,88,87,88,84,70,13,50,67,75,79,68,7
8,66,78,60,-10,27,64,66,65,67,12,53,97,83,93,105,105,87,91,83,25,24,23,3417,4653,27,1829,4361,4667,28,1818,4121,4687,838
8637,0,3553,4700,30,1872,3717,4708,31,1796,3847,4719,16777248,0,3252,4729,1073741857,0,4180,4735,16418,0,3889,4748,36,0,
3767,4754,44,0,4235,4766,37,1850,3985,4778,102,0,4050,4786,32807,0,13,92,96,87,89,93,87,97,81,11,86,88,87,87,19,84,85,76
,88,93,8,76,82,74,71,87,84,80,77,64,69,75,65,79,12,107,91,91,99,92,84,82,13,92,80,75,92,7,105,96,102,106,100,98,102,10,9
1,104,87,84,98,86,16,95,93,81,9,103,98,86,98,88,102,96,89,83,5,104,105,110,107,92,12,95,95,87,90,94,15,80,92,96,95,86,78
,5,104,111,109,93,111,11,89,85,101,93,17,93,80,98,97,81,93,11,98,99,95,102,86,94,15,90,78,98,76,7,90,102,107,91,99,98,84
,9,93,107,90,96,19,85,86,92,91])


