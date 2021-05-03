
public struct RetriableTask<Success, Failure: Error> {
    public typealias TaskResult = (Result<Success, Failure>) -> Void
    
    private let maxAttempts: Int
    private let task: (@escaping TaskResult) -> Void
    private let shouldStopRetrying: (Failure) -> Bool
    
    public init(maxAttempts: Int,
                task: @escaping (@escaping TaskResult) -> Void,
                shouldStopRetrying: @escaping (Failure) -> Bool = { _ in false })
    {
        self.maxAttempts = maxAttempts
        self.task = task
        self.shouldStopRetrying = shouldStopRetrying
    }
    
    public func start(completion: @escaping TaskResult) {
        self.task { result in
            switch result {
            case let .success(response):
                completion(.success(response))
            case let .failure(error):
                debugPrint("Retrier Task Failed || Remaining Attempts: \(maxAttempts)")
                guard maxAttempts > 1 && !shouldStopRetrying(error) else {
                    return completion(.failure(error))
                }
                RetriableTask(maxAttempts: maxAttempts - 1,
                              task: task,
                              shouldStopRetrying: shouldStopRetrying)
                    .start(completion: completion)
            }
        }
    }
}
