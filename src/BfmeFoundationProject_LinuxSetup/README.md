# BFME Linux setup

Runs the Windows All-in-One Launcher and Online Arena on Linux under Proton (default) or Wine, with the setup done for you. No sudo. It never installs system packages: `doctor` tells you what is missing.

```
./bfme-linux-setup.sh doctor     # check system requirements
./bfme-linux-setup.sh install    # runner, prefix, settings, launcher, Arena, two menu shortcuts
```

Then use the menu shortcuts **BFME All-in-One Launcher** and **BFME Online Arena**. Install the games in the launcher.
Open the Arena from its own shortcut, not from the launcher's Multiplayer tab (the Arena draws outside the launcher frame there).

Other commands: `launcher`, `arena`, `game bfme1|bfme2|rotwk`, `shortcuts`, `status`, `reset-prefix --yes`, `help`.

## What it sets up

- One shared prefix under `~/.local/share/bfme-foundation` (change with `BFME_HOME`).
- Proton through `umu-launcher` (checksum-verified download) or your system Wine 10.0 plus winetricks (`BFME_RUNNER=wine`).
- The launcher and Arena in the same folders as on Windows (`AppData/Roaming/...` in the prefix). The Arena is downloaded and updated by the script, with an MD5 check.
- Prefix settings, applied once per version:
  - `mfc71`, `msvcp71`, `msvcr71`, `dinput8` = `native,builtin`. This stops the multiplayer "Out of Sync" error between Linux and Windows players.
  - `DisableHWAcceleration = 1` so the launcher repaints tabs correctly.
  - Proton: `d3d8`, `d3d9`, `d3d11`, `dxgi` = `native,builtin` (DXVK).
  - Wine: `corefonts`, `win10`, `dxvk`, `d3dx9`, a `dxvk.conf` (the game closes at map load without it), `LogPixels = 96`.

## Settings

`<data dir>/config.env` or the environment: `BFME_RUNNER` (proton|wine), `BFME_PROTONPATH`, `BFME_ARENA_BRANCH`, `BFME_NVIDIA` (auto|1|0), `BFME_EXTRA_ENV`, `BFME_UMU_RUN`, `BFME_HOME`.

## Notes

- Use one runner and one Wine version per prefix.
- Do not switch patches in the launcher once a game is installed (it once broke BFME 2 on Wine).
- x86_64 only. A firewall (`ufw`, `firewalld`) is reported by `doctor`; the script never changes it.

## Flatpak

`flatpak/` holds a manifest that packages the same script as a Flatpak (`BfmeFoundationProject.AllInOneLauncher.Linux`) with two menu entries, **BFME All-in-One Launcher** and **BFME Online Arena**. Inside the sandbox the script uses Proton only, and the graphics and 32-bit libraries come from the Flatpak runtime.

Build and install it locally (needs `flatpak` and `flatpak-builder`, and the Flathub remote for the runtimes):

```
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
cd flatpak
flatpak-builder --user --install --install-deps-from=flathub --force-clean build-dir BfmeFoundationProject.AllInOneLauncher.Linux.yml
```

The 32-bit extensions are required, and Flatpak does **not** install them for apps outside Flathub (not with `flatpak-builder`, not from a self-hosted repo, not with a `.flatpakref`). Use the helper, which also picks the 32-bit NVIDIA driver that matches your card:

```
flatpak/install-flatpak.sh --repo <repo URL or path>       # or: --bundle file.flatpak
```

Without the extensions the app detects the problem, `doctor` fails, and every start command exits with the command to run.

### Repository and updates

Tagged releases (`linux-v*`) publish a Flatpak repository to GitHub Pages, so `flatpak update` finds new versions. The repository address is `https://<owner>.github.io/<repo>` unless the repository variable `FLATPAK_REPO_BASE_URL` is set. One-time setup: **Settings > Pages > Source: GitHub Actions**.

```
curl -fLO https://<owner>.github.io/<repo>/install-flatpak.sh && bash install-flatpak.sh
flatpak update        # later, to get new versions
```

The repository is not signed yet, so Flatpak adds it with signature checking off.

Data lives in `~/.var/app/BfmeFoundationProject.AllInOneLauncher.Linux/data/bfme-foundation`.
