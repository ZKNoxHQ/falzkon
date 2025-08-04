// Blake2s Hash Contract
use core::blake::{blake2s_compress, blake2s_finalize};
use core::box::BoxTrait;

#[starknet::interface]
pub trait IBlake2sHash<TContractState> {
    fn get_hash_type(self: @TContractState) -> felt252;
}

#[starknet::contract]
pub mod Blake2sHash {
    use core::blake::{blake2s_compress, blake2s_finalize};
    use core::box::BoxTrait;

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

    let mut state=blake2s_compress(IV, 18_u32, msg).unbox();

    let mut i=0;
   

    let mut counter:u32=0;
    let mut res:u256=0;
    //todo append counter to state

    while counter!=32{
        msg=BoxTrait::new([counter; 16]);
        let mut state=blake2s_compress(IV, 18_u32, msg).unbox();

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
        println!("Blake2s compress completed");
        
        let finalize_result = blake2s_finalize(state, byte_count, msg).unbox();
        println!("Blake2s finalize completed");
        
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
        
        println!("Blake2s produces different outputs for different inputs");
    }
}