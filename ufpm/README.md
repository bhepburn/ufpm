# ufpm - OpenWrt device fingerprinting

The `ufpm` package identifies connected devices by matching their MAC address against IEEE OUI vendor databases. Each database tier has a weight — more specific prefixes score higher, and the first match in priority order wins.

## uBus API

* `ubus call fingerprint fingerprint` — Main user-facing method. Returns the matched vendor for a device.
* `ubus call fingerprint get_data` — Returns the raw device data used for matching.
* `ubus call fingerprint add_data` — Adds a MAC address to the device table.
* `ubus call fingerprint load_fingerprints` — Loads a custom fingerprint JSON override at runtime.

## MAC lookup priority

| Prefix | Characters matched | Weight |
|---|---|---|
| `mac-iab-`   | 9 | 10.0 |
| `mac-oui36-` | 9 |  8.0 |
| `mac-oui28-` | 7 |  5.0 |
| `mac-oui-`   | 6 |  3.0 |

The first database tier to produce a match wins. IAB is preferred over OUI-36 when both cover the same 9-character prefix.

## Vendor databases

dedOn first boot `scripts/update-oui.uc` downloads the four IEEE CSV sources and
compiles each one into a binary hash table under `/usr/share/ufpm/db/`:

| Source | Output |
|---|---|
| `http://standards-oui.ieee.org/oui/oui.csv`      | `db/oui.bin`   |
| `https://standards-oui.ieee.org/oui28/mam.csv`   | `db/oui28.bin` |
| `https://standards-oui.ieee.org/oui36/oui36.csv` | `db/oui36.bin` |
| `https://standards-oui.ieee.org/iab/iab.csv`     | `db/iab.bin`   |

## Building

This package is built as part of the OpenWrt package feed. The C ucode extension
(`src/`) is compiled via CMake and installed as `uht.so`. The OUI vendor databases
are fetched and compiled at runtime by `update-oui.uc` — no build-time data files
are required.
