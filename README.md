# Apple-Only Firewall (Surge v5)

This module blocks all outbound connections except those to Apple-owned domains.

## Usage (iOS)
1. Add `apple-only.sgmodule` as a local module in Surge.
2. Place it after other rule modules so the final `REJECT` is enforced.

## Notes
- This is intentionally strict and will break Apple services that rely on third-party CDNs.
- Add more `DOMAIN-SUFFIX` entries if you need additional Apple domains.
