/**
 * ClipSync Encrypted Relay Server (Zero-Knowledge Forwarder)
 * Forwards end-to-end encrypted envelopes between authenticated paired clients
 * when direct LAN and WebRTC P2P direct paths are unreachable.
 */

const { WebSocketServer, WebSocket } = require('ws');
const http = require('http');

class RelayServer {
  constructor(port = 8081) {
    this.port = port;
    this.server = null;
    this.wss = null;
    this.sessions = new Map(); // deviceId -> { ws, connectedAt, bytesForwarded }
  }

  start() {
    return new Promise((resolve, reject) => {
      this.server = http.createServer((req, res) => {
        if (req.url === '/health') {
          let totalBytes = 0;
          for (const s of this.sessions.values()) {
            totalBytes += s.bytesForwarded;
          }
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({
            status: 'ok',
            activeSessions: this.sessions.size,
            totalBytesForwarded: totalBytes,
          }));
        } else {
          res.writeHead(404);
          res.end();
        }
      });

      this.wss = new WebSocketServer({
        server: this.server,
        maxPayload: 30 * 1024 * 1024, // 30MB max frame for chunked files or large images
      });

      this.wss.on('connection', (ws) => {
        let authenticatedDeviceId = null;

        ws.on('message', (messageRaw, isBinary) => {
          try {
            // Relay operates on JSON envelope or binary frame
            if (isBinary) {
              // Binary format: [RecipientID 32B][Payload NB]
              if (messageRaw.length < 32) return;
              const targetIdHex = messageRaw.subarray(0, 32).toString('hex');
              const target = this.sessions.get(targetIdHex);
              if (target && target.ws.readyState === WebSocket.OPEN) {
                target.ws.send(messageRaw, { binary: true });
                if (authenticatedDeviceId && this.sessions.has(authenticatedDeviceId)) {
                  this.sessions.get(authenticatedDeviceId).bytesForwarded += messageRaw.length;
                }
              }
              return;
            }

            // JSON Envelope forwarding
            const msg = JSON.parse(messageRaw.toString());
            const { type, senderId, targetId, encryptedPayload } = msg;

            if (type === 'ATTACH_SESSION') {
              if (!senderId || typeof senderId !== 'string') {
                ws.send(JSON.stringify({ type: 'ERROR', message: 'Invalid senderId' }));
                return;
              }
              authenticatedDeviceId = senderId;
              this.sessions.set(senderId, { ws, connectedAt: Date.now(), bytesForwarded: 0 });
              ws.send(JSON.stringify({ type: 'ATTACH_OK', deviceId: senderId }));
              return;
            }

            if (type === 'FORWARD_ENVELOPE') {
              if (!authenticatedDeviceId) {
                ws.send(JSON.stringify({ type: 'ERROR', message: 'Session not attached' }));
                return;
              }
              if (!targetId || !this.sessions.has(targetId)) {
                ws.send(JSON.stringify({ type: 'RELAY_DROPPED', reason: 'TARGET_OFFLINE', targetId }));
                return;
              }
              const target = this.sessions.get(targetId);
              if (target.ws.readyState === WebSocket.OPEN) {
                const payloadStr = JSON.stringify({
                  type: 'RELAY_ENVELOPE',
                  senderId: authenticatedDeviceId,
                  encryptedPayload,
                });
                target.ws.send(payloadStr);
                this.sessions.get(authenticatedDeviceId).bytesForwarded += payloadStr.length;
                ws.send(JSON.stringify({ type: 'RELAY_ACK', targetId }));
              }
              return;
            }

            if (type === 'PING') {
              ws.send(JSON.stringify({ type: 'PONG' }));
              return;
            }

            ws.send(JSON.stringify({ type: 'ERROR', message: `Unknown relay command: ${type}` }));
          } catch (err) {
            ws.send(JSON.stringify({ type: 'ERROR', message: 'Malformed relay message' }));
          }
        });

        ws.on('close', () => {
          if (authenticatedDeviceId && this.sessions.has(authenticatedDeviceId)) {
            const sess = this.sessions.get(authenticatedDeviceId);
            if (sess.ws === ws) {
              this.sessions.delete(authenticatedDeviceId);
            }
          }
        });

        ws.on('error', () => {
          if (authenticatedDeviceId && this.sessions.has(authenticatedDeviceId)) {
            this.sessions.delete(authenticatedDeviceId);
          }
        });
      });

      this.server.listen(this.port, () => {
        resolve(this.port);
      });

      this.server.on('error', (err) => reject(err));
    });
  }

  stop() {
    return new Promise((resolve) => {
      if (this.wss) {
        for (const [_, sess] of this.sessions) {
          try { sess.ws.close(); } catch (_) {}
        }
        this.wss.close();
      }
      if (this.server) {
        this.server.close(() => resolve());
      } else {
        resolve();
      }
    });
  }
}

if (require.main === module) {
  const port = process.env.PORT || 8081;
  const server = new RelayServer(port);
  server.start().then(() => {
    console.log(`[ClipSync Relay] Listening on port ${port}`);
  }).catch((err) => {
    console.error(`[ClipSync Relay] Startup error:`, err);
    process.exit(1);
  });
}

module.exports = { RelayServer };
