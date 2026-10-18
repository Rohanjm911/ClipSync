/**
 * ClipSync WebSocket Signaling Server
 * Coordinates WebRTC SDP offer/answer and ICE candidate exchanges between paired devices.
 */

const { WebSocketServer, WebSocket } = require('ws');
const http = require('http');

class SignalingServer {
  constructor(port = 8080) {
    this.port = port;
    this.server = null;
    this.wss = null;
    this.clients = new Map(); // deviceId -> { ws, connectedAt, lastSeen }
  }

  start() {
    return new Promise((resolve, reject) => {
      this.server = http.createServer((req, res) => {
        if (req.url === '/health') {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ status: 'ok', activeDevices: this.clients.size }));
        } else {
          res.writeHead(404);
          res.end();
        }
      });

      this.wss = new WebSocketServer({ server: this.server });

      this.wss.on('connection', (ws, req) => {
        let authenticatedDeviceId = null;

        ws.on('message', (messageRaw) => {
          try {
            const msg = JSON.parse(messageRaw.toString());
            const { type, senderId, targetId, payload } = msg;

            switch (type) {
              case 'REGISTER': {
                if (!senderId || typeof senderId !== 'string') {
                  ws.send(JSON.stringify({ type: 'ERROR', message: 'Invalid senderId' }));
                  return;
                }
                authenticatedDeviceId = senderId;
                this.clients.set(senderId, { ws, connectedAt: Date.now(), lastSeen: Date.now() });
                ws.send(JSON.stringify({ type: 'REGISTER_OK', deviceId: senderId }));
                break;
              }

              case 'SIGNAL_OFFER':
              case 'SIGNAL_ANSWER':
              case 'SIGNAL_ICE': {
                if (!authenticatedDeviceId) {
                  ws.send(JSON.stringify({ type: 'ERROR', message: 'Not registered' }));
                  return;
                }
                if (!targetId || !this.clients.has(targetId)) {
                  ws.send(JSON.stringify({ type: 'PEER_OFFLINE', targetId }));
                  return;
                }
                const target = this.clients.get(targetId);
                if (target.ws.readyState === WebSocket.OPEN) {
                  target.ws.send(JSON.stringify({
                    type,
                    senderId: authenticatedDeviceId,
                    payload,
                  }));
                }
                break;
              }

              case 'PING': {
                if (authenticatedDeviceId && this.clients.has(authenticatedDeviceId)) {
                  this.clients.get(authenticatedDeviceId).lastSeen = Date.now();
                }
                ws.send(JSON.stringify({ type: 'PONG' }));
                break;
              }

              default:
                ws.send(JSON.stringify({ type: 'ERROR', message: `Unknown signal type: ${type}` }));
            }
          } catch (err) {
            ws.send(JSON.stringify({ type: 'ERROR', message: 'Malformed JSON payload' }));
          }
        });

        ws.on('close', () => {
          if (authenticatedDeviceId && this.clients.has(authenticatedDeviceId)) {
            const client = this.clients.get(authenticatedDeviceId);
            if (client.ws === ws) {
              this.clients.delete(authenticatedDeviceId);
            }
          }
        });

        ws.on('error', () => {
          if (authenticatedDeviceId && this.clients.has(authenticatedDeviceId)) {
            this.clients.delete(authenticatedDeviceId);
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
        for (const [_, client] of this.clients) {
          try { client.ws.close(); } catch (_) {}
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
  const port = process.env.PORT || 8080;
  const server = new SignalingServer(port);
  server.start().then(() => {
    console.log(`[ClipSync Signaling] Listening on port ${port}`);
  }).catch((err) => {
    console.error(`[ClipSync Signaling] Startup error:`, err);
    process.exit(1);
  });
}

module.exports = { SignalingServer };
