'use strict';
/*
 * PrivateBin v2 paste decryption.
 *
 * A PrivateBin URL carries its key in the fragment (`#<base58>`), which the
 * server never sees. The server returns JSON; the plaintext is recovered with:
 *   key    = PBKDF2-SHA256(base58decode(fragment), salt, iterations, keysize)
 *   cipher = AES-GCM, with JSON.stringify(adata) as the additional data
 * then optionally zlib-inflated. All parameters live in adata[0].
 */

const crypto = require('crypto');
const zlib = require('zlib');

const B58_ALPHABET = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

function base58Decode(str) {
  let num = 0n;
  for (const ch of str) {
    const idx = B58_ALPHABET.indexOf(ch);
    if (idx === -1) throw new Error('invalid base58 character: ' + ch);
    num = num * 58n + BigInt(idx);
  }
  let hex = num.toString(16);
  if (hex.length % 2) hex = '0' + hex;
  const bytes = Buffer.from(hex, 'hex');
  let leadingZeros = 0;
  for (const ch of str) { if (ch === '1') leadingZeros++; else break; }
  return Buffer.concat([Buffer.alloc(leadingZeros), bytes]);
}

/** True when a parsed JSON body looks like a PrivateBin paste envelope. */
function isPaste(obj) {
  return !!(obj && obj.ct && Array.isArray(obj.adata) && (obj.v === 1 || obj.v === 2));
}

function decrypt(paste, keyFragment) {
  if (paste.v !== 2) {
    throw new Error('unsupported PrivateBin version ' + paste.v + ' (only v2 is supported)');
  }
  const adata = paste.adata;
  const [iv64, salt64, iterations, keysize, tagsize, , mode, compression] = adata[0];
  const iv = Buffer.from(iv64, 'base64');
  const salt = Buffer.from(salt64, 'base64');

  let keyBytes = base58Decode(keyFragment);
  if (keyBytes.length < 32) {
    keyBytes = Buffer.concat([Buffer.alloc(32 - keyBytes.length), keyBytes]);
  }

  const aesKey = crypto.pbkdf2Sync(keyBytes, salt, iterations, keysize / 8, 'sha256');
  const aad = Buffer.from(JSON.stringify(adata), 'utf8');
  const tagLen = tagsize / 8;
  const ctFull = Buffer.from(paste.ct, 'base64');

  const decipher = crypto.createDecipheriv('aes-' + keysize + '-' + mode, aesKey, iv);
  decipher.setAuthTag(ctFull.subarray(ctFull.length - tagLen));
  decipher.setAAD(aad);

  let compressed;
  try {
    compressed = Buffer.concat([
      decipher.update(ctFull.subarray(0, ctFull.length - tagLen)),
      decipher.final(),
    ]);
  } catch (err) {
    throw new Error(
      'decryption failed (wrong key, password-protected paste, or corrupt data): ' + err.message
    );
  }

  let plain;
  if (compression === 'none') {
    plain = compressed;
  } else {
    try { plain = zlib.inflateSync(compressed); }
    catch (e) { plain = zlib.inflateRawSync(compressed); }
  }
  return plain.toString('utf8');
}

module.exports = { decrypt, isPaste, base58Decode };
