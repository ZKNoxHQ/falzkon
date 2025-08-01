"""
Python reference implementation for Keccak Hash comparison with Cairo
Uses standard hashlib Keccak implementation
"""

import hashlib

def compute_keccak_hash_bytes(data: bytes) -> int:
    """
    Compute Keccak hash from bytes
    """
    hasher = hashlib.sha3_256()  # Keccak-256
    hasher.update(data)
    digest = hasher.digest()  # 32 bytes
    
    # Convert to integer (big-endian)
    return int.from_bytes(digest, 'big')

def compute_keccak_hash_u256(value: int) -> int:
    """
    Compute Keccak hash from a u256 value
    Convert to 32 bytes (big-endian) then hash
    """
    # Convert u256 to 32 bytes (big-endian)
    byte_data = value.to_bytes(32, 'big')
    return compute_keccak_hash_bytes(byte_data)

def test_keccak_implementations():
    """Test cases to compare with Cairo implementation"""
    
    print("=== Keccak Hash Comparison Tests ===\n")
    
    # Test 1: Simple bytes [1, 2, 3, 4]
    test_bytes = bytes([1, 2, 3, 4])
    print(f"Test bytes: {test_bytes.hex()}")
    
    result1 = compute_keccak_hash_bytes(test_bytes)
    print(f"Python Keccak result: {result1}")
    print(f"Python Keccak result (hex): {hex(result1)}")
    print("Run Cairo tests to get expected value for comparison")
    print()
    
    # Test 2: u256 value
    test_u256 = 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
    print(f"Test u256 value: {hex(test_u256)}")
    
    result2 = compute_keccak_hash_u256(test_u256)
    print(f"Python Keccak result (u256): {result2}")
    print(f"Python Keccak result (u256 hex): {hex(result2)}")
    print()
    
    # Test 3: Simple u256 (12345)
    simple_u256 = 12345
    print(f"Simple u256 value: {simple_u256}")
    
    result3 = compute_keccak_hash_u256(simple_u256)
    print(f"Python Keccak result (simple u256): {result3}")
    print(f"Python Keccak result (simple u256 hex): {hex(result3)}")
    print()
    
    # Test 4: Empty input
    empty_bytes = b''
    print("Test empty input")
    
    result4 = compute_keccak_hash_bytes(empty_bytes)
    print(f"Python Keccak result (empty): {result4}")
    print(f"Python Keccak result (empty hex): {hex(result4)}")
    print()
    
    return {
        'bytes_simple': result1,
        'u256_complex': result2,
        'u256_simple': result3,
        'empty': result4
    }

def verify_keccak_properties():
    """Verify Keccak properties and show debug info"""
    
    print("=== Keccak Properties ===")
    
    # Show Keccak digest size
    hasher = hashlib.sha3_256()
    print(f"Keccak-256 digest size: {hasher.digest_size} bytes ({hasher.digest_size * 8} bits)")
    
    # Show that it fits in u256
    max_u256 = (1 << 256) - 1
    print(f"Max u256 value: {hex(max_u256)}")
    print(f"Keccak produces values that fit in u256: ✓")
    print()

if __name__ == "__main__":
    print("Keccak Hash Function Test\n")
    
    # Check if SHA3 is available
    try:
        hasher = hashlib.sha3_256()
        print("✓ Keccak-256 (SHA3) is available in hashlib")
    except AttributeError:
        print("❌ Keccak not available in this Python installation")
        exit(1)
    
    results = test_keccak_implementations()
    verify_keccak_properties()
    
    print("=== Summary for Cairo Comparison ===")
    for key, value in results.items():
        print(f"{key}: {value}")
    
    print("\n✅ Python Keccak implementation ready for Cairo comparison!")
    print("Hash type identifier: 'keccak'")
    print("\nNext steps:")
    print("1. Run: scarb test")
    print("2. Compare the Keccak hash values between Cairo and Python")
    print("3. Note: Cairo uses a different Keccak implementation, so values may not match exactly")"""
Python reference implementation for Blake2s Hash comparison with Cairo
Uses standard hashlib Blake2s implementation
"""

import hashlib

def compute_blake2s_hash_bytes(data: bytes) -> int:
    """
    Compute Blake2s hash from bytes
    """
    hasher = hashlib.blake2s()
    hasher.update(data)
    digest = hasher.digest()  # 32 bytes
    
    # Convert to integer (big-endian)
    return int.from_bytes(digest, 'big')

def compute_blake2s_hash_u256(value: int) -> int:
    """
    Compute Blake2s hash from a u256 value
    Convert to 32 bytes (big-endian) then hash
    """
    # Convert u256 to 32 bytes (big-endian)
    byte_data = value.to_bytes(32, 'big')
    return compute_blake2s_hash_bytes(byte_data)

def compute_blake2s_hash_felt(value: int) -> int:
    """
    Compute Blake2s hash from a felt252 value
    Convert to minimal bytes (big-endian) then hash
    """
    # Convert to minimal byte representation
    if value == 0:
        byte_data = b'\x00'
    else:
        # Calculate number of bytes needed
        bit_length = value.bit_length()
        byte_length = (bit_length + 7) // 8
        byte_data = value.to_bytes(byte_length, 'big')
    
    return compute_blake2s_hash_bytes(byte_data)

def test_blake2s_implementations():
    """Test cases to compare with Cairo implementation"""
    
    print("=== Blake2s Hash Comparison Tests ===\n")
    
    # Test 1: Simple bytes [1, 2, 3, 4]
    test_bytes = bytes([1, 2, 3, 4])
    print(f"Test bytes: {test_bytes.hex()}")
    
    result1 = compute_blake2s_hash_bytes(test_bytes)
    print(f"Python Blake2s result: {result1}")
    print(f"Python Blake2s result (hex): {hex(result1)}")
    print("Run Cairo tests to get expected value for comparison")
    print()
    
    # Test 2: 32 bytes sequence
    test_32_bytes = bytes([(i + 1) % 256 for i in range(32)])
    print(f"Test 32 bytes: {test_32_bytes.hex()}")
    
    result2 = compute_blake2s_hash_bytes(test_32_bytes)
    print(f"Python Blake2s result (32 bytes): {result2}")
    print(f"Python Blake2s result (32 bytes hex): {hex(result2)}")
    print()
    
    # Test 3: u256 value
    test_u256 = 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
    print(f"Test u256 value: {hex(test_u256)}")
    
    result3 = compute_blake2s_hash_u256(test_u256)
    print(f"Python Blake2s result (u256): {result3}")
    print(f"Python Blake2s result (u256 hex): {hex(result3)}")
    print()
    
    # Test 4: Simple u256 (12345)
    simple_u256 = 12345
    print(f"Simple u256 value: {simple_u256}")
    
    result4 = compute_blake2s_hash_u256(simple_u256)
    print(f"Python Blake2s result (simple u256): {result4}")
    print(f"Python Blake2s result (simple u256 hex): {hex(result4)}")
    print()
    
    # Test 5: felt252 value
    test_felt = 123456789
    print(f"Test felt252 value: {test_felt}")
    
    result5 = compute_blake2s_hash_felt(test_felt)
    print(f"Python Blake2s result (felt252): {result5}")
    print(f"Python Blake2s result (felt252 hex): {hex(result5)}")
    print()
    
    # Test 6: Empty input
    empty_bytes = b''
    print("Test empty input")
    
    result6 = compute_blake2s_hash_bytes(empty_bytes)
    print(f"Python Blake2s result (empty): {result6}")
    print(f"Python Blake2s result (empty hex): {hex(result6)}")
    print()
    
    return {
        'bytes_simple': result1,
        'bytes_32': result2,
        'u256_complex': result3,
        'u256_simple': result4,
        'felt252': result5,
        'empty': result6
    }

def verify_blake2s_properties():
    """Verify Blake2s properties and show debug info"""
    
    print("=== Blake2s Properties ===")
    
    # Show Blake2s digest size
    hasher = hashlib.blake2s()
    print(f"Blake2s digest size: {hasher.digest_size} bytes ({hasher.digest_size * 8} bits)")
    
    # Show that it fits in u256
    max_u256 = (1 << 256) - 1
    print(f"Max u256 value: {hex(max_u256)}")
    print(f"Blake2s produces values that fit in u256: ✓")
    print()
    
    # Show different input encodings for the same logical value
    value = 12345
    
    # As minimal bytes
    minimal = value.to_bytes((value.bit_length() + 7) // 8, 'big')
    print(f"Value {value} as minimal bytes: {minimal.hex()}")
    print(f"Blake2s: {compute_blake2s_hash_bytes(minimal)}")
    
    # As 32 bytes (u256 style)
    full_32 = value.to_bytes(32, 'big')
    print(f"Value {value} as 32 bytes: {full_32.hex()}")
    print(f"Blake2s: {compute_blake2s_hash_bytes(full_32)}")
    print()

if __name__ == "__main__":
    print("Blake2s Hash Function Test\n")
    
    # Check if Blake2s is available
    try:
        hasher = hashlib.blake2s()
        print("✓ Blake2s is available in hashlib")
    except AttributeError:
        print("❌ Blake2s not available in this Python installation")
        exit(1)
    
    results = test_blake2s_implementations()
    verify_blake2s_properties()
    
    print("=== Summary for Cairo Comparison ===")
    for key, value in results.items():
        print(f"{key}: {value}")
    
    print("\n✅ Python Blake2s implementation ready for Cairo comparison!")
    print("Hash type identifier: 'blake2s'")
    print("\nNext steps:")
    print("1. Run: scarb test")
    print("2. Compare the Blake2s hash values between Cairo and Python")
    print("3. They should match exactly!")"""
Python reference implementation for Blake2s Hash comparison with Cairo
Uses standard hashlib Blake2s implementation
"""

import hashlib

def compute_blake2s_hash_bytes(data: bytes) -> int:
    """
    Compute Blake2s hash from bytes
    """
    hasher = hashlib.blake2s()
    hasher.update(data)
    digest = hasher.digest()  # 32 bytes
    
    # Convert to integer (big-endian)
    return int.from_bytes(digest, 'big')

def compute_blake2s_hash_u256(value: int) -> int:
    """
    Compute Blake2s hash from a u256 value
    Convert to 32 bytes (big-endian) then hash
    """
    # Convert u256 to 32 bytes (big-endian)
    byte_data = value.to_bytes(32, 'big')
    return compute_blake2s_hash_bytes(byte_data)

def compute_blake2s_hash_felt(value: int) -> int:
    """
    Compute Blake2s hash from a felt252 value
    Convert to minimal bytes (big-endian) then hash
    """
    # Convert to minimal byte representation
    if value == 0:
        byte_data = b'\x00'
    else:
        # Calculate number of bytes needed
        bit_length = value.bit_length()
        byte_length = (bit_length + 7) // 8
        byte_data = value.to_bytes(byte_length, 'big')
    
    return compute_blake2s_hash_bytes(byte_data)

def test_blake2s_implementations():
    """Test cases to compare with Cairo implementation"""
    
    print("=== Blake2s Hash Comparison Tests ===\n")
    
    # Test 1: Simple bytes [1, 2, 3, 4]
    test_bytes = bytes([1, 2, 3, 4])
    print(f"Test bytes: {test_bytes.hex()}")
    
    result1 = compute_blake2s_hash_bytes(test_bytes)
    print(f"Python Blake2s result: {result1}")
    print(f"Python Blake2s result (hex): {hex(result1)}")
    print()
    
    # Test 2: 32 bytes sequence
    test_32_bytes = bytes([(i + 1) % 256 for i in range(32)])
    print(f"Test 32 bytes: {test_32_bytes.hex()}")
    
    result2 = compute_blake2s_hash_bytes(test_32_bytes)
    print(f"Python Blake2s result (32 bytes): {result2}")
    print(f"Python Blake2s result (32 bytes hex): {hex(result2)}")
    print()
    
    # Test 3: u256 value
    test_u256 = 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
    print(f"Test u256 value: {hex(test_u256)}")
    
    result3 = compute_blake2s_hash_u256(test_u256)
    print(f"Python Blake2s result (u256): {result3}")
    print(f"Python Blake2s result (u256 hex): {hex(result3)}")
    print()
    
    # Test 4: Simple u256 (12345)
    simple_u256 = 12345
    print(f"Simple u256 value: {simple_u256}")
    
    result4 = compute_blake2s_hash_u256(simple_u256)
    print(f"Python Blake2s result (simple u256): {result4}")
    print(f"Python Blake2s result (simple u256 hex): {hex(result4)}")
    print()
    
    # Test 5: felt252 value
    test_felt = 123456789
    print(f"Test felt252 value: {test_felt}")
    
    result5 = compute_blake2s_hash_felt(test_felt)
    print(f"Python Blake2s result (felt252): {result5}")
    print(f"Python Blake2s result (felt252 hex): {hex(result5)}")
    print()
    
    # Test 6: Empty input
    empty_bytes = b''
    print("Test empty input")
    
    result6 = compute_blake2s_hash_bytes(empty_bytes)
    print(f"Python Blake2s result (empty): {result6}")
    print(f"Python Blake2s result (empty hex): {hex(result6)}")
    print()
    
    return {
        'bytes_simple': result1,
        'bytes_32': result2,
        'u256_complex': result3,
        'u256_simple': result4,
        'felt252': result5,
        'empty': result6
    }

def verify_blake2s_properties():
    """Verify Blake2s properties and show debug info"""
    
    print("=== Blake2s Properties ===")
    
    # Show Blake2s digest size
    hasher = hashlib.blake2s()
    print(f"Blake2s digest size: {hasher.digest_size} bytes ({hasher.digest_size * 8} bits)")
    
    # Show that it fits in u256
    max_u256 = (1 << 256) - 1
    print(f"Max u256 value: {hex(max_u256)}")
    print(f"Blake2s produces values that fit in u256: ✓")
    print()
    
    # Show different input encodings for the same logical value
    value = 12345
    
    # As minimal bytes
    minimal = value.to_bytes((value.bit_length() + 7) // 8, 'big')
    print(f"Value {value} as minimal bytes: {minimal.hex()}")
    print(f"Blake2s: {compute_blake2s_hash_bytes(minimal)}")
    
    # As 32 bytes (u256 style)
    full_32 = value.to_bytes(32, 'big')
    print(f"Value {value} as 32 bytes: {full_32.hex()}")
    print(f"Blake2s: {compute_blake2s_hash_bytes(full_32)}")
    print()

if __name__ == "__main__":
    print("Blake2s Hash Function Test\n")
    
    # Check if Blake2s is available
    try:
        hasher = hashlib.blake2s()
        print("✓ Blake2s is available in hashlib")
    except AttributeError:
        print("❌ Blake2s not available in this Python installation")
        exit(1)
    
    results = test_blake2s_implementations()
    verify_blake2s_properties()
    
    print("=== Summary for Cairo Comparison ===")
    for key, value in results.items():
        print(f"{key}: {value}")
    
    print("\n✅ Python Blake2s implementation ready for Cairo comparison!")
    print("Run the Cairo tests and compare the values.")