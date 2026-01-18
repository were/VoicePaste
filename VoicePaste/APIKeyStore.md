# APIKeyStore

## Purpose

Manages persistent storage and retrieval of the OpenAI API key for VoicePaste. Provides secure, user-controlled access to the API key with minimal friction.

## File-Based Storage

The API key is stored in a local file:

**Path:** `~/Library/Application Support/VoicePaste/api_key`

This location follows macOS application standards for user data storage outside the app bundle.

## File Permissions

The API key file is created with restrictive permissions:

- **Mode:** 0600 (owner read/write only)
- **Owner:** Current user
- **Group/Others:** No access

These permissions prevent other users on the system from reading the API key while allowing the VoicePaste app to read and write the file.

## Security Model

The API key is stored in **plaintext on disk**. This design choice prioritizes user experience over encrypted storage:

### Plaintext Rationale

Encrypted storage would require:

- Keychain integration (system permission dialogs on each read)
- Key derivation and management
- Additional complexity

The plaintext approach:

- Eliminates repeated Keychain permission prompts
- Maintains simple user experience
- Relies on file system permissions for access control
- Matches the threat model of a trusted desktop application

**Security Note:** Users should protect their machine and be aware that the plaintext key exists in their Application Support directory.

## Key Operations

### Reading the API Key

When transcription is needed, the API key is read from the file. If the file does not exist or is empty, no API key is configured.

### Writing the API Key

When the user enters a key in the Settings UI and clicks "Save", the key is written to the file atomically to prevent partial writes.

### Clearing the API Key

The user can click "Clear" in the Settings UI to delete the stored API key. This removes the file from disk.

### Empty Key Handling

If the key file exists but is empty, it is treated as "no API key configured". The app does not attempt transcription and prompts the user to configure a key in Settings.

## Atomic Writes

File writes use atomic operations to ensure the key file is never partially written. If a write operation fails, the previous key remains intact.

## User-Controlled Storage

Users have full control over their API key:

- Add a key anytime via the Settings UI
- View whether a key is configured (for privacy, the key value is not displayed in settings)
- Clear the key anytime via the "Clear" button
- Remove the file manually if desired

## Access Control

Only the VoicePaste application and the file owner can read/write the API key file. The file is inaccessible to:

- Other users on the system
- Other applications (via standard file permissions)
- macOS sandboxed applications (unless explicitly granted access)

## API Key Validation

Before use, the API key is validated to be non-empty. Invalid or expired keys are caught during transcription attempts with appropriate error messages.
