# Fishblood

> **Nightscout blood glucose values in your Fish shell — for people with Type 1 diabetes who live in the terminal.**

Fishblood is a [Fish shell](https://fishshell.com/) plugin that fetches your current blood glucose, trend arrow, and delta from a [Nightscout](https://nightscout.github.io/) instance and displays them either in your prompt or on demand from the command line. Built by a T1D dev who wanted to glance at their CGM data without leaving the terminal.

Works with any CGM that feeds Nightscout: **Dexcom**, **FreeStyle Libre**, **Medtronic**, **Eversense**, etc. Supports both **mmol/L** (UK, EU, AU) and **mg/dL** (US) display units.

### Quickstart

```fish
fisher install elgumso/fishblood
set -U fishblood_url https://your.nightscout.example
fishblood enable
```

That's it. Open a new shell and your blood glucose is in the prompt. For mg/dL instead of mmol/L: `fishblood units mgdl`.

### Two modes

Pick whichever fits how you work — they're independent and you can use both:

1. **Prompt mode.** A glucose segment is spliced into your `fish_prompt` and shows up on every prompt render. Enable with `fishblood enable`.

   ```
   elgumso @ myhost --> 7.2 → {-0.1} ~>
   ```
2. **Call mode.** Your prompt is left untouched. Run `bloodsugar` from the command line whenever you want to check:

   ```
   $ bloodsugar
   7.2 mmol/L → -0.1
   ```

   `bloodsugar mgdl` or `bloodsugar mmol` overrides the display unit for that one call. With no argument, it uses `$fishblood_units` (defaults to `mmol`). Call mode does a **synchronous** fetch if the cache is stale — you're waiting on it interactively, so it goes and gets it.

To use call mode only, just don't run `fishblood enable`. The `bloodsugar` function is always available either way.

### How it works

The `fishblood_prompt_segment` function (used by prompt mode) checks an on-disk cache (default `/tmp/blood`); if it's older than `fishblood_update_interval` seconds (default 60), a `curl` to your Nightscout endpoint is fired off in the background via `&` + `disown`. The prompt never blocks on the network — it reads whatever's currently in the cache, and the next render picks up the fresh value. No cron job, no background daemon, no `sudo`, nothing that gets clobbered on a `fish` package upgrade.

Glucose values are fetched from the `/pebble` endpoint, which returns values matching what the Nightscout UI displays. The plugin auto-detects whether your server reports in mmol/L or mg/dL (values under 40 are mmol/L) and converts at display time based on `$fishblood_units`, so changing units takes effect on the next prompt render with no refetch needed.

Values are colour-coded: **green** when in range (3.9–10.0 mmol/L / 70–180 mg/dL), **red** when low or high.

### Trend arrow

The Nightscout `direction` field renders as a unicode arrow between the value and the delta:

| direction | arrow |
|---|---|
| `DoubleUp` | ⇈ |
| `SingleUp` | ↑ |
| `FortyFiveUp` | ↗ |
| `Flat` | → |
| `FortyFiveDown` | ↘ |
| `SingleDown` | ↓ |
| `DoubleDown` | ⇊ |
| `NONE`, `NOT COMPUTABLE`, `RATE OUT OF RANGE` | (hidden) |

### Dependencies

- [Fish shell](https://fishshell.com/) 3.3.0 or newer
- `curl` and `jq`
- A [Nightscout](https://nightscout.github.io/) instance with the `/pebble` endpoint reachable (auth optional — see API secret below)

### Installation

With [Fisher](https://github.com/jorgebucaran/fisher) (recommended):

```fish
fisher install elgumso/fishblood
```

Manual install — a POSIX shell installer is provided for users who don't run a plugin manager:

```sh
git clone https://github.com/elgumso/fishblood
cd fishblood
./install.sh
```

The installer checks for `fish` ≥ 3.3.0, `curl`, and `jq`, then copies the plugin files into `$XDG_CONFIG_HOME/fish` (default `~/.config/fish`).

### Configuration

Fishblood reads five universal variables. Set them once and they persist across shells:

```fish
set -U fishblood_url https://your.nightscout.example
set -U fishblood_units mmol                # mmol or mgdl; default mmol
set -U fishblood_update_interval 60        # seconds; default 60
set -U fishblood_cache /tmp/blood          # default /tmp/blood
set -U fishblood_api_secret ''             # optional; see below
```

Until `fishblood_url` is pointed at a real instance, the prompt segment stays empty and `bloodsugar` fails clearly — no requests are made to the placeholder URL.

#### API secret (for locked-down instances)

If your Nightscout instance requires authentication for `/api/v1/entries`, set `fishblood_api_secret` to the **plaintext** secret you configured as `API_SECRET` on the server:

```fish
set -U fishblood_api_secret 'your-plaintext-secret-here'
```

Fishblood computes the SHA1 hex digest locally (via `sha1sum`, falling back to `shasum` on macOS/BSD) and sends it as the `api-secret` HTTP header Nightscout expects. The plaintext never leaves your machine. To disable auth again, clear it: `set -U fishblood_api_secret ''`.

### Enabling the prompt segment

```fish
fishblood enable
```

This:

1. Copies your current `fish_prompt` to `$__fish_config_dir/functions/fish_prompt.fish` if you don't already have one there (uses `funcsave` to capture the fish default).
2. Backs it up to `fish_prompt.fish.fishblood.bak`.
3. Injects a call to `fishblood_prompt_segment` immediately before the closing `end`.

Start a new shell to see it. If you have a heavily-customized prompt and want the segment in a specific place, skip `fishblood enable` and add `fishblood_prompt_segment` to your `fish_prompt` by hand.

> **Using a prompt framework like [Tide](https://github.com/IlanCosman/tide), [Starship](https://starship.rs/), or [Hydro](https://github.com/jorgebucaran/hydro)?** Don't run `fishblood enable` — it would patch the framework's wrapper file and likely break on the framework's next update. Use **call mode** instead: `bloodsugar` works regardless of what prompt you're running, and you can bind it to a key or alias if you want it always at hand.

### Commands

```
bloodsugar [mmol|mgdl]      # call mode: print current value, trend, delta

fishblood status            # show URL, units, cache path, interval, current value, age
fishblood refresh           # force an immediate (synchronous) fetch
fishblood units [mmol|mgdl] # show or set display units
fishblood enable            # prompt mode: splice segment into fish_prompt
fishblood disable           # restore the backup (or strip the segment call)
fishblood help
```

### Uninstalling

With Fisher:

```fish
fisher remove elgumso/fishblood
```

Fisher fires the `_fishblood_uninstall` event, which runs `fishblood disable` (restoring your backed-up `fish_prompt`), removes the cache file, and erases the universal variables.

Manual installs use the matching uninstaller:

```sh
./uninstall.sh
```

Same cleanup: restores the prompt backup, clears the cache, erases the universal variables, deletes the plugin files.

### Disclaimer

Fishblood is a glanceable display, not a medical device. Do not make treatment decisions based on what your terminal shows you. Always confirm with your CGM, meter, or care team. The author of this plugin is not a clinician.

### Keywords

Nightscout · Fish shell · Type 1 diabetes · T1D · CGM · continuous glucose monitor · blood glucose · BGL · Dexcom · FreeStyle Libre · Libre · diabetes terminal · fish prompt · diabetes CLI tools · mmol/L · mg/dL
