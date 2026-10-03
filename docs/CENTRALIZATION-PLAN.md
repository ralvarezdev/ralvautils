# RalvaUtils — Centralization Plan

A plan for turning this folder of loose PowerShell scripts into a single, discoverable toolbox.

## Current state

The folder mixes three different kinds of files that need different treatment:

### 1. Real runnable scripts
These do work when executed and should become module functions.

| File | Purpose |
| --- | --- |
| `check-kebab-case.ps1` | Lints filenames for kebab-case violations |
| `delete-dev-cache-from-local.ps1` | Removes dev/build caches from local disk |
| `delete-dev-cache-from-onedrive.ps1` | Removes dev/build caches synced in OneDrive |
| `onedrive-remove-cloud-conflicts.ps1` | Removes OneDrive cloud-conflict copies |
| `ignore-dev-by-onedrive.ps1` | Marks dev folders to be ignored by OneDrive |
| `fix-onedrive-git-mess.ps1` | Repairs git repos confused by OneDrive sync |
| `get-files-modified-today.ps1` | Lists files modified today |
| `log-files-laptop-suffix.ps1` | Logs files with a laptop suffix |
| `log-modified-and-created-today-and-yesterday.ps1` | Logs recently created/modified files |
| `git-modify-committed-date.ps1` | Rewrites a commit's committed date |
| `nul-removal.ps1` | Removes stray `nul` files |

### 2. Defined but never invoked
| File | Issue |
| --- | --- |
| `project-cleanup.ps1` | Defines `Invoke-ProjectCleanup` but never calls it — running the file does nothing |

### 3. Cheatsheet snippets, not scripts
These are notes meant to be run by hand, not executed as `.ps1` files.

| File | Issue |
| --- | --- |
| `git-remote-fetch.ps1` | Contains literal `username/repo-name` placeholder |
| `mount-ehdd.ps1` | Mixes PowerShell + bash/WSL commands meant for manual use |
| `git-compact.ps1` | Empty |
| `link-games.ps1` | Empty |
| `reset-onedrive.ps1` | Empty |

## Recommended approach: a PowerShell module

This is the idiomatic Windows answer and solves discoverability and reuse.

```
ralvautils/
├─ RalvaUtils.psd1          # module manifest (lists exported functions)
├─ RalvaUtils.psm1          # dot-sources everything in Functions/
├─ Functions/
│  ├─ git/        Invoke-GitCompact.ps1, Set-GitCommitDate.ps1 ...
│  ├─ onedrive/   Repair-OneDriveGit.ps1, Reset-OneDrive.ps1, Remove-OneDriveConflict.ps1 ...
│  ├─ devcache/   Invoke-ProjectCleanup.ps1, Remove-DevCache.ps1 ...
│  ├─ files/      Test-KebabCase.ps1, Get-FilesModifiedToday.ps1, Write-FileLog.ps1 ...
│  └─ system/     Mount-Ehdd.ps1 ...
├─ Snippets/      # cheatsheets that aren't real scripts — kept as .md or notes
│  └─ mount-ehdd.md, git-remote-setup.md
├─ README.md      # index: what each command does
└─ check-kebab-case.ps1     # becomes a lint helper run on the module itself
```

### Why a module beats a folder of loose scripts
- One `Import-Module RalvaUtils` (or auto-load via `$PROFILE`) makes every command available everywhere — no `cd`-ing to the folder or typing full paths.
- Each utility becomes a named **function** (`Verb-Noun`, e.g. `Remove-DevCache`) with tab-completion, `Get-Help`, and the ability to call one from another.
- Shared helpers (colored `Write-Host` patterns, confirm prompts, root-path lists like `$myProjectRoots`) live in one place instead of being copy-pasted.

### Naming convention
Files stay kebab-case (and the `check-kebab-case` linter keeps enforcing it). The function *inside* each file uses `Verb-Noun` PascalCase with an approved verb.

| File | Function |
| --- | --- |
| `remove-dev-cache.ps1` | `Remove-DevCache` |
| `check-kebab-case.ps1` | `Test-KebabCase` |
| `get-files-modified-today.ps1` | `Get-FilesModifiedToday` |

The linter just needs to skip the module manifest (`.psd1`/`.psm1`).

## Lighter alternative

If a full module feels heavy for a personal toolbox, the minimum viable centralization is:
- Group the loose `.ps1` files into category subfolders.
- Add a `README.md` table (script → one-line description).
- Add a `profile-snippet.ps1` that adds this repo to `$PATH` (or defines aliases), so scripts are callable by name from anywhere.
- Move cheatsheets/empty files out of `.ps1` into a `notes/` folder so they stop looking like broken scripts.

## Alternative: a Go CLI as dispatcher + plugin host

A different direction: a Go binary (`ralva <group> <cmd>`) that provides a unified command
surface and dispatches to implementations. Because most scripts are PowerShell- and
Windows-bound (OneDrive sync, WSL mount, git plumbing), Go does **not** reimplement the
logic — it acts as a *dispatcher + UX layer + plugin host*. PowerShell stays the engine.

### Core idea: one Command contract, multiple providers

```
                 ┌─────────────────────────┐
                 │   Cobra command tree     │  ← UX: help, completion, flags
                 └───────────┬─────────────┘
                             │ built from
                 ┌───────────▼─────────────┐
                 │      Registry            │
                 └───────────┬─────────────┘
            registered by ───┼───────────────┐
        ┌──────────────┐ ┌───▼─────────┐ ┌───▼──────────┐
        │ NativeProvider│ │EmbeddedProv.│ │ExternalProv. │
        │ (Go funcs)    │ │ (go:embed)  │ │(runtime dir) │
        └──────────────┘ └─────────────┘ └──────────────┘
                 │              │               │
                 └──────────────┼───────────────┘
                                ▼
                        ┌──────────────┐
                        │   Runners    │  powershell / bash / wsl / exe
                        └──────────────┘
```

- **`Command`** — name, group, summary, arg/flag schema, `Execute(ctx, args)`.
- **`Runner`** — invokes an interpreter (`powershell -File …`, `wsl …`, raw exe).
- **`Provider`** — any source that yields `Command`s into the registry.

### Extensibility tiers (all share one manifest schema)

| Tier | Source | Add a command by… | Single binary? |
| --- | --- | --- | --- |
| 1. Native | Go code | writing Go, recompile | yes |
| 2. Embedded | `go:embed` scripts + manifest | dropping a script, **recompile** | yes |
| 3. External | runtime plugin dir | dropping a script + manifest, **no recompile** | binary yes, scripts external |

Tier 3 (git external-subcommand model) is what makes it genuinely extensible: scan
`~/.ralva/commands/**/*.cmd.yaml` at startup. Add a utility by dropping two files — no Go
toolchain needed.

```yaml
# remove-dev-cache.cmd.yaml
name: remove-dev-cache
group: devcache
summary: Remove dev/build caches from local disk
runner: powershell
script: ./remove-dev-cache.ps1
flags:
  - { name: dry-run, type: bool, default: false }
  - { name: root,    type: string, required: false }
```

This composes with the module idea rather than competing: the PowerShell module becomes the
**script layer** the Go CLI embeds and/or discovers; each function gets a `.cmd.yaml` sidecar.

## Tradeoffs

### PowerShell module (Option A)
**Pros**
- Idiomatic on Windows; near-zero ceremony for a personal toolbox.
- Tab-completion, `Get-Help`, and global availability from one `Import-Module`.
- Scripts stay directly editable — change a `.ps1`, it takes effect immediately, no build.
- Native access to PowerShell strengths (OneDrive COM, pipeline objects, WSL interop).

**Cons**
- Windows/PowerShell-only; no path to cross-platform.
- "Extensibility" is just "add another function" — no declarative contract, no plugin model,
  no isolation between core and third-party commands.
- Distribution is a folder to clone + a `$PROFILE` edit, not a single artifact.
- No typed flag parsing or structured I/O contract beyond what each script hand-rolls.

### Go CLI dispatcher + plugin host (Option B)
**Pros**
- Single portable binary; trivial to drop on a fresh machine.
- Unified, discoverable surface with real flag parsing, completion, and consistent help
  across every command regardless of implementation language.
- Genuine extensibility: Tier 3 lets anyone add commands declaratively without recompiling
  or writing Go; core and external commands share one contract.
- A clean seam (the `Runner` abstraction) to later add bash/cross-platform without rework.

**Cons**
- Real upfront build: Cobra wiring, registry, manifest loader/validator, runners, plugin
  discovery — meaningful code before the first command runs.
- Two languages to maintain (Go front door + PowerShell engine); a bug can be in either.
- The binary still shells out to PowerShell, so it does **not** remove the Windows/pwsh
  dependency for most commands — Go buys UX and distribution, not portability of the logic.
- Tier 3 runs arbitrary scripts from a directory → a trust/allow-list concern if ever shared.
- Interpreter availability must be validated, or users get cryptic exec errors.
- Embedding (Tier 2) trades away the "just edit a `.ps1`" agility — a change needs a rebuild
  unless that command is also exposed via the external dir.

### When each wins
- **Choose the module** if this stays a personal Windows toolbox and the priority is low
  maintenance and direct editing.
- **Choose the Go CLI** if you want a single distributable binary, a polished/uniform UX, or
  a real third-party extension model — and you accept the upfront build and dual-language cost.
- **Hybrid** is viable: keep the PowerShell module as the engine, and add the Go CLI later as
  a thin host over it once the scripts are organized. The module work is not wasted either way.

## Decisions to make before building the Go CLI
1. **Interpreter availability** — validate runners exist; fail with a clear message.
2. **Trust** — Tier-3 discovery executes arbitrary scripts; gate it if the tool is ever shared.
3. **I/O contract** — exit codes only, or JSON on stdout that Go parses for richer UX.
4. **Cross-platform ambition** — Windows-only forever, or keep the `Runner` seam generic.
5. **Manifest versioning** — include `manifestVersion` from day one so the plugin contract can
   evolve without breaking external commands.

## Recommendation

Sequence them: **organize as the PowerShell module first** (low cost, immediately useful, and
it's the script layer either architecture needs), then add the **Go CLI dispatcher** if and
when you want single-binary distribution or a declarative plugin model. Building the Go host
first, before the scripts are structured, front-loads the hardest work onto the least certain
requirement.

### Suggested first step
Convert the existing runnable scripts into functions and wire up `RalvaUtils.psm1` /
`RalvaUtils.psd1`, leaving the snippets and empty files to be triaged separately. This is the
shared foundation; the Go CLI, if pursued, sits on top of it.
