/// RemoteMac fork patch 7: hard bounds on server-supplied sizes (proposal §9).
extension VNCProtocol {
	enum Limits {
		static let maxFramebufferSide: UInt16 = 16_384
		static let maxCursorSide: UInt16 = 256
		static let maxCutTextBytes = 1_048_576
		/// Slack allowed on top of the raw size for a rectangle's compressed payload.
		static let compressedSlackBytes = 65_536
	}
}
