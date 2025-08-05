
import hashlib


def print_rfc_hash_to_words(hex_str):
    # Conversion to words for Cairo format
    b = bytes.fromhex(hex_str)
    words = []
    for i in range(0, len(b), 4):
        # Extract 4 bytes chunk
        chunk = b[i:i+4]
        # Interpret as little-endian uint32
        word = int.from_bytes(chunk, 'little')
        words.append(word)
    print("// RFC Appendix B Blake2s Hash of `abc`:")
    print("// 508C5E8C327C14E2E1A72BA34EEB452F37458B209ED63A294D999B4C86675982")
    print("// Conversion (in python) into words:")
    print("[")
    for word in words:
        print('\t{},'.format(hex(word)))
    print("],")


def test_rfc7693_abc():
    hash_abc_expected = "508C5E8C327C14E2E1A72BA34EEB452F37458B209ED63A294D999B4C86675982".lower()
    hash_abc_computed = hashlib.blake2s(b'abc').digest().hex()
    assert hash_abc_computed == hash_abc_expected
    print("Hash of `abc` computed: ", hash_abc_computed)
    print("Hash of `abc` expected: ", hash_abc_expected)
    print_rfc_hash_to_words(hash_abc_computed)
    return True


if __name__ == "__main__":
    assert test_rfc7693_abc()
