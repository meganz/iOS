protocol RandomNumberGenerating {
    func generate(lowerBound: Int, upperBound: Int) -> Int
}

struct RandomNumberGenerator: RandomNumberGenerating {
    func generate(lowerBound: Int, upperBound: Int) -> Int {
        Int.random(in: lowerBound...upperBound)
    }
}
