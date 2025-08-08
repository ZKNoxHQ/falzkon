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


pub fn HashToPoint_Blake2s(msgHash: ByteArray, salt: ByteArray) -> Span<felt252> {
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

    let mut coef: felt252 = 0;

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
        // Test vector taken from ETHFALCON repository in `test/ZKNOXHashToPointZKVectors.t.sol`
        let mut msg = "\x4d\x79\x20\x6e\x61\x6d\x65\x20\x69\x73\x20\x52\x65\x6e\x61\x75\x64\x20\x66\x72\x6f\x6d\x20\x5a\x4b\x4e\x4f\x58\x21\x21\x21\x21";
        // salt is 40 bytes
        // Cairo does not support non-utf8 encoding
        let salt0 = 0xf23a52b5da67eaf7baae0f5fb1369db78f3ac45f;
        let salt1 = 0x8c4ac5671d85735cdddb09d2b1e34a1fc066ff4a;
        let mut salt = "";
        salt.append_word(salt0, 20);
        salt.append_word(salt1, 20);
        let mut out = HashToPoint_Blake2s(msg, salt);
        let mut expected:Span<felt252> = array![
            1952, 6176,673,3128,6784,7239,9178,1821,8025,4491,8781,10767,6767,1868,2315,115,1022,2106,9533,1695,9904,9668,2971,11612,4095,5690,3922,10628,2548,10609,8060,4774,3839,8828,11005,424,9730,7803,2043,5714,3235,1150,9318,11684,3374,9353,8584,7793,9633,924,9619,8865,7550,4852,9279,10808,1517,7107,5199,11307,9715,8625,4999,5787,11201,4258,2057,5048,11198,9591,7947,5151,4123,10725,11587,5909,4510,11918,10202,9525,9345,10443,7938,7678,6645,1163,595,5360,2033,439,4111,8827,10086,7835,6645,8330,5315,9653,1039,693,9507,2925,2308,7060,12004,8691,1780,6649,10768,8909,10919,4916,6987,4235,11143,4127,3995,6793,7627,12253,858,5115,9104,8798,6530,6880,5337,9294,9206,8537,3096,8696,4409,9580,670,5563,10734,9728,2196,11068,296,1581,6955,10604,7150,12054,11458,11414,4833,7545,11756,7363,5845,8006,7096,882,3375,7053,7349,9567,2071,6159,8372,7535,9986,8911,7771,8260,6811,4040,14,10745,11698,3603,3507,7286,7956,5791,9248,11183,362,5,7361,1305,1739,8007,2600,634,2790,6394,6322,12037,7167,8166,7898,5118,8376,8495,3479,3594,1992,2904,5278,7246,4707,3754,7270,4035,1264,8414,1053,4860,6778,4031,9672,2108,3396,4397,10978,6244,3730,7647,8219,6695,3361,3258,8893,2190,9245,6037,5344,5070,11769,6057,10406,898,3014,11663,3076,7560,6105,202,7521,1933,1157,3160,6802,7393,9420,875,1821,12017,440,6563,2035,2442,11976,11750,6545,210,6078,11987,8960,4161,811,668,7159,2956,10542,12285,4228,5805,3593,2048,8804,2538,10196,7075,12264,6886,10495,10943,10127,6572,5914,9607,3047,3972,7904,4776,6917,667,4786,1995,8888,4336,989,6539,10784,1876,11385,7176,10139,6208,2159,6474,5822,6722,9310,6726,11626,4247,8383,11743,10643,3265,3021,8087,1005,11421,4276,8737,8536,1903,61,7838,1431,1320,5651,10782,4618,10730,5885,6395,4496,1326,4483,9505,10508,8546,31,2757,7879,4105,3593,5980,688,1306,4534,9327,10010,4366,2752,5919,4971,1278,3190,1843,11826,8590,12216,1148,3831,8322,4751,12119,574,377,4509,8653,1819,5399,10815,11219,4496,8199,6457,3257,8708,9828,1680,5170,9220,1172,9736,1633,138,5170,6218,709,12163,9909,5311,5377,1054,7576,7030,11422,8410,11908,7233,6019,141,5085,5241,1200,575,3140,7743,2124,4697,1894,6204,10866,467,3538,8002,7576,9869,2011,8043,11429,9713,12275,4843,7691,10405,2530,3767,894,9263,1068,4608,10276,7785,2271,8623,2608,1912,8489,6432,3559,3514,7999,9370,3446,1592,10061,11289,1922,1795,6224,7959,260,12185,7069,4338,5814,2063,2419,3304,4964,10975,5619,1905,4403,11803,10888,6294,4635,8119,3552,11557,11706,4877,506,8190,5674,701,8399,11894,3648,1341,3579,3302,8161,441,2650,10894,2537,12223,5837,8309,9492,1083,10514,9564,11806,1896,7873,3905,3904,3738,8531,5815,9794,3320,10348,4673,7509,9376,10396
        ].span();
        assert_eq!(expected, out);
    }
}