# Nips

NIPs stand for Nostr Implementation Possibilities. NIPs under this project are collections of Move smart contracts for the context of Nostr.

## On-chain Verification

NIPs' smart contracts in Move verify integrity and authenticity of the Nostr events on-chain. It provides verifications on-chain from Move smart contract supported verification schemes.

### Protocol Implementation

NIPs under this project implement Nostr protocols in Move programming language.

The implementation goals of this project are defined as below.

Implemented:

- [x] NIP-01 - implements secp256k1 elliptic curve over Schnorr signature for verification of signatures of Nostr events in order to persist authentic and verified Nostr events on-chain.

High priority:

- [ ] NIP-39 - bind Rooch DID document and on-chain identity to a Nostr user metadata event to confirm external identification with Rooch Network, e.g. `rooch:<address>`.

Medium priority:

- [ ] NIP-57 - records and persist important lightning payments of Nostr events and validates zap request and zap receipt integrity on-chain.

Low priority:

- [ ] NIP-03 - provides verification method of OpenTimestamps proof OTS file data in base64 encoded format in content fields of Nostr events on-chain. Need to support OpenTimestamps for Bitcoin attestations on Rooch.
- [ ] NIP-13 - calculates PoW text notes of Nostr events and validate it on-chain.
- [ ] NIP-53 - verification of the proofs of the p tags in live events using hex-encoded signed SHA-256 of a tags from event owners on-chain.
- [ ] NIP-60 - supports cashu-based wallet and provides accessibility to proof validation of unspent proofs in token events using users' private keys from wallet event to stay in the newest state.
- [ ] NIP-61 - verify NUT-12 (DLEQ proofs) in an event received cashu zaps on-chain from an observer blockchain client.

### Contract Addresses

Move smart contracts of NIPs of this project are deployed to Rooch Network. The deployed contract addresses of each NIP align with Rooch Network's env alias, i.e. local, dev, test, main, which can be found in the values of `[addresses]` in each NIP's `Move.toml` file.

## Related Links

- NIPs: https://github.com/nostr-protocol/nips.
