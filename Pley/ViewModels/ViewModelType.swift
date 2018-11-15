import Foundation

protocol ViewModelType: class {
    associatedtype Input
    associatedtype Output

    var input: Input { get }
    var output: Output { get }
}
