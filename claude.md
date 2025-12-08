# HP41SerialReader - TULIP4041 Support Implementation

## Session Date
December 8, 2025

## Overview
Added support for the TULIP4041 serial interface device while maintaining full backward compatibility with Diego Diaz's USB-41 interface. All TULIP4041-specific features are conditional on a new DTR toggle setting.

## Changes Made

### 1. DTR (Data Terminal Ready) Support
**Files Modified:** `SerialSettings.swift`, `SettingsView.swift`, `SerialPortManager.swift`, `ContentView.swift`

- Added `enableDTR` boolean property to `SerialSettings` (default: false)
- Added toggle control in Settings UI: "Enable DTR (for TULIP4041)"
- Modified `connect()` function to accept `enableDTR` parameter
- When DTR is enabled, sets `port.dtr = true` for TULIP4041 compatibility
- Explicitly disables hardware flow control (both DTR/DSR and RTS/CTS) as TULIP4041 needs DTR line enabled but not flow control
- Stored DTR setting in `dtrEnabled` flag for use in data processing

### 2. Right-Justified Line Handling (Byte 232/0xE8)
**File Modified:** `SerialPortManager.swift`

**TULIP4041 Mode (DTR enabled):**
- Right-justify by padding to 24 characters, then add newline
- Example: "PRP" becomes "                   PRP\n"

**USB-41 Mode (DTR disabled):**
- Original behavior: prepend 24 spaces, no newline
- Preserves existing functionality

### 3. A2 Byte Separator Handling (Byte 162/0xA2)
**File Modified:** `SerialPortManager.swift`

**Problem:** TULIP4041 batches multiple program steps on single line, separated by A2 bytes
- Example: `"Y OR N" A2 AVIEW A2 SF 00 E0`

**TULIP4041 Mode (DTR enabled):**
- Treats A2 (skip-2) as line break separator
- Un-batches commands into separate lines
- Sets `lineEndFlag = true` to trigger line processing

**USB-41 Mode (DTR disabled):**
- A2 adds spaces (original behavior)
- No line breaking

### 4. Automatic Line Numbering for Program Listings
**File Modified:** `SerialPortManager.swift`

Added intelligent line numbering that:
- Only activates in TULIP4041 mode when DTR is enabled
- Only applies to program listings (PRP/LIST commands)
- Skips the PRP/LIST command line itself
- Detects label lines (pattern: ` XX♦LBL`) and extracts their line numbers
- Adds sequential line numbers to all other program lines
- Format: ` XX command\n` (space, 2-digit number, space, command, newline)

**Variables Added:**
- `currentLineNumber`: Tracks the current line number in program listing
- `inProgramListingMode`: Boolean flag indicating if currently processing a program listing

### 5. Smart Mode Detection
**File Modified:** `SerialPortManager.swift`

Added `detectProgramListingMode()` function that analyzes each line to determine printout type:

**Enables Program Listing Mode:**
- When line starts with "PRP" or "LIST"
- Resets `currentLineNumber` to 0

**Disables Program Listing Mode:**
- When line starts with "PRFLAGS", "PRKEYS", "PRREG", or "STATUS"
- Resets `currentLineNumber` to 0

**Features:**
- Trims whitespace before checking (handles right-justified lines)
- Case-insensitive matching (converts to uppercase)
- Maintains mode for continuation lines (doesn't reset between lines of same printout)

**New Function:** `resetProgramListingMode()`
- Called on disconnect and when Clear button is pressed
- Resets mode flags for next printout

### 6. Debug Logging Cleanup
**Files Modified:** `SerialPortManager.swift`, `ContentView.swift`

Removed verbose debug logging to prevent timing issues:
- Removed byte-by-byte logging (Raw byte, ASCII char, Integer value)
- Removed mode detection status messages
- Removed line numbering debug messages
- Removed port enumeration logging
- Kept critical error messages and connection status

### 7. Auto-Scrolling for Received Data Window
**File Modified:** `ContentView.swift`

**Applies to Both Devices (Not conditional on DTR)**

Implemented automatic scrolling to keep latest data visible:
- Wrapped ScrollView with `ScrollViewReader`
- Added invisible marker at bottom with `id("bottom")`
- Added `.onChange(of: serialManager.receivedData)` observer
- Automatically scrolls to bottom with smooth animation when new data arrives
- Benefits both USB-41 and TULIP4041 users

## Technical Details

### Data Flow for TULIP4041 Program Listings

1. **PRP command arrives** (right-justified with E8):
   - Padded to 24 chars, newline added
   - `detectProgramListingMode()` identifies "PRP", enables mode
   - `addLineNumberIfNeeded()` skips PRP line (no number added)

2. **Label line arrives** (e.g., ` 01♦LBL "YNSUB"` + E0):
   - Newline added by E0
   - `addLineNumberIfNeeded()` detects label pattern ` XX♦`
   - Extracts line number (01), updates `currentLineNumber`
   - No number added (already has one)

3. **Regular program line arrives** (e.g., `XEQ "SAVST"` + A2):
   - A2 adds newline and sets `lineEndFlag`
   - `addLineNumberIfNeeded()` increments counter and adds number
   - Output: ` 02 XEQ "SAVST"\n`

4. **Another line arrives** (e.g., `SF 00` + E0):
   - E0 adds newline
   - `addLineNumberIfNeeded()` increments counter and adds number
   - Output: ` 03 SF 00\n`

### Compatibility Matrix

| Feature | USB-41 (DTR OFF) | TULIP4041 (DTR ON) |
|---------|------------------|---------------------|
| DTR Line | Not enabled | Enabled |
| Hardware Flow Control | Disabled | Disabled |
| E8 (232) Right-justify | 24 spaces prepended | Pad to 24 chars + newline |
| A2 (162) Separator | Add spaces | Line break |
| Line Numbering | None | Auto for program listings |
| Mode Detection | Not active | PRP/LIST vs PRFLAGS/etc |
| Auto-scrolling | Yes | Yes |

## Files Modified

1. **SerialSettings.swift**
   - Added `enableDTR` published property

2. **SettingsView.swift**
   - Added DTR toggle UI control
   - Added temporary state variable for DTR
   - Updated `onAppear` and `applyChanges` functions

3. **SerialPortManager.swift**
   - Added `dtrEnabled`, `currentLineNumber`, `inProgramListingMode` properties
   - Modified `connect()` to accept and handle `enableDTR` parameter
   - Modified `disconnect()` to call `resetProgramListingMode()`
   - Added `resetProgramListingMode()` function
   - Modified byte 162 (A2) handling for line breaking
   - Modified byte 232 (E8) handling for right-justification
   - Added `detectProgramListingMode()` function
   - Added `addLineNumberIfNeeded()` function
   - Removed verbose debug logging

4. **ContentView.swift**
   - Modified `connect()` call to pass `settings.enableDTR`
   - Modified Clear button to call `serialManager.resetProgramListingMode()`
   - Added auto-scrolling with ScrollViewReader
   - Removed debug logging

## Testing Status

✅ **Completed:**
- DTR enable/disable functionality
- Right-justified line handling
- A2 byte un-batching
- Automatic line numbering
- Mode detection (PRP/LIST vs PRFLAGS/PRKEYS)
- PRP/LIST command line skipping
- Debug logging removal
- Auto-scrolling implementation

✅ **Verified Working:**
- USB-41 interface (DTR OFF) - maintains original functionality
- TULIP4041 interface (DTR ON) - all new features working

⚠️ **Known Issues:**
- Occasional data jumbling observed (cause to be investigated in future session)

## Future Improvements

1. Investigate and resolve occasional data jumbling
2. Consider adding user preference for auto-scrolling on/off
3. Add visual indicator in UI showing which mode (USB-41 vs TULIP4041) is active

## Notes

- All TULIP4041-specific features are activated only when DTR toggle is enabled
- USB-41 compatibility is fully preserved - no changes to behavior when DTR is disabled
- Auto-scrolling feature benefits both devices equally
- Code includes comments explaining TULIP4041 vs USB-41 mode differences
