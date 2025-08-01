// Simple Working Poseidon Hash Contract



#[starknet::interface]
pub trait IPoseidonHash<TContractState> {
    fn compute_poseidon_hash(self: @TContractState, input: u256) -> felt252;
    fn compute_poseidon_hash_bytes(self: @TContractState, input: Array<u8>) -> felt252;
    fn get_hash_type(self: @TContractState) -> felt252;
}

#[starknet::contract]
pub mod PoseidonHash {
    use core::poseidon::PoseidonTrait;
    use core::hash::HashStateTrait;
    use core::traits::Into;
    use core::array::ArrayTrait;

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl PoseidonHashImpl of super::IPoseidonHash<ContractState> {
        fn compute_poseidon_hash(self: @ContractState, input: u256) -> felt252 {
            let input_low: u128 = input.low;
            let input_high: u128 = input.high;
            
            let low_felt: felt252 = input_low.into();
            let high_felt: felt252 = input_high.into();
            
            let mut hash_state = PoseidonTrait::new();
            hash_state = hash_state.update(low_felt);
            hash_state = hash_state.update(high_felt);
            hash_state.finalize()
        }

        fn compute_poseidon_hash_bytes(self: @ContractState, input: Array<u8>) -> felt252 {
            let mut hash_state = PoseidonTrait::new();
            let mut i = 0;
            let input_len = input.len();
            let input_span = input.span();
            
            while i < input_len {
                let mut chunk: felt252 = 0;
                let mut j = 0;
                
                while j < 31 && (i + j) < input_len {
                    let byte_val: felt252 = (*input_span.at(i + j)).into();
                    chunk = chunk * 256 + byte_val;
                    j += 1;
                };
                
                hash_state = hash_state.update(chunk);
                i += 31;
            };
            
            hash_state.finalize()
        }

        fn get_hash_type(self: @ContractState) -> felt252 {
            'poseidon'
        }
    }
}

#[cfg(test)]
mod tests {
    use core::poseidon::PoseidonTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};
    use core::traits::Into;
    use core::array::ArrayTrait;

    #[test]
    fn test_poseidon_direct() {
        let mut hash_state = PoseidonTrait::new();
        hash_state = hash_state.update(123);
        hash_state = hash_state.update(456);
        let result = hash_state.finalize();
        
        println!("Direct Poseidon hash of [123, 456]: {}", result);
    }

    #[test]
    fn test_poseidon_u256_logic() {
        let input: u256 = 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
        
        let input_low: u128 = input.low;
        let input_high: u128 = input.high;
        
        let low_felt: felt252 = input_low.into();
        let high_felt: felt252 = input_high.into();
        
        let mut hash_state = PoseidonTrait::new();
        hash_state = hash_state.update(low_felt);
        hash_state = hash_state.update(high_felt);
        let result = hash_state.finalize();
        
        println!("Poseidon u256 hash: {}", result);
    }

    #[test]
    fn test_poseidon_simple_u256() {
        let simple_input: u256 = 12345;
        let simple_low: felt252 = simple_input.low.into();
        let simple_high: felt252 = simple_input.high.into();
        
        let mut hash_state = PoseidonTrait::new();
        hash_state = hash_state.update(simple_low);
        hash_state = hash_state.update(simple_high);
        let result = hash_state.finalize();
        
        println!("Poseidon simple u256 hash: {}", result);
    }

    #[test]
    fn test_poseidon_bytes_logic() {
        let mut input = ArrayTrait::new();
        let mut i: u8 = 0;
        while i < 32 {
            input.append((i % 255) + 1);
            i += 1;
        };
        
        let mut hash_state = PoseidonTrait::new();
        let input_span = input.span();
        let input_len = input.len();
        let mut idx = 0;
        
        while idx < input_len {
            let mut chunk: felt252 = 0;
            let mut j = 0;
            
            while j < 31 && (idx + j) < input_len {
                let byte_val: felt252 = (*input_span.at(idx + j)).into();
                chunk = chunk * 256 + byte_val;
                j += 1;
            };
            
            hash_state = hash_state.update(chunk);
            idx += 31;
        };
        
        let result = hash_state.finalize();
        println!("Poseidon bytes hash: {}", result);
    }

    #[test]
    fn test_poseidon_small_bytes() {
        let mut small_input = ArrayTrait::new();
        small_input.append(1);
        small_input.append(2);
        small_input.append(3);
        small_input.append(4);
        
        let input_span = small_input.span();
        let mut chunk: felt252 = 0;
        let mut k = 0;
        while k < small_input.len() {
            let byte_val: felt252 = (*input_span.at(k)).into();
            chunk = chunk * 256 + byte_val;
            k += 1;
        };
        
        let mut hash_state = PoseidonTrait::new();
        hash_state = hash_state.update(chunk);
        let result = hash_state.finalize();
        
        println!("Poseidon small bytes hash: {}", result);
    }
}