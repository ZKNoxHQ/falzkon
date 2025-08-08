// Keccak Hash Contract


#[starknet::interface]
pub trait IKeccakHash<TContractState> {
    fn compute_keccak_hash(self: @TContractState, input: Array<u8>) -> u256;
    fn compute_keccak_hash_u256(self: @TContractState, input: u256) -> u256;
    fn compute_keccak_byte_array(self: @TContractState, input: ByteArray) -> u256;
    fn get_hash_type(self: @TContractState) -> felt252;
}

#[starknet::contract]
pub mod KeccakHash {
    use core::keccak::{keccak_u256s_le_inputs, compute_keccak_byte_array};
    use core::traits::Into;
    use core::array::ArrayTrait;

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl KeccakHashImpl of super::IKeccakHash<ContractState> {
        fn compute_keccak_hash(self: @ContractState, input: Array<u8>) -> u256 {
            let mut u256_inputs = ArrayTrait::new();
            
            if input.len() == 0 {
                u256_inputs.append(0);
            } else {
                let input_span = input.span();
                let mut packed: u256 = 0;
                let mut i = 0;
                while i != 4 && i != input.len() {
                    let byte_val: u256 = (*input_span.at(i)).into();
                    packed = packed * 256 + byte_val;
                    i += 1;
                };
                u256_inputs.append(packed);
            }
            
            keccak_u256s_le_inputs(u256_inputs.span())
        }

        fn compute_keccak_hash_u256(self: @ContractState, input: u256) -> u256 {
            let mut u256_inputs = ArrayTrait::new();
            u256_inputs.append(input);
            keccak_u256s_le_inputs(u256_inputs.span())
        }

        fn compute_keccak_byte_array(self: @ContractState, input: ByteArray) -> u256 {
            compute_keccak_byte_array(@input)
        }

        fn get_hash_type(self: @ContractState) -> felt252 {
            'keccak'
        }
    }
}



#[cfg(test)]
mod tests {
    use core::keccak::{compute_keccak_byte_array};
   

    #[test]
    fn test_keccak_byte_array() {
        
        //can be assessed against https://emn178.github.io/online-tools/keccak_256.html
        assert_eq!(
            compute_keccak_byte_array(@""),
            0x70a4855d04d8fa7b3b2782ca53b600e5c003c7dcb27d7e923c23f7860146d2c5,
        );
        assert_eq!(
            compute_keccak_byte_array(@"0123456789abedef"),
            0x156c8d1049ee26f4f392bf8260b9e1c5ad5542778f003235f8cf5e0a19520886,
        );
        assert_eq!(
            compute_keccak_byte_array(@"hello-world"),
            0xd9ba3e823d55e5075f58ee022c16025c3abe8b41b95d7b4651a3cf8422ad1bd4,
        );
    }

   

    
}