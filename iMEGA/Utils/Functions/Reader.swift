import Foundation

public struct Reader<R, A> {
    public let runReader: (R) -> A

    public init(_ runReader: @escaping (R) -> A) {
        self.runReader = runReader
    }
}

// MARK: - Functor
extension Reader {
    public func map<B>(_ f: @escaping (A) -> B) -> Reader<R, B> {
        return .init(self.runReader >>> f)
    }
}

public func <|> <R, A, B> (reader: Reader<R, A>, f: @escaping (A) -> B) -> Reader<R, B> {
    return reader.map(f)
}

// MARK: - Apply
extension Reader {

    public func apply<B>(_ f: Reader<R, (A) -> B>) -> Reader<R, B> {
        return .init { r in
            f.runReader(r) <| self.runReader(r)
        }
    }
}

// MARK: - Applicative
public func pure<R, A>(_ a: A) -> Reader<R, A> {
    return .init(const(a))
}

// MARK: - Monad
extension Reader {

    public func flatMap<B>(_ f: @escaping (A) -> Reader<R, B>) -> Reader<R, B> {
        return .init { r in
            f(self.runReader(r)).runReader(r)
        }
    }
}

// Functor
infix operator <|>: infixl4

// Semigroupoid
infix operator >>>: infixr9
infix operator <<<: infixr9

infix operator <|: infixr0
infix operator |>: infixl1

// Apply
infix operator *>: infixl4
infix operator <*: infixl4
// Apply (right-associative)
infix operator <%>: infixr4
infix operator %>: infixr4
infix operator <%: infixr4

public func id<A>(_ a: A) -> A {
    return a
}

public func <<< <A, B, C>(_ b2c: @escaping (B) -> C, _ a2b: @escaping (A) -> B) -> (A) -> C {
    return { a in b2c(a2b(a)) }
}

public func >>> <A, B, C>(_ a2b: @escaping (A) -> B, _ b2c: @escaping (B) -> C) -> (A) -> C {
    return { a in b2c(a2b(a)) }
}

public func const<A, B>(_ a: A) -> (B) -> A {
    return { _ in a }
}

public func <| <A, B> (f: (A) -> B, a: A) -> B {
    return f(a)
}

public func |> <A, B> (a: A, f: (A) -> B) -> B {
    return f(a)
}
