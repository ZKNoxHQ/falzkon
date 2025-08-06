// SPDX-FileCopyrightText: 2025 ZKNOX.
//
// SPDX-License-Identifier: MIT

//! Implementation of Number Theoretic Transform (NTT) based on ZKNOX implementation

// Remove unused imports for now
use super::*;

use core::keccak::{keccak_u256s_le_inputs, compute_keccak_byte_array};
pub const Q256: u256 = 12289;


fn append_txsalt(txhigh:felt252, txlow:felt252, salt_high:felt252, salt_low:felt252)->ByteArray{
    let mut out="";

    out.append_word(txhigh, 16);
    out.append_word(txlow, 16);
    out.append_word(salt_high, 20);  
    out.append_word(salt_low, 20);
    return out;
}


fn print_bytearray(in: ByteArray, length:usize){
    let mut cl=in.clone();
    let mut i:usize=0;

    while i!=length{
        println!("{:x}", cl[i]);
        i=i+1;
    }

}

//salt: 40 bytes
//msgHash: 32 bytes
pub fn HashToPoint_RIP( txhigh:felt252, txlow:felt252, salt_high:felt252, salt_low:felt252)  -> Span<felt252>{
    let mut vec=array![];//the 512 elements vector 
    let mut nchunks=0;//current number of reduced chunks
    let mut concat=append_txsalt(txhigh, txlow, salt_high, salt_low);
    //convert state from u256 to byte array
    
    let mut tmp=compute_keccak_byte_array(@concat);//result is reverted
    
    let statel=tmp&0xffffffffffffffffffffffffffffffff;//low 128 bits
    let stateh=tmp/0x100000000000000000000000000000000;//high 128 bits

    let statelow:felt252=statel.try_into().unwrap();
    let statehi:felt252=stateh.try_into().unwrap();

    let mut state="";
    state.append_word(statehi,16);
    state.append_word(statelow,16);
    state=state.rev();


    state.append_byte(0);
    state.append_byte(0);
    state.append_byte(0);
    state.append_byte(0);
    state.append_byte(0);
    state.append_byte(0);
    state.append_byte(0);// 56 MSB bit to 0, safe as counter cannot exceed 255

    let mut counter=0;
    let mut chunk_unreduced=0;

    while(counter!=255){
        concat=state.clone();
        concat.append_byte(counter);

        let statec=concat.clone();
        tmp=compute_keccak_byte_array(@concat);//result is reverted

      
        let mut i=0;
      
        while i!=16{
            chunk_unreduced=(tmp&0xff)*256+(tmp&0xff00)/256;//unrevert
            tmp=tmp/(256*256);
            
            if(chunk_unreduced<61445){
                let mut chunk:felt252=(chunk_unreduced%Q256).try_into().unwrap();
                vec.append(chunk);
               
                nchunks=nchunks+1;
                if(nchunks==512){
                    return vec.span();
                }
            }
            i=i+1;
            
        }
        counter=counter+1;
    }

    return vec.span();
}

fn HashToPointTrash()-> Span<felt252>{
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
    use super::*;
    use super::HashToPointTrash;
   
    #[test]
    fn test_cheap(){
        let mut a = HashToPointTrash();
    }
   
    #[test] 
    fn test_hash2Point(){
        let mut shi=0x46b9dd2b0ba88d13233b3feb743eeb243fcd52ea;
        let mut slo=0x62b81b82b50c27646ed5762fd75dc4ddd8c0f200;
        let mut txhi=0x4d79206e616d652069732052656e6175;
        let mut txlo=0x64206f662073697a6520333220212121;

        let mut res=HashToPoint_RIP(txhi, txlo, shi, slo);
        //reference vector generated with ETHFALCON python ref
        let mut expected= array![12209, 4306, 10034, 844, 6116, 11601, 11563, 1924, 7434, 6560, 2289, 5990, 8155, 3590, 9092, 3351, 7475, 4170, 11612, 206, 3252, 3740, 8024, 2144, 11239, 5587, 10540, 11767, 7078, 3849, 8792, 1431, 1604, 5089, 7244, 3755, 7721, 8059, 8244, 1561, 2221, 1523, 10622, 10951, 10382, 3890, 3689, 2241, 997, 9992, 11643, 11670, 1484, 5370, 792, 8565, 10144, 9075, 2024, 7007, 11627, 3246, 7228, 3544, 5071, 11581, 11425, 1582, 11120, 4331, 6099, 2010, 1331, 8828, 1773, 12218, 6539, 6686, 913, 8100, 1874, 1571, 1368, 10442, 2062, 2530, 2145, 7891, 9287, 10830, 9536, 10290, 334, 3016, 2112, 179, 2494, 2851, 4537, 4454, 11219, 10592, 667, 7923, 684, 6966, 3665, 5489, 657, 6707, 2161, 12167, 4841, 2066, 947, 7090, 5226, 5377, 1630, 6162, 2003, 4093, 5765, 151, 11215, 5602, 6534, 7725, 11562, 8207, 4470, 4507, 11673, 9226, 4517, 9462, 11969, 4920, 1496, 9420, 4262, 2658, 1250, 10273, 6553, 9268, 3839, 4972, 10395, 1147, 4412, 10843, 6548, 7322, 7267, 7132, 10394, 1019, 8648, 5447, 10779, 5989, 10514, 9707, 986, 2381, 10934, 3903, 7268, 7973, 10375, 7618, 12142, 2226, 1289, 1747, 3912, 2202, 11024, 8295, 10333, 3328, 9493, 2813, 9174, 9898, 680, 10203, 11815, 3277, 2268, 5791, 1760, 11445, 3470, 2331, 4644, 511, 1667, 1667, 3159, 3129, 205, 6086, 8852, 981, 6297, 4835, 1598, 10210, 8087, 6389, 6272, 8504, 2792, 11000, 12234, 6782, 3848, 9051, 9169, 5491, 5775, 11012, 10204, 7769, 10602, 7000, 9387, 12066, 93, 6800, 298, 3396, 9351, 1079, 6673, 10766, 9349, 7379, 11443, 3956, 10535, 3133, 1745, 8044, 10520, 9398, 3847, 4922, 11024, 5841, 6986, 9076, 3900, 301, 6297, 5782, 5331, 9980, 9228, 8298, 3666, 5364, 4313, 4208, 3589, 2830, 429, 10160, 12140, 2323, 12145, 7233, 6473, 11548, 8748, 1360, 10788, 12111, 3119, 11705, 5108, 3621, 6900, 4185, 12063, 2990, 4017, 11570, 11154, 1583, 8420, 8026, 3933, 8840, 4906, 12219, 10368, 67, 5771, 7989, 11868, 11309, 10367, 7021, 8070, 3657, 1852, 6740, 4175, 4405, 1353, 456, 5977, 3813, 2068, 2700, 4136, 9395, 5599, 1711, 3997, 4566, 8348, 3446, 1902, 1460, 9110, 8899, 8389, 9701, 6906, 11575, 2878, 7573, 8742, 307, 7931, 6768, 1645, 10704, 4493, 656, 6435, 2419, 10426, 12008, 7080, 10215, 4703, 376, 9360, 2884, 11892, 5752, 10321, 4294, 7631, 2360, 11059, 1729, 4833, 2552, 10195, 3171, 9279, 9810, 12122, 2276, 3490, 9692, 10209, 8165, 8683, 11116, 11361, 4753, 12099, 488, 6028, 1968, 7611, 5102, 9443, 7490, 835, 295, 2274, 4082, 5699, 8634, 10843, 7658, 12067, 2668, 7082, 6348, 9683, 5035, 1437, 5682, 5283, 6190, 11376, 4606, 5302, 4084, 1602, 326, 6559, 3839, 10591, 11533, 597, 7100, 9117, 977, 9103, 4079, 5629, 10560, 9608, 1110, 9975, 10019, 10690, 1640, 8200, 870, 3974, 7386, 789, 3468, 5544, 7354, 3881, 5737, 6528, 10033, 840, 9447, 3960, 571, 10257, 7457, 473, 12118, 651, 489, 8666, 7071, 8781, 1982, 6818, 11028, 7475, 9485, 11271, 7305, 11247, 131, 7633, 5367, 4977, 1630, 8944, 4222, 788, 6153, 5052, 5258, 10547, 8773, 6808, 9636, 11600, 5185, 5241, 2730, 9775, 10084, 3221, 205, 7585, 8525, 2816, 6734, 2516, 318, 10393, 320, 11103, 8431, 11163, 7063, 67, 7951, 10460, 8314, 6952, 5609, 9781, 9648, 3600, 6944, 11956, 11073, 2085, 877, 8308, 8037].span();

        assert_eq!(expected, res);

    }

}
