#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// RemoteMac fork patch 4: a lock-protected FIFO whose consumer can suspend until
/// an element arrives, replacing the unlocked `Queue` + 10 ms polling send loop.
/// Producers may call `enqueue` from any thread; there is a single consumer.
final class MessageQueue<T>: @unchecked Sendable {
	private let lock = NSLock()
	private var list = [T]()
	private var waiter: CheckedContinuation<Void, Never>?
	private var unsent = 0

	/// Elements enqueued but not yet fully written to the socket.
	var outstandingCount: Int {
		lock.lock()
		defer { lock.unlock() }

		return unsent
	}

	/// The consumer calls this after an element has been written.
	func markSent() {
		lock.lock()
		unsent = max(0, unsent - 1)
		lock.unlock()
	}

	func enqueue(_ element: T) {
		lock.lock()
		list.append(element)
		unsent += 1
		let pending = waiter
		waiter = nil
		lock.unlock()

		pending?.resume()
	}

	func dequeue() -> T? {
		lock.lock()
		defer { lock.unlock() }

		guard !list.isEmpty else { return nil }

		return list.removeFirst()
	}

	func clear() {
		lock.lock()
		list.removeAll()
		unsent = 0
		lock.unlock()
	}

	var isEmpty: Bool {
		lock.lock()
		defer { lock.unlock() }

		return list.isEmpty
	}

	/// Suspends until `enqueue` or `wake` is called, or the task is cancelled.
	/// Returns immediately if an element is already queued.
	func waitForElement() async {
		await withTaskCancellationHandler {
			await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
				lock.lock()

				if !list.isEmpty || Task.isCancelled {
					lock.unlock()
					continuation.resume()
					return
				}

				let previous = waiter
				waiter = continuation
				lock.unlock()

				previous?.resume()
			}
		} onCancel: {
			wake()
		}
	}

	/// Wakes a suspended consumer without enqueueing (used on disconnect).
	func wake() {
		lock.lock()
		let pending = waiter
		waiter = nil
		lock.unlock()

		pending?.resume()
	}
}
