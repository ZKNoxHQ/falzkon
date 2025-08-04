// SPDX-FileCopyrightText: 2025 ZKNOX.
//
// SPDX-License-Identifier: MIT

//! Implementation of Number Theoretic Transform (NTT) based on ZKNOX implementation

// Remove unused imports for now
// use crate::zknox_nttconstants::{psi_rev};
use super::*;

use crate::keccak_hash::HashToPointRIP;
use crate::blake2s_hash::HashToPointBlake;


#[cfg(test)]
mod tests {
    use super::*;

    #[test] 
    //reference implementation
    fn test_HashToPointRIP() {
       let mut msgHash:ByteArray="caca";
       let mut nonce:ByteArray="ttoto";

       HashToPointRIP(nonce, msgHash);
       
    }

    #[test] 
    fn test_HashToPointBlake(){
        let mut msgHash:ByteArray="caca";
        let mut nonce:ByteArray="ttoto";
 
        HashToPointBlake(nonce, msgHash);
    }

}
