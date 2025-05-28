# Nostrtrn

Nostrtrn stands for Notes and Other Stuff Transmitted by Relays Through Rooch Network.

## Introduction

Introduce Nostrtrn, a Nostr bridge on Rooch Network. It bridges Nostr to Rooch Network and builds stuff on verificable data and proofs on-chain.

## Triangle

### Relationship With Nostr

#### As On-chain Event Converter

Nostrtrn accepts events from Nostr and converts the events stored in databases from Nostr relays to on-chain Nostr events in Move state at nearly zero data loss rate.

### Relationship With Rooch Network

#### As Client-side Proof Verification Machine

When use Nostrtrn as a client-side verification machine on Rooch Network for verifying proofs produced or generated from Nostr relays, it will produce results such as `0` or `1` in binary, `false` or `true` in program, or `falsified` or `verified` in common language.

#### As Verifiable Data Registry

Nostrtrn builds on Rooch Network and uses Rooch Network as Verifiable Data Registry, or VDR.

Nostrtrn leverages Nostr in Move project to persist Nostr events on Rooch Network as verifiable data source, and communicates with external registered Nostr relays via a service discovery and registry mechanism on Rooch Network.

## Related Links

- Verifiable Data Registry (VDR): https://github.com/nuwa-protocol/NIPs/blob/main/nips/nip-1.md.

## License

Root project of Nostrtrn is licensed under version 3 (or any later version) of the GNU Affero General Public License.
