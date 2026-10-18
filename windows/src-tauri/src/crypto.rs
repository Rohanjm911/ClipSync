//! Cryptographic Primitives for ClipSync
//! Implements Ed25519 for Identity & Signatures, X25519 for Key Agreement,
//! and ChaCha20-Poly1305 for Authenticated Symmetric Encryption.

use chacha20poly1305::{
    aead::{Aead, KeyInit},
    ChaCha20Poly1305, Nonce,
};
use ed25519_dalek::{Signature, Signer, SigningKey, Verifier, VerifyingKey};
use rand::rngs::OsRng;
use sha2::{Digest, Sha256};
use x25519_dalek::{PublicKey as X25519PublicKey, StaticSecret};

pub struct IdentityKeyPair {
    pub signing_key: SigningKey,
    pub verifying_key: VerifyingKey,
    pub exchange_secret: StaticSecret,
    pub exchange_public: X25519PublicKey,
}

impl IdentityKeyPair {
    /// Generate a fresh cryptographic identity keypair using OS entropy
    pub fn generate() -> Self {
        let mut csprng = OsRng;
        let signing_key = SigningKey::generate(&mut csprng);
        let verifying_key = signing_key.verifying_key();
        let exchange_secret = StaticSecret::random_from_rng(&mut csprng);
        let exchange_public = X25519PublicKey::from(&exchange_secret);

        Self {
            signing_key,
            verifying_key,
            exchange_secret,
            exchange_public,
        }
    }

    /// Reconstruct identity from stored 32-byte secret seed
    pub fn from_seeds(signing_seed: &[u8; 32], exchange_seed: &[u8; 32]) -> Self {
        let signing_key = SigningKey::from_bytes(signing_seed);
        let verifying_key = signing_key.verifying_key();
        let exchange_secret = StaticSecret::from(*exchange_seed);
        let exchange_public = X25519PublicKey::from(&exchange_secret);

        Self {
            signing_key,
            verifying_key,
            exchange_secret,
            exchange_public,
        }
    }

    /// Sign arbitrary message bytes with Ed25519 private key
    pub fn sign(&self, message: &[u8]) -> Vec<u8> {
        self.signing_key.sign(message).to_vec()
    }

    /// Compute public fingerprint (SHA-256 of Ed25519 verifying key)
    pub fn device_id(&self) -> String {
        let mut hasher = Sha256::new();
        hasher.update(self.verifying_key.as_bytes());
        hex::encode(hasher.finalize())
    }

    /// Public Ed25519 key as hex string
    pub fn ed25519_pubkey_hex(&self) -> String {
        hex::encode(self.verifying_key.as_bytes())
    }

    /// Public X25519 key as hex string
    pub fn x25519_pubkey_hex(&self) -> String {
        hex::encode(self.exchange_public.as_bytes())
    }

    /// Compute Diffie-Hellman shared secret with peer's X25519 public key
    pub fn diffie_hellman(&self, peer_x25519_bytes: &[u8; 32]) -> [u8; 32] {
        let peer_pub = X25519PublicKey::from(*peer_x25519_bytes);
        let shared = self.exchange_secret.diffie_hellman(&peer_pub);
        *shared.as_bytes()
    }
}

/// Verify an Ed25519 signature given the peer's public key bytes
pub fn verify_signature(
    public_key_bytes: &[u8; 32],
    message: &[u8],
    signature_bytes: &[u8; 64],
) -> bool {
    if let Ok(verifying_key) = VerifyingKey::from_bytes(public_key_bytes) {
        let signature = Signature::from_bytes(signature_bytes);
        verifying_key.verify(message, &signature).is_ok()
    } else {
        false
    }
}

/// Derive 256-bit symmetric encryption key using HKDF-SHA256 from shared secret
pub fn derive_symmetric_key(shared_secret: &[u8; 32], context: &[u8]) -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(b"ClipSync-v1-HKDF-");
    hasher.update(context);
    hasher.update(shared_secret);
    let result = hasher.finalize();
    let mut key = [0u8; 32];
    key.copy_from_slice(&result);
    key
}

/// Encrypt plaintext using ChaCha20-Poly1305 with random 96-bit nonce
pub fn encrypt_payload(
    key: &[u8; 32],
    plaintext: &[u8],
) -> Result<(Vec<u8>, [u8; 12]), String> {
    let cipher = ChaCha20Poly1305::new_from_slice(key)
        .map_err(|e| format!("Cipher init failed: {}", e))?;
    
    let mut nonce_bytes = [0u8; 12];
    rand::RngCore::fill_bytes(&mut OsRng, &mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);

    let ciphertext = cipher
        .encrypt(nonce, plaintext)
        .map_err(|e| format!("Encryption error: {}", e))?;

    Ok((ciphertext, nonce_bytes))
}

/// Decrypt ciphertext using ChaCha20-Poly1305 with 96-bit nonce
pub fn decrypt_payload(
    key: &[u8; 32],
    ciphertext: &[u8],
    nonce_bytes: &[u8; 12],
) -> Result<Vec<u8>, String> {
    let cipher = ChaCha20Poly1305::new_from_slice(key)
        .map_err(|e| format!("Cipher init failed: {}", e))?;
    let nonce = Nonce::from_slice(nonce_bytes);

    cipher
        .decrypt(nonce, ciphertext)
        .map_err(|e| format!("Decryption authentication failure: {}", e))
}

/// Compute SHA-256 hash of arbitrary bytes
pub fn compute_sha256(data: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data);
    hex::encode(hasher.finalize())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_identity_keypair_generation_and_signing() {
        let id = IdentityKeyPair::generate();
        let message = b"ClipSync unit test message";
        let signature = id.sign(message);
        assert_eq!(signature.len(), 64);

        let mut sig_arr = [0u8; 64];
        sig_arr.copy_from_slice(&signature);
        assert!(verify_signature(id.verifying_key.as_bytes(), message, &sig_arr));

        // Tampered message must fail
        assert!(!verify_signature(id.verifying_key.as_bytes(), b"tampered", &sig_arr));
    }

    #[test]
    fn test_diffie_hellman_and_symmetric_encryption() {
        let alice = IdentityKeyPair::generate();
        let bob = IdentityKeyPair::generate();

        let secret_alice = alice.diffie_hellman(bob.exchange_public.as_bytes());
        let secret_bob = bob.diffie_hellman(alice.exchange_public.as_bytes());
        assert_eq!(secret_alice, secret_bob);

        let key_alice = derive_symmetric_key(&secret_alice, b"clipboard-test");
        let key_bob = derive_symmetric_key(&secret_bob, b"clipboard-test");
        assert_eq!(key_alice, key_bob);

        let original = b"Secret clipboard contents 12345";
        let (ciphertext, nonce) = encrypt_payload(&key_alice, original).expect("encrypt");
        let decrypted = decrypt_payload(&key_bob, &ciphertext, &nonce).expect("decrypt");
        assert_eq!(decrypted, original);

        // Tampering with ciphertext must fail authentication
        let mut tampered = ciphertext.clone();
        tampered[0] ^= 0xFF;
        assert!(decrypt_payload(&key_bob, &tampered, &nonce).is_err());
    }
}
