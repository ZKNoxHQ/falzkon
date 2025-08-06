// Blake2s Hash Contract
use core::blake::{blake2s_compress};
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


//salt: 40 bytes
//msgHash: 32 bytes
pub fn HashToPointBlake( salt: ByteArray,  msgHash: ByteArray) -> u256{
    let mut input:ByteArray=salt;
    input.append(@msgHash);


    //todo convert input to boxTrait
    //let mut state:u256=compute_keccak_byte_array(@input);
    //convert state from u256 to byte array
    let mut IV = BoxTrait::new([0_u32; 8]);
    let mut msg = BoxTrait::new([0_u32; 16]);//msghash+salt=72 bytes = 18 u32

    //let mut state=blake2s_compress(IV, 18_u32, msg).unbox();

    //let mut i=0;
   

    let mut counter:u32=0;
    let mut res:u256=0;
    //todo append counter to state

    while counter!=32{
        msg=BoxTrait::new([counter; 16]);
        //let mut state=blake2s_compress(IV, 18_u32, msg).unbox();

        counter=counter+1;

    }
    
    return res;
}

#[cfg(test)]
mod tests {
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
    
}