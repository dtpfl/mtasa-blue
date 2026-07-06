## Multi Theft Auto: San Andreas

[![Build Status](https://github.com/multitheftauto/mtasa-blue/workflows/Build/badge.svg?event=push&branch=master)](https://github.com/multitheftauto/mtasa-blue/actions?query=branch%3Amaster+event%3Apush) [![Unique servers online](https://img.shields.io/endpoint?url=https%3A%2F%2Fmultitheftauto.com%2Fapi%2Fservers-shields.io.json)](https://community.multitheftauto.com/index.php?p=servers) [![Unique players online](https://img.shields.io/endpoint?url=https%3A%2F%2Fmultitheftauto.com%2Fapi%2Fplayers-shields.io.json)](https://multitheftauto.com) [![Unique players last 24 hours](https://img.shields.io/endpoint?url=https%3A%2F%2Fmultitheftauto.com%2Fapi%2Funique-players-shields.io.json)](https://multitheftauto.com) [![Discord](https://img.shields.io/discord/278474088903606273?label=discord&logo=discord)](https://discord.com/invite/mtasa) [![Crowdin](https://badges.crowdin.net/e/f5dba7b9aa6594139af737c85d81d3aa/localized.svg)](https://multitheftauto.crowdin.com/multitheftauto)

[Multi Theft Auto](https://www.multitheftauto.com/) (MTA) is a software project that adds network play functionality to Rockstar North's Grand Theft Auto game series, in which this functionality is not originally found. It is a unique modification that incorporates an extendable network play element into a proprietary commercial single-player PC game.

## Introduction

Multi Theft Auto is based on code injection and hooking techniques whereby the game is manipulated without altering any original files supplied with the game. The software functions as a game engine that installs itself as an extension of the original game, adding core functionality such as networking and GUI rendering while exposing the original game's engine functionality through a scripting language.

Originally founded back in early 2003 as an experimental piece of C/C++ software, Multi Theft Auto has since grown into an advanced multiplayer platform for gamers and third-party developers. Our software provides a minimal sandbox style gameplay that can be extended through the Lua scripting language in many ways, allowing servers to run custom created game modes with custom content for up to hundreds of online players.

Formerly a closed-source project, we have migrated to open-source to encourage other developers to contribute as well as showing insight into our project's source code and design for educational reasons.

Multi Theft Auto is built upon the "Blue" concept that implements a game engine framework. Since the class design of our game framework is based upon Grand Theft Auto's design, we are able to insert our code into the original game. The game is then heavily extended by providing new game functionality (including tweaks and crash fixes) as well as a completely new graphical interface, networking and scripting component.

## Gameplay content

By default, Multi Theft Auto provides the minimal sandbox style gameplay of Grand Theft Auto. The gameplay can be heavily extended through the use of the Lua scripting language that has been embedded in the client and server software. Both the server hosting the game, as well as the client playing the game are capable of running and synchronizing Lua scripts. These scripts are layered on top of Multi Theft Auto's game framework that consists of many classes and functions so that the game can be adjusted in virtually any possible way.

All gameplay content such as Lua scripts, images, sounds, custom models or textures is grouped into a "resource". This resource is nothing more than an archive (containing the content) and a metadata file describing the content and any extra information (such as dependencies on other resources).

Using a framework based on resources has a number of advantages. It allows content to be easily transferred to clients and servers. Another advantage is that we can provide a way to import and export scripting functionality in a resource. For example, different resources can import (often basic) functionality from one or more common resources. These will then be automatically downloaded and started. Another feature worth mentioning is that server administrators can control the access to specific resources by assigning a number of different user rights to them.

## Development

Our project's code repository can be found on the [multitheftauto/mtasa-blue](https://github.com/multitheftauto/mtasa-blue/) Git repository at [GitHub](https://github.com/). We are always looking for new developers, so if you're interested, here are some useful links:

* [Contributors Guide and Coding Guidelines](https://github.com/multitheftauto/mtasa-docs/blob/main/mtasa-blue/CONTRIBUTING.md)
* [Nightly Builds](https://nightly.multitheftauto.com/)
* [Milestones](https://github.com/multitheftauto/mtasa-blue/milestones)

### Build Instructions

#### Windows

Prerequisites
- [Visual Studio 2026](https://visualstudio.microsoft.com/vs/) with:
  - Desktop development with C++
  - Optional component *C++ MFC for latest v145 build tools (x86 & x64)* or if that's missing *C++ MFC for x64/x86 (Latest MSVC)*
- [Microsoft DirectX SDK](https://wiki.multitheftauto.com/wiki/Compiling_MTASA#Microsoft_DirectX_SDK)
- [Git for Windows](https://git-scm.com/download/win) (Optional)

1. Execute `win-create-projects.bat`
2. Open `MTASA.sln` in the `Build` directory
3. Compile
4. Execute: `win-install-data.bat`

Visit the wiki article ["Compiling MTASA"](https://wiki.multitheftauto.com/wiki/Compiling_MTASA) for additional information and error troubleshooting.

#### GNU/Linux

You can build the MTA:SA server on GNU/Linux distributions only for x86, x86_64, armhf and arm64 CPU architectures. ARM architectures are currently in **experimental phase**, which means they're unstable, untested and may crash randomly. Beware that we only officially support building from x86_64 and that includes cross-compiling for x86, arm and arm64.

**Build dependencies**

*Please always read the utils/docker/Dockerfile for up-to-date build dependencies.*

- make
- GNU GCC compiler (version 10 or newer)
- libncurses-dev
- libmysqlclient-dev

**Build instructions: Script**

**Note:** This script always deletes `Build/` and `Bin/` directories and does a clean build.

```sh
$ ./linux-build.sh [--arch=x86|x64|arm|arm64] [--config=debug|release] [--cores=<n>]
$ ./linux-install-data.sh  # optional step
```

If build architecture `--arch` is not provided, then it's taken from the environment variable `BUILD_ARCHITECTURE` (defaults to: x64).

If build configuration `--config` is not provided, then it's taken from the environment variable `BUILD_CONFIG` (defaults to: release).

If the number of jobs `--cores` is not provided, then the build will default to the amount of CPU cores.

If you are trying to **cross-compile** to another architecture, then set `AR`, `CC`, `CXX`, `GCC_PREFIX` environment variables accordingly (see `utils/docker/Dockerfile` for an example).

**Build instructions: Manual**

```sh
$ ./utils/premake5 gmake
$ make -C Build/ config=release_x64 all
$ ./linux-install-data.sh  # optional step
```

If you don't want to build the release configuration for the x86_64 architecture, you can instead pick another build configuration from: `{debug|release}_{x86|x64|arm|arm64}`.

#### GNU/Linux: Cross-compiling the Client for Windows x86

You can cross-compile the MTA:SA client using [msvc-wine](https://github.com/mstorsjo/msvc-wine/) (Microsoft's VC++ toolchain running under Wine). The server can be built natively as described above.

**Prerequisites**

- Wine 11.0+ (or the latest stable Wine)
- msvc-wine with MSVC 14.50+ and Windows SDK 10.0.26100+
- [Microsoft.DXSDK.D3DX](https://www.nuget.org/packages/Microsoft.DXSDK.D3DX) NuGet package for D3DX9 headers and import library

**One-time setup**

```sh
# Install msvc-wine
$ git clone https://github.com/mstorsjo/msvc-wine ~/msvc-wine
$ cd ~/msvc-wine
$ ./vsdownload.py --accept-license
$ ./install.sh ~/msvc

# Create afxres.h stub (MFC not available in msvc-wine)
$ printf '#define IDC_STATIC (-1)\n#include <windows.h>\n' > /path/to/mtasa-blue/Include/afxres.h

# Install D3DX9 headers and lib from NuGet
$ mkdir -p /tmp/dxsdk
$ wget https://www.nuget.org/api/v2/package/Microsoft.DXSDK.D3DX/9.29.952.8 -O /tmp/dxsdk/dxsdk.zip
$ cd /tmp/dxsdk && unzip dxsdk.zip
$ cp /tmp/dxsdk/build/native/include/* /path/to/mtasa-blue/Include/
$ mkdir -p /path/to/mtasa-blue/Lib/x86
$ cp /tmp/dxsdk/build/native/release/lib/x86/d3dx9.lib /path/to/mtasa-blue/Lib/x86/
```

**Build and run (script)**

```sh
# Build and launch the client
$ ./wine-client.sh --gta-path "/path/to/GTA San Andreas"

# Build only
$ ./wine-client.sh --build-only

# Run only (after a previous build)
$ ./wine-client.sh --run-only --gta-path "/path/to/GTA San Andreas"

# See all options
$ ./wine-client.sh --help
```

**Manual build steps**

1. Generate Visual Studio project files:
   ```sh
   $ ./win-create-projects.bat   # requires Wine + .NET Framework
   ```

2. (Optional) Strip `<PostBuildEvent>` from generated `.vcxproj` files — `robocopy`/`xcopy` post-build steps hang under Wine:
   ```sh
   $ for f in Build/*.vcxproj; do
       sed -i '/<PostBuildEvent>/,/<\/PostBuildEvent>/d' "$f"
     done
   ```

3. Build projects individually (building via the solution file is unreliable under Wine):
   ```sh
   $ cd Build
   $ MSBUILD=~/msvc-wine/msvc/bin/x64/msbuild
   $ DXSDK_DIR="/path/to/mtasa-blue" $MSBUILD "Client Launcher.vcxproj" -property:Configuration=Release -property:Platform=Win32
   $ DXSDK_DIR="/path/to/mtasa-blue" $MSBUILD "Client Core.vcxproj" -property:Configuration=Release -property:Platform=Win32
   $ DXSDK_DIR="/path/to/mtasa-blue" $MSBUILD "GUI.vcxproj" -property:Configuration=Release -property:Platform=Win32
   $ DXSDK_DIR="/path/to/mtasa-blue" $MSBUILD "Game SA.vcxproj" -property:Configuration=Release -property:Platform=Win32
   $ DXSDK_DIR="/path/to/mtasa-blue" $MSBUILD "Multiplayer SA.vcxproj" -property:Configuration=Release -property:Platform=Win32
   $ DXSDK_DIR="/path/to/mtasa-blue" $MSBUILD "Loader.vcxproj" -property:Configuration=Release -property:Platform=Win32
   $ DXSDK_DIR="/path/to/mtasa-blue" $MSBUILD "Loader Proxy.vcxproj" -property:Configuration=Release -property:Platform=Win32
   $ DXSDK_DIR="/path/to/mtasa-blue" $MSBUILD "Client Deathmatch.vcxproj" -property:Configuration=Release -property:Platform=Win32
   $ DXSDK_DIR="/path/to/mtasa-blue" $MSBUILD "Client Webbrowser.vcxproj" -property:Configuration=Release -property:Platform=Win32
   $ DXSDK_DIR="/path/to/mtasa-blue" $MSBUILD "CEFLauncher.vcxproj" -property:Configuration=Release -property:Platform=Win32
   $ DXSDK_DIR="/path/to/mtasa-blue" $MSBUILD "CEFLauncher DLL.vcxproj" -property:Configuration=Release -property:Platform=Win32
   ```

4. Copy CEF runtime files:
   ```sh
   $ mkdir -p Bin/mta/cef/locales
   $ cp vendor/cef3/cef/Release/*.dll Bin/mta/
   $ cp vendor/cef3/cef/Resources/icudtl.dat Bin/mta/
   $ cp vendor/cef3/cef/Resources/*.pak Bin/mta/
   $ cp vendor/cef3/cef/Resources/locales/* Bin/mta/cef/locales/
   ```

5. Install client data files:
   ```sh
   $ cp -r Shared/data/MTA\ San\ Andreas/* Bin/
   ```

**Running the client under Wine**

Because Linux filesystems are case-sensitive, the built DLLs end up in `Bin/mta/` (lowercase) but the launcher expects them in `Bin/MTA/` (uppercase). You must merge them before running:

```sh
$ cp -rn Bin/mta/* Bin/MTA/
$ wget https://mirror-cdn.multitheftauto.com/bdata/netc.dll -O Bin/MTA/netc.dll
$ cp -n Bin/MTA/netc.dll Bin/mta/netc.dll  # also needed in lowercase mta/ (CL38)
```

Set up the registry so the launcher can find your GTA:SA installation:

```sh
$ cat > mta_registry.reg << 'EOF'
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\Software\Multi Theft Auto: San Andreas All\Common]
"GTA:SA Path"="Z:\\path\\to\\GTA San Andreas"

[HKEY_LOCAL_MACHINE\Software\Multi Theft Auto: San Andreas All\1.6]
"Last Run Location"="Z:\\path\\to\\mtasa-blue\\Bin"
EOF
$ wine regedit /S mta_registry.reg
```

The CGUI font loader (`Client/gui/CGUI_Impl.cpp:457`) looks in `cgui/` relative to the install directory, but that directory is at `MTA/cgui/`. Symlink it:

```sh
$ ln -s "$(realpath Bin/MTA/cgui)" Bin/cgui
```

Install Microsoft fonts (Verdana, Tahoma) for correct UI rendering:

```sh
$ winetricks corefonts
```

Launch the client:

```sh
$ cd Bin && wine "Multi Theft Auto.exe"
```

**Known limitations**

- The client is a Windows DirectX 9 application. Running it under Wine may have graphical issues or failures depending on your GPU and Wine configuration (Wine's wined3d or DXVK).
- Grand Theft Auto: San Andreas must be installed and accessible from Wine.
- The CEGUI font loader (`Client/gui/CGUI_Impl.cpp:457`) looks for `cgui/<fontname>` relative to the install directory, but the `cgui/` directory lives under `MTA/`. The `wine-client.sh` script creates a symlink at `Bin/cgui/` → `Bin/MTA/cgui/` to work around this.
- `verdana.ttf` is required for the "clear" font (nametags). The script symlinks it to `sans.ttf` as a fallback. For the intended appearance, install the Microsoft Core Fonts in your Wine prefix:

  ```sh
  $ winetricks corefonts   # provides Verdana, Tahoma, Arial, etc.
  ```
  (Requires `winetricks` to be installed on your system.)

#### GNU/Linux: Docker Build Environment

If you have problems resolving the required dependencies or want maximum compatibility, you can use our dockerized build environment that ships all needed dependencies. We also use this environment to build the official binaries.

**Pulling the Docker image**

```sh
$ docker pull ghcr.io/multitheftauto/mtasa-blue-build:latest
```

**Building with Docker**

These examples assume that your current directory is the mtasa-blue checkout directory. You should also know that `/build` is the code directory required by our Docker image inside the container. After compiling, you will find the resulting binaries in `./Bin`. To build the unoptimised debug build, add `--config=debug` to the docker run arguments.

```sh
# x86_64
docker run --rm -v `pwd`:/build ghcr.io/multitheftauto/mtasa-blue-build:latest --arch=x64

# x86
docker run --rm -v `pwd`:/build ghcr.io/multitheftauto/mtasa-blue-build:latest --arch=x86

# arm
docker run --rm -v `pwd`:/build ghcr.io/multitheftauto/mtasa-blue-build:latest --arch=arm

# arm64
docker run --rm -v `pwd`:/build ghcr.io/multitheftauto/mtasa-blue-build:latest --arch=arm64
```

### Premake FAQ

#### How to add new C++ source files?

Execute `win-create-projects.bat`

## License

Unless otherwise specified, all source code hosted on this repository is licensed under the GPLv3 license. See the [LICENSE](./LICENSE) file for more details.

Grand Theft Auto and all related trademarks are © Rockstar North 1997–2026.
