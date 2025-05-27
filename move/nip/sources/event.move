// event.move, based on RoochNetwork's Move base smart contract at https://github.com/rooch-network/rooch/blob/main/examples/nostr/sources/event.move.
// Copyright (C) 2025  ZHANG, HENGMING
// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (c) RoochNetwork
// SPDX-License-Identifier: Apache-2.0

/*
/// Module: nip
/// Name: event
/// Description: Implements NIP-01 event structure
*/
module nip::event {
    use std::vector;
    use std::string::{Self, String};
    use std::option::{Self, Option};
    use moveos_std::signer;
    use moveos_std::object::{Self, ObjectID};
    use moveos_std::hash;
    use moveos_std::hex;
    use moveos_std::timestamp;
    use moveos_std::event;
    use moveos_std::json;
    use moveos_std::string_utils;
    use rooch_framework::ecdsa_k1;
    use nip::inner;

    // Kind of the event
    const EVENT_KIND_USER_METADATA: u16 = 0;

    // Error codes starting from 1000
    const ErrorMalformedId: u64 = 1000;
    const ErrorSignatureValidationFailure: u64 = 1001;
    const ErrorMalformedPublicKey: u64 = 1002;
    const ErrorUtf8Encoding: u64 = 1003;
    const ErrorMalformedSignature: u64 = 1004;
    const ErrorEventStoreNotExist: u64 = 1005;
    const ErrorSigAlreadyExists: u64 = 1006;

    #[data_struct]
    /// EventStore
    struct EventStore has key, copy, drop {
        events: vector<Event>
    }

    #[data_struct]
    /// Event
    struct Event has key, store, copy, drop {
        id: vector<u8>, // 32-bytes lowercase hex-encoded sha256 of the serialized event data
        pubkey: vector<u8>, // 32-bytes lowercase hex-encoded public key of the event creator
        created_at: u64, // unix timestamp in seconds
        kind: u16, // integer between 0 and 65535
        tags: vector<vector<String>>, // arbitrary string
        content: String, // arbitrary string
        sig: Option<vector<u8>> // 64-bytes lowercase hex of the signature of the sha256 hash of the serialized event data, which is the same as the "id" field
    }

    #[data_struct]
    /// Event create notification for Move events
    struct NostrEventCreatedEvent has copy, drop {
        id: ObjectID
    }

    #[data_struct]
    /// Event update notification for Move events
    struct NostrEventUpdatedEvent has copy, drop {
        id: ObjectID
    }

    #[data_struct]
    /// Event save notification for Move events
    struct NostrEventSavedEvent has copy, drop {
        id: ObjectID
    }

    #[data_struct]
    /// UserMetadata field as stringified JSON object, when the Event kind is equal to 0
    struct UserMetadata has copy, drop {
        name: String,
        about: String,
        picture: String
    }

    /// Serialize to byte arrays, which could be sha256 hashed and hex-encoded with lowercase to 32 byte arrays
    fun serialize(pubkey: String, created_at: u64, kind: u16, tags: vector<vector<String>>, content: String): vector<u8> {
        let serialized = string::utf8(b"");
        let left_sb = string::utf8(b"[");
        let right_sb = string::utf8(b"]");
        let double_qm = string::utf8(b"\"");
        let coma = string::utf8(b",");

        // version 0, as described in NIP-01
        let version = 0;
        let version_str = string_utils::to_string_u8(version);
        string::append(&mut serialized, left_sb);
        string::append(&mut serialized, version_str);
        string::append(&mut serialized, coma);

        // pubkey
        assert!(string::length(&pubkey) == 64, ErrorMalformedPublicKey);
        string::append(&mut serialized, double_qm);
        string::append(&mut serialized, pubkey);
        string::append(&mut serialized, double_qm);
        string::append(&mut serialized, coma);

        // created_at
        let created_at_str = string_utils::to_string_u64(created_at);
        string::append(&mut serialized, created_at_str);
        string::append(&mut serialized, coma);

        // kind
        let kind_str = string_utils::to_string_u16(kind);
        string::append(&mut serialized, kind_str);
        string::append(&mut serialized, coma);

        // tags
        let tags_str = string::utf8(json::to_json(&tags));
        string::append(&mut serialized, tags_str);
        string::append(&mut serialized, coma);

        // content
        string::append(&mut serialized, double_qm);
        string::append(&mut serialized, content);
        string::append(&mut serialized, double_qm);
        string::append(&mut serialized, right_sb);

        // get the serialized string bytes
        let serialized_bytes = string::into_bytes(serialized);

        // check UTF-8 encoding
        assert!(string::internal_check_utf8(&serialized_bytes), ErrorUtf8Encoding);

        serialized_bytes
    }

    /// Check signature with public key, id and signature for schnorr
    fun check_signature(id: vector<u8>, x_only_public_key: vector<u8>, signature: vector<u8>) {
        assert!(ecdsa_k1::verify(
            &signature,
            &x_only_public_key,
            &id,
            ecdsa_k1::sha256()
        ), ErrorSignatureValidationFailure);
    }

    /// Create an Event id
    fun create_event_id(pubkey: String, created_at: u64, kind: u16, tags: vector<vector<String>>, content: String): vector<u8> {
        // serialize input to bytes for an Event id
        let serialized = serialize(pubkey, created_at, kind, tags, content);

        // hash with sha256
        let id = hash::sha2_256(serialized);

        // verify the length of the hex bytes to 32 bytes (64 characters)
        assert!(vector::length(&hex::encode(id)) == 64, ErrorMalformedId);

        id
    }

    /// Create an Event for signing
    public fun create_event(x_only_public_key: String, kind: u16, tags: vector<vector<String>>, content: String): vector<u8> {
        // get now timestamp by seconds
        let created_at = timestamp::now_seconds();

        // create event id
        let id = create_event_id(x_only_public_key, created_at, kind, tags, content);

        // get the hex decoded public key bytes
        let pubkey = hex::decode(&string::into_bytes(x_only_public_key));

        // derive a rooch address
        let rooch_address = inner::derive_rooch_address(pubkey);

        // init an empty signature
        let sig = option::none<vector<u8>>();

        // save the event for signing to the rooch address mapped to the public key
        let event = Event {
            id,
            pubkey,
            created_at,
            kind,
            tags,
            content,
            sig,
        };
        // borrow event store
        let event_store = borrow_mut_event_store(rooch_address);
        // borrow inner mutable events
        let events = borrow_mut_events(event_store);
        // get the event for signing pushed to the event store's events
        vector::push_back<Event>(events, event);

        // emit a move event nofitication
        let event_store_object_id = event_store_object_id(rooch_address);
        let move_event = NostrEventCreatedEvent {
            id: event_store_object_id
        };
        event::emit(move_event);

        // return the event object as JSON
        let event_json = json::to_json<Event>(&event);
        event_json
    }

    /// Entry function to create an Event for signing
    public entry fun create_event_entry(x_only_public_key: String, kind: u16, tags: vector<vector<String>>, content: String) {
        let _event_json = create_event(x_only_public_key, kind, tags, content);
    }

    /// Update a signature under the sig field of an Event
    public fun update_event_signature(signer: &signer, signature: String): vector<u8> {
        // get the signer's rooch address
        let rooch_address = signer::address_of(signer);

        // get the event store object id from the address
        let event_store_object_id = event_store_object_id(rooch_address);

        // check the event store object id if it exists
        assert!(object::exists_object_with_type<EventStore>(event_store_object_id), ErrorEventStoreNotExist);

        // borrow event store from the event store object id
        let event_store = borrow_mut_event_store_from_object_id(event_store_object_id);

        // borrow inner mutable events
        let events = borrow_mut_events(event_store);

        // get the last element of event
        let last_event_index = vector::length(events) - 1;

        // get the signature of the last event updated
        let event = vector::borrow_mut(events, last_event_index);

        // flatten the elements
        let (id, pubkey, _created_at, kind, _tags, content, sig) = unpack_event(*event);

        // avoid overide signature
        assert!(option::is_none(&sig), ErrorSigAlreadyExists);

        // decode signature with hex
        let update_sig = hex::decode(&string::into_bytes(signature));

        // check the signature
        check_signature(id, pubkey, update_sig);

        // handle a range of different kinds of an Event
        if (kind == EVENT_KIND_USER_METADATA) {
            // check the content integrity
            let content_bytes = string::bytes(&content);
            let _ = json::from_json<UserMetadata>(*content_bytes);
            // clear past user metadata events from the user with the same rooch address from the public key
            let event_object_id = object::account_named_object_id<Event>(rooch_address);
            if (object::exists_object_with_type<Event>(event_object_id)) {
                let event_object = object::take_object_extend<Event>(event_object_id);
                let event = object::remove(event_object);
                drop_event(event);
            };
        };

        // update the signature of the sig field of the event
        option::fill<vector<u8>>(&mut event.sig, update_sig);

        // emit a move event nofitication
        let move_event = NostrEventUpdatedEvent {
            id: event_store_object_id
        };
        event::emit(move_event);

        // return the signature updated
        update_sig
    }

    /// Entry function to update a signature under sig field of an Event
    public entry fun update_event_signature_entry(signer: &signer, signature: String) {
        let _update_sig = update_event_signature(signer, signature);
    }

    /// Save an Event
    public fun save_event(x_only_public_key: String, created_at: u64, kind: u16, tags: vector<vector<String>>, content: String, signature: String): vector<u8> {
        // check signature length
        assert!(string::length(&signature) == 128, ErrorMalformedSignature);

        // check public key length
        assert!(string::length(&x_only_public_key) == 64, ErrorMalformedPublicKey);

        // create event id
        let id = create_event_id(x_only_public_key, created_at, kind, tags, content);

        // get the hex decoded public key bytes
        let pubkey = hex::decode(&string::into_bytes(x_only_public_key));

        // get the hex decoded signature bytes
        let check_sig = hex::decode(&string::into_bytes(signature));

        // check the signature
        check_signature(id, pubkey, check_sig);

        // derive a rooch address
        let rooch_address = inner::derive_rooch_address(pubkey);

        // handle a range of different kinds of an Event
        if (kind == EVENT_KIND_USER_METADATA) {
            // check the content integrity
            let content_bytes = string::bytes(&content);
            let _ = json::from_json<UserMetadata>(*content_bytes);
            // clear past user metadata events from the user with the same rooch address from the public key
            let event_object_id = object::account_named_object_id<Event>(rooch_address);
            if (object::exists_object_with_type<Event>(event_object_id)) {
                let event_object = object::take_object_extend<Event>(event_object_id);
                let event = object::remove(event_object);
                drop_event(event);
            };
        };

        // pass check sig as option to form sig option
        let sig = option::some<vector<u8>>(check_sig);

        // save the event to the rooch address mapped to the public key
        let event = Event {
            id,
            pubkey,
            created_at,
            kind,
            tags,
            content,
            sig
        };
        // borrow event store
        let event_store = borrow_mut_event_store(rooch_address);
        // borrow inner mutable events
        let events = borrow_mut_events(event_store);
        // get the event pushed to the event store's events
        vector::push_back<Event>(events, event);

        // emit a move event nofitication
        let event_store_object_id = event_store_object_id(rooch_address);
        let move_event = NostrEventSavedEvent {
            id: event_store_object_id
        };
        event::emit(move_event);

        // return the event object as JSON
        let event_json = json::to_json<Event>(&event);
        event_json
    }

    /// Entry function to save an Event
    public entry fun save_event_entry(x_only_public_key: String, created_at: u64, kind: u16, tags: vector<vector<String>>, content: String, signature: String) {
        let _event_json = save_event(x_only_public_key, created_at, kind, tags, content, signature);
    }

    /// drop an event
    fun drop_event(event: Event) {
        let Event {id: _, pubkey: _, created_at: _, kind: _, tags: _, content: _, sig: _} = event;
    }

    public fun unpack_event(event: Event): (vector<u8>, vector<u8>, u64, u16, vector<vector<String>>, String, Option<vector<u8>>) {
        let Event { id, pubkey, created_at, kind, tags, content, sig } = event;
        (id, pubkey, created_at, kind, tags, content, sig)
    }

    fun event_store_object_id(rooch_address: address): ObjectID {
        let event_store_object_id = object::account_named_object_id<EventStore>(rooch_address);
        event_store_object_id
    }

    fun borrow_mut_event_store(rooch_address: address): &mut EventStore {
        // get the event store object id from the address
        let event_store_object_id = event_store_object_id(rooch_address);

        // check the event store object id if it exists, if not, create an empty one
        if (!object::exists_object_with_type<EventStore>(event_store_object_id)) {
            return init_event_store(rooch_address)
        };

        // borrow the event store from the event store object id
        let event_store = borrow_mut_event_store_from_object_id(event_store_object_id);

        event_store
    }

    fun borrow_mut_event_store_from_object_id(event_store_object_id: ObjectID): &mut EventStore {
        // take the event store object from the object store
        let event_store_object = object::borrow_mut_object_extend<EventStore>(event_store_object_id);

        // borrow the event store
        let event_store = object::borrow_mut<EventStore>(event_store_object);

        event_store
    }

    fun init_event_store(rooch_address: address): &mut EventStore {
        // create an event store object and transfer to the rooch address
        let empty_event_store = empty_event_store();
        let event_store_object = object::new_account_named_object<EventStore>(rooch_address, empty_event_store);
        object::transfer_extend(event_store_object, rooch_address);
        // retrieve the mutable event store from the rooch address
        let event_store_object_id = event_store_object_id(rooch_address);
        let event_store = borrow_mut_event_store_from_object_id(event_store_object_id);

        event_store
    }

    fun empty_event_store(): EventStore {
        let event_store = EventStore {
            events: vector::empty<Event>()
        };

        event_store
    }

    fun borrow_mut_events(event_store: &mut EventStore): &mut vector<Event> {
        &mut event_store.events
    }

    /// getter functions for event

    public fun id(event: &Event): vector<u8> {
        event.id
    }

    public fun pubkey(event: &Event): vector<u8> {
        event.pubkey
    }

    public fun created_at(event: &Event): u64 {
        event.created_at
    }

    public fun kind(event: &Event): u16 {
        event.kind
    }

    public fun tags(event: &Event): vector<vector<String>> {
        event.tags
    }

    public fun content(event: &Event): String {
        event.content
    }

    public fun sig(event: &Event): Option<vector<u8>> {
        event.sig
    }

    /// getter functions for event store

    public fun events(event_store: &EventStore): vector<Event> {
        event_store.events
    }
}
