// SPDX-FileCopyrightText: 2025 ZKNOX.
//
// SPDX-License-Identifier: MIT

//! Implementation of Number Theoretic Transform (NTT) based on ZKNOX implementation

use crate::zknox_ntt::{zknox_nttInv, zknox_nttFW};

pub const Q: i32 = 12289;
pub const n: usize=512;
pub const qs1:i32 = 6144; // q >> 1;
pub const sigBound:i32 = 34034726;

//multiplication where the right operator is already in ntt representation (example: public key ntt precomputed for once)
//result is not reduced to spare modular reductions
fn zknox_nttHalfMul_unreduced(mut a: Span<felt252>, mut ntt_b: Span<felt252>) ->Span<felt252>{
    let mut tmp=array![];

    let mut ntt_a=zknox_nttFW(a);
    let mut i=0;
    while(i!=512){
        tmp.append(*ntt_a[i]* *ntt_b[i]);

        i=i+1;
    }

    return tmp.span();
}



fn zknox_falcon_normalize(mut s1: Span<i32>, mut s2: Span<i32>, mut hashed: Span<i32>) -> bool{

    let mut i=0;
    let mut norm:i32=0;

    while i!=512{
        let mut tmp=*s1[i];
        if tmp>qs1 {
            norm=norm+(Q-tmp)*(Q-tmp);
        }
        else{
            norm=norm+(tmp*tmp);
        }
        tmp=*s2[i];
        norm=norm+(tmp*tmp);
    }
    if norm > sigBound{
        return false;
    }
    return true;
}


//s2: 512 felts of value <12289 representing the s2 part of falcon signature
//ntth: 512 felts of value <12289 representing the public key in ntt representation
//result of hashToPoint(signature.salt, msgs, q, n);
pub fn zknox_falcon_core(mut s2: Span<felt252>, mut ntth: Span<felt252>, mut hashed: Span<felt252>) -> Span<felt252> {
    let mut tmp=array![];



    return tmp.span();
}

//test extracted from
//https://github.com/ZKNoxHQ/ETHFALCON/blob/75f01adda9ab6da45f2dd800109cd94f24cf0668/test/ZKNOX_NTT.t.sol#L69