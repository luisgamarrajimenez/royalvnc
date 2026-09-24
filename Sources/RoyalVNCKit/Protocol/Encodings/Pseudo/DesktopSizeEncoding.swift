#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension VNCProtocol {
	struct DesktopSizeEncoding: VNCReceivablePseudoEncoding {
		let encodingType = VNCPseudoEncodingType.desktopSize.rawValue
	}
}

extension VNCProtocol.DesktopSizeEncoding {
	func receive(_ rectangle: VNCProtocol.Rectangle,
				 framebuffer: VNCFramebuffer,
				 connection: NetworkConnectionReading,
				 logger: VNCLogger) async throws {
		let newSize = rectangle.region.size

		// RemoteMac fork patch 7
		guard newSize.width > 0, newSize.height > 0,
			  newSize.width <= VNCProtocol.Limits.maxFramebufferSide,
			  newSize.height <= VNCProtocol.Limits.maxFramebufferSide else {
			throw VNCError.protocol(.boundsViolation("desktop size \(newSize)"))
		}

		framebuffer.resize(to: newSize)
	}
}
