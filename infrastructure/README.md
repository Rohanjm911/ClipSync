# ClipSync Self-Hosted Infrastructure

This directory contains standalone, lightweight zero-knowledge networking services for ClipSync.

## Services

1. **Signaling Server (`infrastructure/signaling`)**:
   Coordinates WebRTC SDP offers/answers and ICE candidates over secure WebSockets. Clients authenticate via signed challenge tokens.
   - Run: `cd signaling && npm start`
   - Default Port: `8080` (or `PORT` environment variable)

2. **Encrypted Relay Server (`infrastructure/relay`)**:
   Operates as a zero-knowledge packet forwarder when direct LAN and WebRTC P2P NAT traversal are blocked by carrier-grade symmetric NATs.
   - Run: `cd relay && npm start`
   - Default Port: `8081` (or `PORT` environment variable)

## Zero-Knowledge Guarantee
Neither the signaling server nor the relay server has access to private keys or decryption keys. All clipboard content and files are end-to-end encrypted with ChaCha20-Poly1305 before transmission.
