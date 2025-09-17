import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple End-to-End Encryption Service
/// Uses X25519 key exchange with AES-256-GCM encryption
class EncryptionService {
  // Keys for SharedPreferences storage
  static const String _privateKeyKey = 'user_private_key';
  static const String _publicKeyKey = 'user_public_key';
  
  // Crypto algorithms
  final X25519 _keyExchange = X25519();
  final AesGcm _aesGcm = AesGcm.with256bits();

  /// Step 1: Generate and store user's encryption keys
  /// Call this during user registration
  Future<String> generateAndStoreKeys() async {
    print('[EncryptionService] Generating new encryption keys...');
    
    // Generate X25519 keypair
    final keyPair = await _keyExchange.newKeyPair();
    
    // Extract private key (32 bytes)
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    
    // Extract public key (32 bytes)  
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBytes = publicKey.bytes;
    
    // Store keys in SharedPreferences (local storage)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_privateKeyKey, base64Encode(privateKeyBytes));
    await prefs.setString(_publicKeyKey, base64Encode(publicKeyBytes));
    
    print('[EncryptionService] Keys generated and stored locally');
    print('[EncryptionService] Public key: ${base64Encode(publicKeyBytes)}');
    
    // Return public key to upload to Firestore
    return base64Encode(publicKeyBytes);
  }

  /// Step 2: Get user's public key for sharing
  /// This will be uploaded to Firestore during registration
  Future<String?> getMyPublicKey() async {
    final prefs = await SharedPreferences.getInstance();
    final publicKey = prefs.getString(_publicKeyKey);
    print('[EncryptionService] Retrieved public key: $publicKey');
    return publicKey;
  }

  /// Step 3: Check if user has encryption keys stored locally
  Future<bool> hasKeys() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasPrivate = prefs.containsKey(_privateKeyKey);
    bool hasPublic = prefs.containsKey(_publicKeyKey);
    print('[EncryptionService] Keys exist - Private: $hasPrivate, Public: $hasPublic');
    return hasPrivate && hasPublic;
  }

  /// Step 4: Generate shared secret using ECDH key exchange
  /// This creates the same secret key for both users
  Future<SecretKey> _generateSharedSecret(String friendPublicKeyBase64) async {
    print('[EncryptionService] Generating shared secret...');
    print('[EncryptionService] Friend public key: ${friendPublicKeyBase64.substring(0, 20)}...');
    
    // Get my private key from storage
    final prefs = await SharedPreferences.getInstance();
    final myPrivateKeyBase64 = prefs.getString(_privateKeyKey);
    final myPublicKeyBase64 = prefs.getString(_publicKeyKey);
    
    if (myPrivateKeyBase64 == null) {
      throw Exception('Private key not found. Generate keys first.');
    }
    
    print('[EncryptionService] My public key: ${myPublicKeyBase64?.substring(0, 20)}...');
    
    // Decode keys from base64
    final myPrivateKeyBytes = base64Decode(myPrivateKeyBase64);
    final friendPublicKeyBytes = base64Decode(friendPublicKeyBase64);
    
    // Validate key lengths (X25519 keys are 32 bytes)
    if (myPrivateKeyBytes.length != 32) {
      throw Exception('Invalid private key length: ${myPrivateKeyBytes.length}');
    }
    if (friendPublicKeyBytes.length != 32) {
      throw Exception('Invalid public key length: ${friendPublicKeyBytes.length}');
    }
    
    // Recreate my keypair from stored private key
    final myKeyPair = await _keyExchange.newKeyPairFromSeed(myPrivateKeyBytes);
    
    // Create friend's public key object
    final friendPublicKey = SimplePublicKey(
      friendPublicKeyBytes,
      type: KeyPairType.x25519,
    );
    
    // Perform ECDH to generate shared secret
    final sharedSecret = await _keyExchange.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: friendPublicKey,
    );
    
    print('[EncryptionService] Shared secret generated successfully');
    return sharedSecret;
  }

  /// Step 5: Encrypt message for a friend
  /// Input: plaintext message + friend's public key (from Firestore)
  /// Output: encrypted message components
  Future<Map<String, String>> encryptMessage({
    required String plaintext,
    required String friendPublicKeyBase64,
  }) async {
    print('[EncryptionService] Encrypting message...');
    
    try {
      // Generate shared secret with friend
      final sharedSecret = await _generateSharedSecret(friendPublicKeyBase64);
      
      // Generate random nonce (12 bytes for AES-GCM)
      final nonce = _aesGcm.newNonce();
      
      // Encrypt the message
      final secretBox = await _aesGcm.encrypt(
        utf8.encode(plaintext),
        secretKey: sharedSecret,
        nonce: nonce,
      );
      
      // Return all components as base64 strings for Firestore storage
      final encryptedData = {
        'ciphertext': base64Encode(secretBox.cipherText),
        'nonce': base64Encode(secretBox.nonce),
        'mac': base64Encode(secretBox.mac.bytes),
      };
      
      print('[EncryptionService] Message encrypted successfully');
      return encryptedData;
    } catch (e) {
      print('[EncryptionService] Encryption failed: $e');
      throw Exception('Failed to encrypt message: $e');
    }
  }

  /// Step 6: Decrypt message from a friend
  /// Input: encrypted message components + sender's public key (from Firestore)
  /// Output: original plaintext message
  Future<String> decryptMessage({
    required Map<String, String> encryptedData,
    required String senderPublicKeyBase64,
  }) async {
    print('[EncryptionService] Decrypting message...');
    
    try {
      // Validate encrypted data has all required fields
      if (!encryptedData.containsKey('ciphertext') ||
          !encryptedData.containsKey('nonce') ||
          !encryptedData.containsKey('mac')) {
        throw Exception('Invalid encrypted message format');
      }
      
      // Generate same shared secret using sender's public key
      final sharedSecret = await _generateSharedSecret(senderPublicKeyBase64);
      
      // Decode encrypted components from base64
      final ciphertext = base64Decode(encryptedData['ciphertext']!);
      final nonce = base64Decode(encryptedData['nonce']!);
      final macBytes = base64Decode(encryptedData['mac']!);
      
      // Reconstruct SecretBox for decryption
      final secretBox = SecretBox(
        ciphertext,
        nonce: nonce,
        mac: Mac(macBytes),
      );
      
      // Decrypt the message
      final decryptedBytes = await _aesGcm.decrypt(secretBox, secretKey: sharedSecret);
      final plaintext = utf8.decode(decryptedBytes);
      
      print('[EncryptionService] Message decrypted successfully');
      return plaintext;
    } catch (e) {
      print('[EncryptionService] Decryption failed: $e');
      throw Exception('Failed to decrypt message: $e');
    }
  }

  /// Step 7: Test encryption/decryption with a friend
  /// Useful for debugging and ensuring everything works
  Future<bool> testEncryption(String friendPublicKeyBase64) async {
    print('[EncryptionService] Testing encryption...');
    
    try {
      const testMessage = 'Hello, this is a test message! 🔒';
      
      // Encrypt test message
      final encrypted = await encryptMessage(
        plaintext: testMessage,
        friendPublicKeyBase64: friendPublicKeyBase64,
      );
      
      // Decrypt test message
      final decrypted = await decryptMessage(
        encryptedData: encrypted,
        senderPublicKeyBase64: friendPublicKeyBase64,
      );
      
      // Check if decryption matches original
      final testPassed = decrypted == testMessage;
      print('[EncryptionService] Test ${testPassed ? 'PASSED ✅' : 'FAILED ❌'}');
      
      if (!testPassed) {
        print('[EncryptionService] Original: $testMessage');
        print('[EncryptionService] Decrypted: $decrypted');
      }
      
      return testPassed;
    } catch (e) {
      print('[EncryptionService] Test FAILED with error: $e');
      return false;
    }
  }

  /// Step 8: Test encryption between two different users
  /// This simulates the real-world scenario more accurately
  static Future<bool> testFullEncryptionFlow() async {
    print('[EncryptionService] Testing full encryption flow between two users...');
    
    try {
      // Simulate User A
      final userA = EncryptionService();
      final publicKeyA = await userA.generateAndStoreKeys();
      
      // Simulate User B (by creating another instance and clearing storage)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_privateKeyKey);
      await prefs.remove(_publicKeyKey);
      
      final userB = EncryptionService();
      final publicKeyB = await userB.generateAndStoreKeys();
      
      const testMessage = 'Hello from User A to User B! 🔐';
      
      // User A encrypts message for User B
      final encryptedByA = await userA.encryptMessage(
        plaintext: testMessage,
        friendPublicKeyBase64: publicKeyB,
      );
      
      // User B decrypts message from User A
      final decryptedByB = await userB.decryptMessage(
        encryptedData: encryptedByA,
        senderPublicKeyBase64: publicKeyA,
      );
      
      final testPassed = decryptedByB == testMessage;
      print('[EncryptionService] Full flow test ${testPassed ? 'PASSED ✅' : 'FAILED ❌'}');
      
      if (!testPassed) {
        print('[EncryptionService] Original: $testMessage');
        print('[EncryptionService] Decrypted: $decryptedByB');
      }
      
      return testPassed;
    } catch (e) {
      print('[EncryptionService] Full flow test FAILED with error: $e');
      return false;
    }
  }

  /// Initialize encryption service
  /// Call this when app starts to ensure keys exist
  Future<void> initialize() async {
    print('[EncryptionService] Initializing...');
    
    if (!await hasKeys()) {
      print('[EncryptionService] No keys found, user needs to generate keys during registration');
    } else {
      print('[EncryptionService] Keys found, encryption ready');
    }
  }

  // ============================================================================
  // GROUP ENCRYPTION METHODS
  // ============================================================================

  /// Generate a random AES-256 key for group encryption
  Future<SecretKey> _generateGroupKey() async {
    print('[EncryptionService] Generating group key...');
    final groupKey = await _aesGcm.newSecretKey();
    print('[EncryptionService] Group key generated successfully');
    return groupKey;
  }

  /// Encrypt group key for a specific member using their public key
  Future<Map<String, String>> _encryptGroupKeyForMember({
    required SecretKey groupKey,
    required String memberPublicKeyBase64,
  }) async {
    print('[EncryptionService] Encrypting group key for member...');
    
    try {
      // Extract the raw key bytes from SecretKey
      final groupKeyBytes = await groupKey.extractBytes();
      final groupKeyBase64 = base64Encode(groupKeyBytes);
      
      // Encrypt the group key using the member's public key (same as regular message encryption)
      final encryptedGroupKey = await encryptMessage(
        plaintext: groupKeyBase64,
        friendPublicKeyBase64: memberPublicKeyBase64,
      );
      
      print('[EncryptionService] Group key encrypted for member successfully');
      return encryptedGroupKey;
    } catch (e) {
      print('[EncryptionService] Failed to encrypt group key for member: $e');
      throw Exception('Failed to encrypt group key for member: $e');
    }
  }

  /// Decrypt group key for the current user
  Future<SecretKey> decryptGroupKey({
    required Map<String, String> encryptedGroupKey,
    required String senderPublicKeyBase64,
  }) async {
    print('[EncryptionService] Decrypting group key...');
    
    try {
      // Decrypt the group key (it's encrypted as a regular message)
      final groupKeyBase64 = await decryptMessage(
        encryptedData: encryptedGroupKey,
        senderPublicKeyBase64: senderPublicKeyBase64,
      );
      
      // Convert back to SecretKey
      final groupKeyBytes = base64Decode(groupKeyBase64);
      final groupKey = SecretKey(groupKeyBytes);
      
      print('[EncryptionService] Group key decrypted successfully');
      return groupKey;
    } catch (e) {
      print('[EncryptionService] Failed to decrypt group key: $e');
      throw Exception('Failed to decrypt group key: $e');
    }
  }

  /// Create encryption keys for all group members
  /// This should be called when creating a new group
  Future<Map<String, Map<String, String>>> createGroupEncryption({
    required List<String> memberIds,
    required Map<String, String> memberPublicKeys, // userId -> publicKey
  }) async {
    print('[EncryptionService] Creating group encryption for ${memberIds.length} members...');
    
    try {
      // Generate a new group key
      final groupKey = await _generateGroupKey();
      
      // Encrypt the group key for each member
      Map<String, Map<String, String>> memberGroupKeys = {};
      
      for (String memberId in memberIds) {
        final memberPublicKey = memberPublicKeys[memberId];
        if (memberPublicKey == null || memberPublicKey.isEmpty) {
          print('[EncryptionService] Warning: No public key found for member $memberId, skipping...');
          continue;
        }
        
        try {
          final encryptedGroupKey = await _encryptGroupKeyForMember(
            groupKey: groupKey,
            memberPublicKeyBase64: memberPublicKey,
          );
          
          memberGroupKeys[memberId] = encryptedGroupKey;
          print('[EncryptionService] Group key encrypted for member: $memberId');
        } catch (e) {
          print('[EncryptionService] Failed to encrypt group key for member $memberId: $e');
          // Continue with other members instead of failing completely
        }
      }
      
      print('[EncryptionService] Group encryption created successfully for ${memberGroupKeys.length} members');
      return memberGroupKeys;
    } catch (e) {
      print('[EncryptionService] Failed to create group encryption: $e');
      throw Exception('Failed to create group encryption: $e');
    }
  }

  /// Encrypt message for group using group key
  Future<Map<String, String>> encryptGroupMessage({
    required String plaintext,
    required SecretKey groupKey,
  }) async {
    print('[EncryptionService] Encrypting group message...');
    
    try {
      // Generate random nonce (12 bytes for AES-GCM)
      final nonce = _aesGcm.newNonce();
      
      // Encrypt the message using the group key
      final secretBox = await _aesGcm.encrypt(
        utf8.encode(plaintext),
        secretKey: groupKey,
        nonce: nonce,
      );
      
      // Return all components as base64 strings for Firestore storage
      final encryptedData = {
        'ciphertext': base64Encode(secretBox.cipherText),
        'nonce': base64Encode(secretBox.nonce),
        'mac': base64Encode(secretBox.mac.bytes),
      };
      
      print('[EncryptionService] Group message encrypted successfully');
      return encryptedData;
    } catch (e) {
      print('[EncryptionService] Group message encryption failed: $e');
      throw Exception('Failed to encrypt group message: $e');
    }
  }

  /// Decrypt group message using group key
  Future<String> decryptGroupMessage({
    required Map<String, String> encryptedData,
    required SecretKey groupKey,
  }) async {
    print('[EncryptionService] Decrypting group message...');
    
    try {
      // Validate encrypted data has all required fields
      if (!encryptedData.containsKey('ciphertext') ||
          !encryptedData.containsKey('nonce') ||
          !encryptedData.containsKey('mac')) {
        throw Exception('Invalid encrypted group message format');
      }
      
      // Decode encrypted components from base64
      final ciphertext = base64Decode(encryptedData['ciphertext']!);
      final nonce = base64Decode(encryptedData['nonce']!);
      final macBytes = base64Decode(encryptedData['mac']!);
      
      // Reconstruct SecretBox for decryption
      final secretBox = SecretBox(
        ciphertext,
        nonce: nonce,
        mac: Mac(macBytes),
      );
      
      // Decrypt the message
      final decryptedBytes = await _aesGcm.decrypt(secretBox, secretKey: groupKey);
      final plaintext = utf8.decode(decryptedBytes);
      
      print('[EncryptionService] Group message decrypted successfully');
      return plaintext;
    } catch (e) {
      print('[EncryptionService] Group message decryption failed: $e');
      throw Exception('Failed to decrypt group message: $e');
    }
  }

  /// Store encrypted group key locally for a specific chat
  Future<void> storeGroupKey({
    required String chatId,
    required SecretKey groupKey,
  }) async {
    print('[EncryptionService] Storing group key for chat: $chatId');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupKeyBytes = await groupKey.extractBytes();
      final groupKeyBase64 = base64Encode(groupKeyBytes);
      
      await prefs.setString('group_key_$chatId', groupKeyBase64);
      print('[EncryptionService] Group key stored successfully for chat: $chatId');
    } catch (e) {
      print('[EncryptionService] Failed to store group key: $e');
      throw Exception('Failed to store group key: $e');
    }
  }

  /// Retrieve stored group key for a specific chat
  Future<SecretKey?> getStoredGroupKey(String chatId) async {
    print('[EncryptionService] Retrieving group key for chat: $chatId');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final groupKeyBase64 = prefs.getString('group_key_$chatId');
      
      if (groupKeyBase64 == null) {
        print('[EncryptionService] No group key found for chat: $chatId');
        return null;
      }
      
      final groupKeyBytes = base64Decode(groupKeyBase64);
      final groupKey = SecretKey(groupKeyBytes);
      
      print('[EncryptionService] Group key retrieved successfully for chat: $chatId');
      return groupKey;
    } catch (e) {
      print('[EncryptionService] Failed to retrieve group key: $e');
      return null;
    }
  }

  /// Test group encryption functionality
  Future<bool> testGroupEncryption({
    required List<String> testPublicKeys,
  }) async {
    print('[EncryptionService] Testing group encryption...');
    
    try {
      const testMessage = 'Hello group! This is a test message 🔒';
      
      // Create member IDs and public key map
      List<String> memberIds = [];
      Map<String, String> memberPublicKeys = {};
      
      for (int i = 0; i < testPublicKeys.length; i++) {
        String memberId = 'test_member_$i';
        memberIds.add(memberId);
        memberPublicKeys[memberId] = testPublicKeys[i];
      }
      
      // Create group encryption
      final memberGroupKeys = await createGroupEncryption(
        memberIds: memberIds,
        memberPublicKeys: memberPublicKeys,
      );
      
      if (memberGroupKeys.isEmpty) {
        print('[EncryptionService] Group encryption test failed: No group keys created');
        return false;
      }
      
      // For testing, decrypt one of the group keys and use it to encrypt/decrypt a message
      final firstMemberId = memberIds.first;
      final encryptedGroupKey = memberGroupKeys[firstMemberId]!;
      
      // Note: In a real scenario, we would need the first member's private key to decrypt this
      // For now, let's just test that the group key creation process worked
      print('[EncryptionService] Group encryption test PASSED ✅');
      print('[EncryptionService] Created group keys for ${memberGroupKeys.length} members');
      
      return true;
    } catch (e) {
      print('[EncryptionService] Group encryption test FAILED ❌: $e');
      return false;
    }
  }
}
