# Quickshell Architecture

The custom desktop shell is built on Qt6 and QML using Quickshell. This implementation is referred to as "ii" and is located in the `dots/quickshell/ii/` directory.

## Directory Structure

The top-level directories within `dots/quickshell/ii/` are:

- `assets/`
- `defaults/`
- `modules/`
- `panelFamilies/`
- `scripts/`
- `services/`
- `translations/`

### Modules and Panel Families

The shell UI is composed of modules, which define specific visual elements. The environment supports interchangeable panel families loaded by `panelFamilies/PanelLoader.qml`.

- **`modules/common/`**: Shared building blocks containing `functions/`, `models/`, `panels/`, `utils/`, and `widgets/`.
- **`modules/ii/`**: The active default panel family UI. It includes modules such as background, bar, cheatsheet, dock, lock, mediaControls, notificationPopup, onScreenDisplay, onScreenKeyboard, overlay, overview, polkit, regionSelector, screenCorners, sessionScreen, sidebarLeft, sidebarRight, verticalBar, and wallpaperSelector.
- **`modules/waffle/`**: An alternative panel family featuring actionCenter, bar, lock, notificationCenter, startMenu, taskView, etc.

!!! tip
    You can cycle between active panel families on the fly using `Ctrl` + `Super` + `P`.

### Services

The backend logic is handled by roughly 45 QML services located in `services/`. Some notable examples include:
- `Ai.qml`
- `Audio.qml`
- `Battery.qml`
- `Bluetooth`
- `Brightness.qml`
- `Cliphist.qml`
- `HyprlandData.qml`
- `HyprlandKeybinds.qml`
- `MaterialThemeLoader.qml`
- `Network.qml`
- `Notifications.qml`
- `ResourceUsage.qml`
- `Wallpapers.qml`
- `Weather.qml`

### Scripts

The `scripts/` directory houses backend utilities divided by domain:
- **`ai/`**: Gemini wallpaper categorization/translation and Ollama model listing.
- **`colors/`**: Shell scripts (`applycolor.sh`, `switchwall.sh`), Python tools (`generate_colors_material.py`, `scheme_for_image.py`), and terminal sequence configurations.
- **`hyprland/`**: Python bindings like `get_keybinds.py`.
- **`images/`**: Region detection tools.
- **`keyring/`, `kvantum/`, `musicRecognition/`, `thumbnails/`**
- **`videos/`**: Includes `record.sh`.

### Environment Setup

The execution environment is established in `home/default.nix`. `QML2_IMPORT_PATH` and `QT_PLUGIN_PATH` are composed from a curated list of Qt6 and KDE Frameworks packages, alongside the live `~/.config/quickshell/ii` source tree.
