const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { WebSocket } = require('ws');
const { SignalingServer } = require('../server.js');

describe('ClipSync Signaling Server Integration Tests', () => {
  const TEST_PORT = 9180;
  let server;

  before(async () => {
    server = new SignalingServer(TEST_PORT);
    await server.start();
  });

  after(async () => {
    if (server) {
      await server.stop();
    }
  });

  it('should serve /health endpoint correctly', async () => {
    const res = await new Promise((resolve) => {
      http.get(`http://127.0.0.1:${TEST_PORT}/health`, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => resolve(JSON.parse(data)));
      });
    });
    assert.equal(res.status, 'ok');
    assert.equal(typeof res.activeDevices, 'number');
  });

  it('should register clients and forward WebRTC signals', async () => {
    const ws1 = new WebSocket(`ws://127.0.0.1:${TEST_PORT}`);
    const ws2 = new WebSocket(`ws://127.0.0.1:${TEST_PORT}`);

    await Promise.all([
      new Promise(r => ws1.on('open', r)),
      new Promise(r => ws2.on('open', r)),
    ]);

    // Register dev1
    const reg1Promise = new Promise(resolve => {
      ws1.once('message', raw => resolve(JSON.parse(raw.toString())));
    });
    ws1.send(JSON.stringify({ type: 'REGISTER', senderId: 'dev_windows_001' }));
    const reg1 = await reg1Promise;
    assert.equal(reg1.type, 'REGISTER_OK');
    assert.equal(reg1.deviceId, 'dev_windows_001');

    // Register dev2
    const reg2Promise = new Promise(resolve => {
      ws2.once('message', raw => resolve(JSON.parse(raw.toString())));
    });
    ws2.send(JSON.stringify({ type: 'REGISTER', senderId: 'dev_android_002' }));
    const reg2 = await reg2Promise;
    assert.equal(reg2.type, 'REGISTER_OK');
    assert.equal(reg2.deviceId, 'dev_android_002');

    // Send SIGNAL_OFFER from dev1 to dev2
    const offerPromise = new Promise(resolve => {
      ws2.once('message', raw => resolve(JSON.parse(raw.toString())));
    });
    ws1.send(JSON.stringify({
      type: 'SIGNAL_OFFER',
      senderId: 'dev_windows_001',
      targetId: 'dev_android_002',
      payload: { sdp: 'v=0...' },
    }));

    const receivedOffer = await offerPromise;
    assert.equal(receivedOffer.type, 'SIGNAL_OFFER');
    assert.equal(receivedOffer.senderId, 'dev_windows_001');
    assert.equal(receivedOffer.payload.sdp, 'v=0...');

    // Attempt to signal non-existent peer
    const offlinePromise = new Promise(resolve => {
      ws1.once('message', raw => resolve(JSON.parse(raw.toString())));
    });
    ws1.send(JSON.stringify({
      type: 'SIGNAL_OFFER',
      senderId: 'dev_windows_001',
      targetId: 'dev_non_existent',
      payload: { sdp: 'v=0...' },
    }));

    const offlineRes = await offlinePromise;
    assert.equal(offlineRes.type, 'PEER_OFFLINE');
    assert.equal(offlineRes.targetId, 'dev_non_existent');

    ws1.close();
    ws2.close();
  });
});
