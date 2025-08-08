// Blake2s Hash Contract
use core::blake::blake2s_finalize;
use core::box::BoxTrait;

#[starknet::interface]
pub trait IBlake2sHash<TContractState> {
    fn get_hash_type(self: @TContractState) -> felt252;
}

#[starknet::contract]
pub mod Blake2sHash {

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl Blake2sHashImpl of super::IBlake2sHash<ContractState> {
        fn get_hash_type(self: @ContractState) -> felt252 {
            'blake2s'
        }
    }
}

fn bytearray_to_fixed_u32_array(input_bytes: ByteArray) -> Box<[u32; 16]> {
    // convert a ByteArray (of max 64 bytes) into 16 words (u32) in LSB order.
    let byte_len = input_bytes.len();
    let mut values = ArrayTrait::<u32>::new();
    
    let mut i = 0;
    let mut values_created: u32 = 0;
    
    // Convert byte groups into u32 in little-endian order
    while i != byte_len && values_created != 16 {
        let mut value: u32 = 0;
        let mut byte_count: u32 = 0;
        let mut shift: u32 = 1;

        while byte_count != 4 && i != byte_len {
            let byte_val: u32 = input_bytes[i].into();
            value += byte_val * shift;
            i += 1;
            byte_count += 1;
            if byte_count == 4 {
                break;
            }
            shift *= 256;
        };

        // Pad with zeros if fewer than 4 bytes
        while byte_count != 4 {
            byte_count += 1;
            if byte_count == 4{
                break;
            }
            shift *= 256;
        }

        values.append(value);
        values_created += 1;
    };
    
    // Pad with zeros to reach 16 values
    while values_created != 16 {
        values.append(0);
        values_created += 1;
    }

    // Convert to fixed array
    let result = [
        *values.at(0),  *values.at(1),  *values.at(2),  *values.at(3),
        *values.at(4),  *values.at(5),  *values.at(6),  *values.at(7),
        *values.at(8),  *values.at(9),  *values.at(10), *values.at(11),
        *values.at(12), *values.at(13), *values.at(14), *values.at(15)
    ];
    
    BoxTrait::new(result)
}


fn HashToPoint_Blake2s(msgHash: ByteArray, salt: ByteArray) -> Span<i32> {
    // Cairo's blake2s implementation supports input as [u32;16], so maximum 64 bytes
    // We cannot hash (msgHash||salt) as it is 32+40 = 72 bytes
    // Instead, we do the following:
    // 1. hash salt to get 32 bytes
    // 2. hash (msgHash|| saltHash) (64 bytes).
    // Then, we use the Blake2s_prng construction using a counter.

    // inital state is the IV (xor with a parameter for the first value)
    let iv = BoxTrait::new([
        0x6A09E667 ^ 0x01010020,
        0xBB67AE85, 0x3C6EF372, 0xA54FF53A,
        0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19,
    ]);

    // 1. hash salt to get 32 bytes
    let mut salt_array = bytearray_to_fixed_u32_array(salt);
    let salt_hash = blake2s_finalize(iv, 40, salt_array).span();

    // 2. hash (msgHash||saltHash)
    let mut msg_hash_array = bytearray_to_fixed_u32_array(msgHash).span();
    let int_input = BoxTrait::new([
            *msg_hash_array[0],
            *msg_hash_array[1],
            *msg_hash_array[2],
            *msg_hash_array[3],
            *msg_hash_array[4],
            *msg_hash_array[5],
            *msg_hash_array[6],
            *msg_hash_array[7],
            *salt_hash[0],
            *salt_hash[1],
            *salt_hash[2],
            *salt_hash[3],
            *salt_hash[4],
            *salt_hash[5],
            *salt_hash[6],
            *salt_hash[7],
        ]);

    let mut state = blake2s_finalize(iv, 64, int_input);
    // fixed state
    let mut fixed_state = ArrayTrait::new();
    for val in state.span() {
        fixed_state.append(*val);
    }

    // output polynomial
    let mut output = array![];

    // XOF starts
    let mut counter:u32 = 0;
    // the word (between 0 and 7) that we can consume.
    // We start at 8 so that it initialize with state with counter = 0.
    let mut word_index: u32 = 8;
    let mut _t:u32 = 0; // state word value
    let mut t: u16 = 0; // the value that can be reduced mod q

    let mut coef: i32 = 0;

    // iterate until you fill the 512 field elements
    let mut i = 0;
    while (i != 512) {
        while (word_index != 8) {
            // now, word_index is between 0 and 7
            let _t = state.span()[word_index];
            // lower part of _t
            t = ((*_t & 0xFF) * 256 + (*_t & 0xFF00) / 256).try_into().unwrap();
            if(t < 61445){
                coef = (t % 12289).try_into().unwrap();
                output.append(coef);
                i = i + 1;
                if (i == 512) {
                    break;
                }
            }

            // higher part of t
            t = ((*_t & 0xFF0000)/256 + (*_t & 0xFF000000)/16777216).try_into().unwrap();
            if(t < 61445){
                coef = (t % 12289).try_into().unwrap();
                output.append(coef);
                i = i + 1;
                if (i == 512) {
                    break;
                }
            }
            word_index = word_index+1;
        }
        // compute a new Blake2s hash
        let state_input= BoxTrait::new([
            *fixed_state[0],
            *fixed_state[1],
            *fixed_state[2],
            *fixed_state[3],
            *fixed_state[4],
            *fixed_state[5],
            *fixed_state[6],
            *fixed_state[7],
            0, counter*16777216,0,0,
            0,0,0,0
        ]);
        state = blake2s_finalize(iv, 40, state_input);
        counter = counter + 1;
        word_index = 0;
    }

    return output.span();
}


#[cfg(test)]
mod tests {
    use super::HashToPoint_Blake2s;
use core::blake::{blake2s_compress, blake2s_finalize};
    use core::box::BoxTrait;

    #[test]
    fn test_blake2s() {
        let state = BoxTrait::new([0_u32; 8]);
        let msg = BoxTrait::new([0_u32; 16]);
        let byte_count = 64_u32;
        let res = blake2s_compress(state, byte_count, msg).unbox();
        assert_eq!(
            res,
            [
                3893814314, 2107143640, 4255525973, 2730947657, 3397056017, 3710875177, 3168346915,
                365144891,
            ],
        );
        let res = blake2s_finalize(state, byte_count, msg).unbox();
        assert_eq!(
            res,
            [
                128291589, 1454945417, 3191583614, 1491889056, 794023379, 651000200, 3725903680,
                1044330286,
            ],
        );
    }

    #[test]
    fn test_blake2s_basic() {
        let state = BoxTrait::new([0_u32; 8]);
        let msg = BoxTrait::new([0_u32; 16]);
        let byte_count = 64_u32;
        
        let compress_result = blake2s_compress(state, byte_count, msg).unbox();
        
        let finalize_result = blake2s_finalize(state, byte_count, msg).unbox();
        
        // Just verify they return different results
        assert_ne!(compress_result, finalize_result);
    }

    #[test]
    fn test_blake2s_different_inputs() {
        let state1 = BoxTrait::new([0_u32; 8]);
        let msg1 = BoxTrait::new([0_u32; 16]);
        
        let state2 = BoxTrait::new([1_u32, 0_u32, 0_u32, 0_u32, 0_u32, 0_u32, 0_u32, 0_u32]);
        let msg2 = BoxTrait::new([1_u32, 0_u32, 0_u32, 0_u32, 0_u32, 0_u32, 0_u32, 0_u32, 0_u32, 0_u32, 0_u32, 0_u32, 0_u32, 0_u32, 0_u32, 0_u32]);
        
        let byte_count = 64_u32;
        
        let result1 = blake2s_finalize(state1, byte_count, msg1).unbox();
        let result2 = blake2s_finalize(state2, byte_count, msg2).unbox();
        
        // Different inputs should produce different outputs
        assert_ne!(result1, result2);
        
    }

    #[test]
    fn test_blake2s_with_abc() {
        // hashing `abc` as it is done in RFC 7693
        // inital state is the IV (xor with a parameter for the first value)
        let state = BoxTrait::new([
            0x6A09E667 ^ 0x01010020,
            0xBB67AE85, 0x3C6EF372, 0xA54FF53A,
            0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19,
        ]);
        // message `abc` padded with zeros
        let msg = BoxTrait::new([
            0x00636261, 0,0,0,
            0,0,0,0,
            0,0,0,0,
            0,0,0,0,
        ]);
        let byte_count = 3_u32;
        let res = blake2s_finalize(state, byte_count, msg).unbox();

        assert_eq!(
            res,
            // RFC Appendix B Blake2s Hash of `abc`:
            // 508C5E8C327C14E2E1A72BA34EEB452F37458B209ED63A294D999B4C86675982
            // Conversion (in python) into words:
            [
                0x8c5e8c50,
                0xe2147c32,
                0xa32ba7e1,
                0x2f45eb4e,
                0x208b4537,
                0x293ad69e,
                0x4c9b994d,
                0x82596786,
            ],
        );
    }

    #[test]
    fn test_hash_to_point_blake2s() {
        let mut msg = "\x4d\x79\x20\x6e\x61\x6d\x65\x20\x69\x73\x20\x52\x65\x6e\x61\x75\x64\x20\x66\x72\x6f\x6d\x20\x5a\x4b\x4e\x4f\x58\x21\x21\x21\x21";
        // salt is 40 bytes
        // Cairo does not support non-utf8 encoding
        let salt0 = 0x46b9dd2b0ba88d13233b3feb743eeb243fcd52ea;
        let salt1 = 0x62b81b82b50c27646ed5762fd75dc4ddd8c0f200;
        let mut salt = "";
        salt.append_word(salt0, 20);
        salt.append_word(salt1, 20);
        let pol = HashToPoint_Blake2s(msg, salt);
        println!("{:?}", pol);
    }
}