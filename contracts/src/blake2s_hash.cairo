// Blake2s Hash Contract

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