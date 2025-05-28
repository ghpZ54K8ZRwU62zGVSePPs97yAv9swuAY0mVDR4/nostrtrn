# Nip

NIP stands for Nostr Implementation Possibilities. NIP is a collection of Move smart contracts for the context of Nostr.

## On-chain Verification

NIP smart contracts verify integrity and authenticity of the Nostr events on-chain. It provides verifications on-chain from Move smart contract supported verification schemes.

### Protocol Implementation

Implemented:

- [x] NIP-01 - implements secp256k1 elliptic curve over Schnorr signature for verification of signatures of Nostr events in order to persist authentic and verified Nostr events on-chain.

High priority:

- [ ] NIP-39 - bind Rooch DID document and on-chain identity to a Nostr user metadata event to confirm external identification with Rooch Network, e.g. `rooch:<address>`.

Medium priority:

- [ ] NIP-57 - records and persist important lightning payments of Nostr events and validates zap request and zap receipt integrity on-chain.

Low priority:

- [ ] NIP-03 - provides verification method of OpenTimestamps proof OTS file data in base64 encoded format in content fields of Nostr events on-chain. Need to support OpenTimestamps for Bitcoin attestations on Rooch.
- [ ] NIP-13 - calculates PoW text notes of Nostr events and validate it on-chain.
- [ ] NIP-60 - supports cashu-based wallet and provides accessibility to proof validation of unspent proofs in token events using users' private keys from wallet event to stay in the newest state.

## License

This work, under `move/nip`, of nostrtrn, is dual-licensed under version 3 (or any later version) of the GNU Affero General Public License and Apache License, Version 2.0.

Both licenses should be complied.

One may obtain a copy of the Apache License, Version 2.0 from this URL:

https://github.com/rooch-network/rooch/blob/main/LICENSE.

One may obtain a copy of the version 3 (or any later version) of the GNU Affero General Public License from the root of this project:

[LICENSE](../../LICENSE).

When deriviate works from this repository, add below licensings of the SPDX license identifier:

```move
// Copyright (C) 2025  ZHANG, HENGMING
// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (c) RoochNetwork
// SPDX-License-Identifier: Apache-2.0
```

Above equals to `(AGPL-3.0-or-later AND Apache-2.0)` syntax of a SPDX-License-Identifier.
