// Keccak Hash Contract
use core::byte_array::ByteArrayTrait;
use core::keccak::{keccak_u256s_le_inputs, compute_keccak_byte_array};
use core::to_byte_array::AppendFormattedToByteArray;


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
                while i < 4 && i < input.len() {
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


//salt: 40 bytes
//msgHash: 32 bytes
pub fn HashToPointRIP( salt: ByteArray,  msgHash: ByteArray) -> u256{
    let mut input:ByteArray=salt;
    input.append(@msgHash);

    let mut state:u256=compute_keccak_byte_array(@input);
    //convert state from u256 to byte array
    
    let mut a="";
    let mut i=0;
    while(i!=32){
        let byte:u8=(state&0xff).try_into().unwrap();
        state=state/256;
        a.append_byte(byte);
        i=i+1;
    }

    let mut counter:u8=0;
    let mut res:u256=0;

    while counter!=32{
        let mut ctx=a.clone();
        ctx.append_byte(counter);
        counter=counter+1;
        a.append_byte(counter);

        res=compute_keccak_byte_array(@a);
    }
    
    return res;
}

#[cfg(test)]
mod tests {
    use core::keccak::{keccak_u256s_le_inputs, compute_keccak_byte_array};
    use core::traits::Into;
    use core::array::ArrayTrait;

    #[test]
    fn test_keccak_direct() {
        let mut inputs = ArrayTrait::new();
        inputs.append(0x01020304);
        let _result = keccak_u256s_le_inputs(inputs.span());
        
        println!("Direct Keccak hash: {}", _result);
    }

    #[test]
    fn test_keccak_u256_logic() {
        let input: u256 = 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
        
        let mut u256_inputs = ArrayTrait::new();
        u256_inputs.append(input);
        let _result = keccak_u256s_le_inputs(u256_inputs.span());
        
        println!("Input: {}", input);
        println!("Keccak u256 hash: {}", _result);
    }

    #[test]
    fn test_keccak_simple_u256() {
        let simple_input: u256 = 12345;
        
        let mut u256_inputs = ArrayTrait::new();
        u256_inputs.append(simple_input);
        let _result = keccak_u256s_le_inputs(u256_inputs.span());
        
        println!("Input (decimal): {}", simple_input);
        println!("Keccak simple u256 hash: {}", _result);
    }

    #[test]
    fn test_keccak_bytes_logic() {
        let mut input = ArrayTrait::new();
        input.append(97);
        input.append(98);
        input.append(99);
       
        
        let input_span = input.span();
        let mut packed: u256 = 0;
        let mut i = 0;
        while i < input.len() {
            let byte_val: u256 = (*input_span.at(i)).into();
            packed = packed * 256 + byte_val;
            i += 1;
        };
        
        println!("Packed input: {}", packed);
        
        let mut u256_inputs = ArrayTrait::new();
        u256_inputs.append(packed);
        let _result = keccak_u256s_le_inputs(u256_inputs.span());
        
       //println!("***Keccak bytes hash: {}", _result);
    }

    #[test]
    fn test_keccak_empty() {
        let mut u256_inputs = ArrayTrait::new();
        u256_inputs.append(0);
        let _result = keccak_u256s_le_inputs(u256_inputs.span());
        
        println!("Keccak empty hash: {}", _result);
    }

    #[test]
    fn test_keccak_byte_array() {
        println!("Keccak byte array");

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