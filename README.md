# BitKeyboard

A custom iOS keyboard operating on bitmap images instead of text, designed with security as the primary constraint.

**Targets:** BitKeyboard, BitKeyboardExtension
**Deployment Target:** iOS 18+
**Framework:** SwiftUI

## Architecture

### Components

1. **App**: Generates encrypted symbol mappings on first launch, receives and displays symbols.
2. **Extension**: Renders the keyboard, encrypts and writes transport tokens to the shared container on each tap.

### Data Flow

**Overview**: `Extension` → `Keyboard Bitmap` → `Encrypted Symbol Mapping` → `Encrypted Transport Token` → `App` → `Decrypted Transport Token` → `App Bitmap`

1. User taps a bitmap symbol key
2. Keyboard reads the encrypted symbol mapping from the shared container
3. Keyboard wraps it in an encrypted transport token via `TransportSecureMapper`
4. Token + counter written to the App Group shared container
5. Notification signals the app
6. App decrypts the transport token, recovers the symbol mapping, matches it to the corresponding bitmap

**Data Transport** Using Darwin notifications because it's a real-time signaling mechanism between the app and the extension.

## Design Mindset

**Task compliance** Bitmaps are pre-defined into bundles.

**Security** Two layers. All security-sensitive data is written with `NSFileProtectionComplete`:

- **Randomized mapping** — each image is mapped to a random UUID, encrypted with a per-device Secure Enclave key.
  - Decompilation — nothing in the binary to extract
  - Cross-device replay — each device has its own mapping, tokens from one are useless on another
  - Jailbreak extraction — per-session regeneration and iOS file protection help, but can't fully prevent extraction if file protection is bypassed

- **Encrypted transport** — unique AES-GCM token per tap with counter-based nonce.
  - Traffic analysis — tapping the same symbol twice produces different data
  - Replay attacks — old tokens are rejected because the counter has moved on
  - Transport interception — token is meaningless without the device secret
  - Memory dump — only one mapping entry in memory at a time, cleared immediately

## Final Thoughts

**Why this architecture?** The App Group shared container is already protected by the OS. Additional encryption layer isn't strictly necessary. But adding encryption demonstrates a deeper security approach.

**Is it overkill?** For 12 animal symbols on a single device, yes. Two layers of encryption and polymorphic tokens are more than the task requires.

**How would this extend to multi-device?**
**Server:**
- Generates the encrypted symbol mappings per-device using each device's Secure Enclave public key
- Stores and serves pre-defined bitmaps
**Client:**
- On-device architecture stays identical — only the mapping origin and asset delivery change
