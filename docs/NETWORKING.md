# ClipSync Networking Architecture (`NETWORKING.md`)

## 1. Smart Hybrid Networking Strategy

ClipSync implements a dynamic three-tier connection hierarchy designed to maximize throughput, minimize latency, and operate seamlessly whether devices are connected to the same home Wi-Fi network or across cellular networks.

```
                  +---------------------------+
                  |  Clipboard / File Action  |
                  +---------------------------+
                                |
             +------------------v------------------+
             | Is Peer available on Local Network? |
             +------------------+------------------+
                       /                 \
                     YES                  NO
                     /                     \
       +--------------------+      +--------------------+
       | Direct TLS/TCP     |      | Remote Signaling   |
       | Local Stream       |      | (WebSocket)        |
       +--------------------+      +---------+----------+
                                             |
                                  +----------v----------+
                                  | Can WebRTC P2P      |
                                  | establish direct    |
                                  | ICE DataChannel?    |
                                  +----------+----------+
                                        /         \
                                      YES          NO
                                      /             \
                         +-------------------+   +--------------------+
                         | Direct WebRTC P2P |   | Encrypted Relay    |
                         | DataChannel       |   | Fallback Forwarder |
                         +-------------------+   +--------------------+
```

---

## 2. Mode A: Local Network Discovery & Direct Transport

### 2.1 mDNS / DNS-SD Service Registration
- Service type: `_clipsync._tcp.local`
- Published records:
  - `port`: Dynamically bound TCP port (e.g. `48901`).
  - `txt.id`: SHA-256 fingerprint prefix of the host device.
  - `txt.ver`: Protocol version (`1`).
  - `txt.name`: Friendly host name.

### 2.2 UDP Broadcast Fallback
In enterprise or guest networks where multicast (mDNS) is blocked by router access point isolation:
- Broadcast port: UDP `48902`.
- Periodic beacon: Sends encrypted discovery ping containing ephemeral challenge.

### 2.3 Direct Authenticated Transport
- Once discovered, nodes establish a direct TCP connection.
- Handshake executes an authenticated challenge-response validating the paired Ed25519 identity keys.
- Traffic is encrypted via ChaCha20-Poly1305 frame streams.
- Measured latency: Typically < 20ms on modern 802.11ac/ax Wi-Fi.

---

## 3. Mode B: Remote Peer-to-Peer (WebRTC)

When devices are on disparate networks (e.g., Windows laptop on office Wi-Fi, Android phone on LTE):
1. **Signaling:** Both clients connect to the configured signaling endpoint via secure WebSocket (`wss://`).
2. **Authentication:** Each client signs a server-provided nonce with their Ed25519 identity key.
3. **Session Negotiation:** Sender issues an encrypted WebRTC SDP Offer through the signaling socket addressed to the paired peer's device ID.
4. **ICE Candidate Exchange:** STUN servers (`stun.l.google.com:19302`) gather host, server-reflexive, and relay candidates.
5. **DataChannel:** Direct peer-to-peer WebRTC DataChannel is established for low-latency transmission.

---

## 4. Mode C: Encrypted Relay Fallback

When symmetric NATs on both endpoints prevent direct P2P hole-punching:
1. Both nodes maintain an authenticated session with the relay server.
2. Messages are framed as opaque ciphertext:
   `[TargetDeviceID (32B)][MessageNonce (12B)][Ciphertext (NB)]`
3. The relay performs zero decryption; it matches `TargetDeviceID` against its active in-memory routing table and forwards the frame immediately.
4. No clipboard data is ever retained on disk or stored permanently on the relay.

---

## 5. Self-Hosted Infrastructure Deployment

Users can run the lightweight ClipSync signaling and relay services on their own VPS or home server without external cloud dependencies:

```bash
# Running the self-hosted signaling server
cd infrastructure/signaling
npm install
node server.js --port 8080

# Running the relay server
cd infrastructure/relay
npm install
node relay.js --port 8081
```
Configure your custom server endpoints in ClipSync Settings -> Advanced Networking.
