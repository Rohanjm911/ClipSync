const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { WebSocket } = require('ws');
const { RelayServer } = require('../relay.js');

describe('ClipSync Relay Server Integration Tests', () => {
  const TEST_PORT = 9181;
  let server;

  before(async () => {
    server = new RelayServer(TEST_PORT);
    await server.start();
  });

  after(async () => {
    if (server) {
      await server.stop();
    }
  });

  it('should serve /health endpoint with stats', async () => {
    const res = await new Promise((resolve) => {
      http.get(`http://127.0.0.1:${TEST_PORT}/health`, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => resolve(JSON.parse(data)));
      });
    });
    assert.equal(res.status, 'ok');
    assert.equal(typeof res.activeSessions, 'number');
    assert.equal(typeof res.totalBytesForwarded, 'number');
  });

  it('should attach sessions and forward encrypted envelopes end-to-end', async () => {
    const wsSender = new WebSocket(`ws://127.0.0.1:${TEST_PORT}`);
    const wsReceiver = new WebSocket(`ws://127.0.0.1:${TEST_PORT}`);

    await Promise.all([
      new Promise(r => wsSender.on('open', r)),
      new Promise(r => wsReceiver.on('open', r)),
    ]);

    // Attach sender
    const senderAttachPromise = new Promise(resolve => {
      wsSender.once('message', raw => resolve(JSON.parse(raw.toString())));
    });
    wsSender.send(JSON.stringify({ type: 'ATTACH_SESSION', senderId: 'dev_sender_101' }));
    const senderAttach = await senderAttachPromise;
    assert.equal(senderAttach.type, 'ATTACH_OK');

    // Attach receiver
    const receiverAttachPromise = new Promise(resolve => {
      wsReceiver.once('message', raw => resolve(JSON.parse(raw.toString())));
    });
    wsReceiver.send(JSON.stringify({ type: 'ATTACH_SESSION', senderId: 'dev_receiver_202' }));
    const receiverAttach = await receiverAttachPromise;
    assert.equal(receiverAttach.type, 'ATTACH_OK');

    // Sender forwards envelope to receiver
    const receivePromise = new Promise(resolve => {
      wsReceiver.once('message', raw => resolve(JSON.parse(raw.toString())));
    });
    const ackPromise = new Promise(resolve => {
      wsSender.once('message', raw => resolve(JSON.parse(raw.toString())));
    });

    const mockEncryptedData = {
      nonce: 'f41249e018a1',
      ciphertext: '5a89f92bd03213ff...',
      tag: '09ab...',
    };

    wsSender.send(JSON.stringify({
      type: 'FORWARD_ENVELOPE',
      targetId: 'dev_receiver_202',
      encryptedPayload: mockEncryptedData,
    }));

    const [receivedMsg, ackMsg] = await Promise.all([receivePromise, ackPromise]);

    assert.equal(receivedMsg.type, 'RELAY_ENVELOPE');
    assert.equal(receivedMsg.senderId, 'dev_sender_101');
    assert.deepEqual(receivedMsg.encryptedPayload, mockEncryptedData);
    assert.equal(ackMsg.type, 'RELAY_ACK');
    assert.equal(ackMsg.targetId, 'dev_receiver_202');

    wsSender.close();
    wsReceiver.close();
  });
});
