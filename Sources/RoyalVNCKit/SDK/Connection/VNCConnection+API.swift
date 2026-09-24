#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

// MARK: - Connect/Disconnect
public extension VNCConnection {
#if canImport(ObjectiveC)
	@objc
#endif
	func connect() {
		beginConnecting()
	}

#if canImport(ObjectiveC)
    @objc
#endif
	func disconnect() {
		beginDisconnecting()
	}
}

public extension VNCConnection {
#if canImport(ObjectiveC)
    @objc
#endif
	func updateColorDepth(_ colorDepth: Settings.ColorDepth) {
		guard let framebuffer = framebuffer else { return }

		let newPixelFormat = VNCProtocol.PixelFormat(depth: colorDepth.rawValue)

		state.pixelFormat = newPixelFormat

		let sendPixelFormatMessage = VNCProtocol.SetPixelFormat(pixelFormat: newPixelFormat)

		clientToServerMessageQueue.enqueue(sendPixelFormatMessage)

		recreateFramebuffer(size: framebuffer.size,
							screens: framebuffer.screens,
							pixelFormat: newPixelFormat)
	}
}

// MARK: - Mouse Input
public extension VNCConnection {
#if canImport(ObjectiveC)
    @objc
#endif
    func mouseMove(x: UInt16, y: UInt16) {
        enqueueMouseEvent(nonNormalizedX: x,
                          nonNormalizedY: y)
    }

#if canImport(ObjectiveC)
    @objc
#endif
    func mouseButtonDown(_ button: VNCMouseButton,
                         x: UInt16, y: UInt16) {
        updateMouseButtonState(button: button,
                               isDown: true)

        enqueueMouseEvent(nonNormalizedX: x,
                          nonNormalizedY: y)
    }

#if canImport(ObjectiveC)
    @objc
#endif
    func mouseButtonUp(_ button: VNCMouseButton,
                       x: UInt16, y: UInt16) {
        updateMouseButtonState(button: button,
                               isDown: false)

        enqueueMouseEvent(nonNormalizedX: x,
                          nonNormalizedY: y)
    }

#if canImport(ObjectiveC)
    @objc
#endif
    func mouseWheel(_ wheel: VNCMouseWheel,
                    x: UInt16, y: UInt16,
                    steps: UInt32) {
        // RemoteMac fork patch 5: RFB wheel "clicks" are a press *and* a release of
        // buttons 4–7. The release was never sent, so servers saw the wheel button
        // held until the next pointer event.
        for _ in 0..<steps {
            updateMouseButtonState(wheel: wheel,
                                   isDown: true)

            enqueueMouseEvent(nonNormalizedX: x,
                              nonNormalizedY: y)

            updateMouseButtonState(wheel: wheel,
                                   isDown: false)

            enqueueMouseEvent(nonNormalizedX: x,
                              nonNormalizedY: y)
        }
    }
}

extension VNCConnection {
    func updateMouseButtonState(button: VNCMouseButton,
                                isDown: Bool) {
        updateMouseButtonState(mousePointerButton: button.mousePointerButton,
                               isDown: isDown)
    }

    func updateMouseButtonState(wheel: VNCMouseWheel,
                                isDown: Bool) {
        updateMouseButtonState(mousePointerButton: wheel.mousePointerButton,
                               isDown: isDown)
    }

    func updateMouseButtonState(mousePointerButton: VNCProtocol.MousePointerButton,
                                isDown: Bool) {
        if isDown {
            mouseButtonState.insert(mousePointerButton)
        } else {
            mouseButtonState.remove(mousePointerButton)
        }
    }
}

// MARK: - Keyboard Input
public extension VNCConnection {
	func keyDown(_ key: VNCKeyCode) {
		enqueueKeyEvent(key: key,
						isDown: true)
	}

#if canImport(ObjectiveC)
	@objc(keyDown:)
#endif
	func _objc_keyDown(_ key: UInt32) {
		keyDown(.init(key))
	}

	func keyUp(_ key: VNCKeyCode) {
		enqueueKeyEvent(key: key,
						isDown: false)
	}

#if canImport(ObjectiveC)
	@objc(keyUp:)
#endif
	func _objc_keyUp(_ key: UInt32) {
		keyUp(.init(key))
	}
}

// MARK: - Outgoing queue (RemoteMac fork patch 8)
public extension VNCConnection {
	/// Waits until every enqueued client message has been written, or the timeout
	/// elapses. Callers use it to make sure key-up events leave before disconnecting.
	func waitForOutgoingMessages(timeoutSeconds: Double) async {
		let deadline = Date().addingTimeInterval(timeoutSeconds)

		while clientToServerMessageQueue.outstandingCount > 0,
			  Date() < deadline,
			  !state.disconnectRequested {
			try? await Task.sleep(nanoseconds: 2_000_000)
		}
	}
}

// MARK: - Refresh (RemoteMac fork patch 8)
public extension VNCConnection {
	/// Asks the server for a full, non-incremental update of the whole framebuffer.
	func requestFullFramebufferUpdate() {
		guard let framebuffer else { return }

		let request = VNCProtocol.FramebufferUpdateRequest(incremental: false,
															xPosition: 0,
															yPosition: 0,
															width: framebuffer.size.width,
															height: framebuffer.size.height)

		enqueueClientToServerMessage(request)
	}
}

// MARK: - Clipboard (RemoteMac fork patch 2)
public extension VNCConnection {
	/// Sends text to the server's clipboard (ClientCutText). RFB mandates Latin-1; pass `.utf8`
	/// only to probe a server. Text that cannot be represented in `encoding` is sent empty.
	func sendClipboardText(_ text: String, encoding: String.Encoding = .isoLatin1) {
		enqueueClientCutTextMessage(text, encoding: encoding)
	}
}
