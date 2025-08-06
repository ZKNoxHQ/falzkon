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

fn bytearray_bytes_to_box_u32(byte_array: ByteArray) -> Box<u32> {
    // Extract bytes and reconstruct u32 (big-endian)
    let mut value: u32 = 0;
    let len = byte_array.len();
    
    // Ensure we don't read more than 4 bytes for u32
    let bytes_to_read = if len > 4 { 4 } else { len };
    
    let mut i = 0;
    while i < bytes_to_read {
        let byte = byte_array[i];
        value = value * 256 + byte.into();
        i += 1;
    };
    
    BoxTrait::new(value)
}


// WE HAVE 18 if SALT + MSG = 72 BYTES...
fn bytearray_to_fixed_u32_array(input_bytes: ByteArray) -> Box<[u32; 16]> {
    let byte_len = input_bytes.len();
    let mut values = ArrayTrait::<u32>::new();
    
    // First, collect all u32 values in a dynamic array
    let mut i = 0;
    let mut values_created:u32 = 0;
    
    while i < byte_len && values_created < 16 {
        let mut value: u32 = 0;
        let mut byte_count:u32 = 0;
        
        while byte_count < 4 && i < byte_len {
            let byte_val: u32 = input_bytes[i].into();
            value = value * 8 + byte_val;
            i += 1;
            byte_count += 1;
        };
        
        while byte_count < 4 {
            value = value * 256;
            byte_count += 1;
        }
        
        values.append(value);
        values_created += 1;
    };
    
    // Pad with zeros
    while values_created < 16 {
        values.append(0);
        values_created += 1;
    }
    
    // Manually assign to fixed array (you'll need to expand this pattern)
    let result = [
        *values.at(0),  *values.at(1),  *values.at(2),  *values.at(3),
        *values.at(4),  *values.at(5),  *values.at(6),  *values.at(7),
        *values.at(8),  *values.at(9),  *values.at(10), *values.at(11),
        *values.at(12), *values.at(13), *values.at(14), *values.at(15)
    ];
    
    BoxTrait::new(result)
}

//salt: 40 bytes
//msgHash: 32 bytes
pub fn HashToPointBlake(salt: ByteArray, msgHash: ByteArray)  -> Span<i32>{

    let mut output = array![];
    // inital state is the IV (xor with a parameter for the first value)
    let iv = BoxTrait::new([
        0x6A09E667 ^ 0x01010020,
        0xBB67AE85, 0x3C6EF372, 0xA54FF53A,
        0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19,
    ]);

    // message to be hashed (40 + 32 = 72 bytes)
    let mut input_bytes:ByteArray=msgHash;
    input_bytes.append(@salt);
    println!("input_bytes: {:?}", input_bytes);
    let mut msg = bytearray_to_fixed_u32_array(input_bytes);
    println!("u32 array:");
    println!("{:?}", msg);
    // msg is now made of 18 values (u32).
    let byte_count:u32 = 18;
    let mut state = blake2s_finalize(iv, byte_count, msg).unbox();
    let [a,b,c,d,e,f,g,h] = state;

    println!("{:?}", state);

    let mut word_index: u32 = 0; // the word (between 0 and 7) that we can consume.
    let mut t_low: u16 = 0; // the value that can be reduced mod q
    let mut t_high: u16 = 0; // the value that can be reduced mod q
    let mut _t:u32 = 0; // state word value

    let mut coef: i32 = 0;

    let mut counter:u32 = 0;
    // iterate until you fill the 512 field elements
    let mut i = 0;
    while (i != 512) {
        while (word_index != 8) {
            // now, word_index is between 0 and 7
            let words: Array<u32> = array![a, b, c, d, e, f, g, h];
            let _t = words.get(word_index).unwrap().unbox();
            t_low = ((*_t & 0xFF) * 256 + (*_t & 0xFF00) / 256).try_into().unwrap();
            if(t_low < 61445){
                coef = (t_low % 12289).try_into().unwrap();
                output.append(coef);
                i = i + 1;
                if (i == 512) {
                    break;
                }
            }

            t_high = ((*_t & 0xFF0000)/256 + (*_t & 0xFF000000)/16777216).try_into().unwrap();
            if(t_high < 61445){
                coef = (t_high % 12289).try_into().unwrap();
                output.append(coef);
                i = i + 1;
                if (i == 512) {
                    break;
                }
            }
            word_index = word_index+1;
        }
        // compute a new Blake2s hash
        let new_state= BoxTrait::new([
            a,b,c,d,
            e,f,g,h,
            counter,0,0,0,
            0,0,0,0
        ]);
        // byte_count = 9 here but I am not sure.
        state = blake2s_finalize(iv, 9, new_state).unbox();
        let [a,b,c,d,e,f,g,h] = state;
        counter = counter + 1;
        word_index = 0;
    }

    return output.span();
}

fn HashToPointTrash()-> Span<i32>{
        let mut output = array![];
    let mut i = 0;
    while (i != 512){
        output.append(i);
        i = i+1;
    }
    return output.span();

}

#[cfg(test)]
mod tests {
    use super::{HashToPointBlake, HashToPointTrash};
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
        // let salt = "1234123412341234123412341234123412341234"; // conversion from ascii so 40 bytes?
        // let msgHash = "56785678567856785678567856785678"; // conversion from ascii so 32 bytes?
        let mut polynomial = HashToPointTrash();
        println!("{:?}", polynomial);
    }
}