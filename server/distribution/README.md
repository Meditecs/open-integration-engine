# Native Installers & Packaging

This directory contains the platform-specific templates, service wrappers, and lifecycle scripts used by Gradle to build native installers for **Open Integration Engine (OIE)** across Linux, Windows and macOS.

## Packaging Matrix

| Platform | Format | Tooling | Gradle Task | Variants |
| :-- | :-- | :-- | :-- | :-- |
| **TAR** (`tar`) | `.tar.gz` | `jpackage` / `tar` | `distPackage` | Standalone (bundled runtime) |
| **Linux** (`deb`) | `.deb` | `jpackage` + `systemd` | `distDeb` | System JRE (`openjdk-17-jre-headless`) |
| **Linux** (`sh`) | `.sh` | Self-extracting archive (Shell stub + Gradle/Ant `.tar.gz`) | `distInstallerSh` | System JRE |
| **Windows** (`arm64` / `x64`) | `.exe` / `.zip` | Inno Setup (via Docker `amake/innosetup`) + WinSW | `distWindows` | Standalone (`with-JRE`) / System JRE / `.zip` |
| **macOS** (`arm64` / `x64`) | `.dmg` | `genisoimage` | `distMac` | Standalone (`with-JRE`) / System JRE |

> **Note on JavaFX:** Server installers bundle or require a standard headless **Java 17+ JRE**. The **Administrator Launcher** (client GUI) runs separately and requires a Java 17+ runtime with **JavaFX** included (e.g., Azul Zulu JDK FX).

---

## Directory Layout

- `linux/`
  - `deb/` — `jpackage` resource overrides, `systemd` unit file, and Debian lifecycle hooks (`postinst`, `prerm`) for service registration and `/usr/local/bin` CLI wrappers.
  - `sh/` — Shell header (`installer.sh`) concatenated with the compressed server payload to produce a self-extracting universal Linux installer (`oie-installer.sh`).
- `tar/`
  - Unix startup scripts injected into the portable `jpackage` `app-image` archive (`distPackage`).
- `windows/`
  - `installer.iss` — Inno Setup script defining the installation wizard, registry entries, service registration, and data cleanup on uninstall.
  - `oieservice.xml` — WinSW configuration wrapping `mirth-server-launcher.jar` as a native Windows Service (`oieservice`).

---

## Prerequisites & Build Commands

### 1. Build Tools Required on the Host

- **All platforms:** JDK 17+ (with `jpackage` available in `PATH`).

* **Windows targets (`distWindows`):** Docker daemon running (uses the `amake/innosetup` image to compile `installer.iss` from Linux/macOS/Windows).
* **Linux `.deb` (`distDeb`):** `dpkg-deb` and `fakeroot` (no external `makeself` binary is needed for `distInstallerSh`).
* **macOS `.dmg` (`distMac`):** `genisoimage` installed on the build host.

### 2. Building Packages

Run the following Gradle tasks from the **repository root** (`/`):

```bash
# Platform-specific targets
./gradlew distPackage     # .tar.gz package
./gradlew distDeb         # Debian/Ubuntu .deb package
./gradlew distInstallerSh # Self-extracting Linux .sh installer
./gradlew distWindows     # Windows .exe (requires Windows host)
./gradlew distMac         # macOS .dmg installer
```
