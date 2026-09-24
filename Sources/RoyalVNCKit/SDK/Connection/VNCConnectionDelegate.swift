#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(ObjectiveC)
@objc(VNCConnectionDelegate)
#endif
public protocol VNCConnectionDelegate: AnyObject {
#if canImport(ObjectiveC)
    @objc
#endif
	func connection(_ connection: VNCConnection,
					stateDidChange connectionState: VNCConnection.ConnectionState)

#if canImport(ObjectiveC)
    @objc
#endif
	func connection(_ connection: VNCConnection,
					credentialFor authenticationType: VNCAuthenticationType,
					completion: @escaping (_ credential: VNCCredential?) -> Void)

#if canImport(ObjectiveC)
    @objc
#endif
	func connection(_ connection: VNCConnection,
					didCreateFramebuffer framebuffer: VNCFramebuffer)

#if canImport(ObjectiveC)
    @objc
#endif
	func connection(_ connection: VNCConnection,
					didResizeFramebuffer framebuffer: VNCFramebuffer)

#if canImport(ObjectiveC)
    @objc
#endif
    func connection(_ connection: VNCConnection,
                    didUpdateFramebuffer framebuffer: VNCFramebuffer,
                    x: UInt16, y: UInt16,
                    width: UInt16, height: UInt16)

#if canImport(ObjectiveC)
    @objc
#endif
	func connection(_ connection: VNCConnection,
					didUpdateCursor cursor: VNCCursor)
}

/// RemoteMac fork patch 3: receives server clipboard text without the library touching the
/// system pasteboard. Set `VNCConnection.clipboardDelegate` to use it.
public protocol VNCConnectionClipboardDelegate: AnyObject {
	/// - Parameters:
	///   - text: the message decoded as Latin-1 (RFB's mandated encoding)
	///   - rawData: the undecoded bytes, so callers can try other encodings
	func connection(_ connection: VNCConnection,
					didReceiveClipboardText text: String,
					rawData: Data)
}
