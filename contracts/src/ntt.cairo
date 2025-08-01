// SPDX-FileCopyrightText: 2025 StarkWare Industries Ltd.
//
// SPDX-License-Identifier: MIT

//! Implementation of Number Theoretic Transform (NTT) for polynomials in Z_q[x]/(phi)
//! Ported from https://github.com/tprest/falcon.py/blob/master/ntt.py

use crate::ntt_constants::{get_even_roots, get_even_roots_inv};
use crate::zq::{add_mod, mul3_mod, mul_mod, sub_mod};

pub const I2: u16 = 6145; // Inverse of 2 mod q
pub const I2_INV: u16 = 6145; // Inverse of 2 mod q
pub const SQR1: u16 = 1479; // Square root of (-1) mod q
pub const SQR1_INV: u16 = 10810; // Inverse of SQR1 mod q


/// Subtract coefficients of two polynomials modulo Q
pub fn sub_zq(mut f: Span<u16>, mut g: Span<u16>) -> Span<u16> {
    assert(f.len() == g.len(), 'f.len() != g.len()');
    let mut res = array![];

    while let Some(f_coeff) = f.pop_front() {
        let g_coeff = g.pop_front().unwrap();
        res.append(sub_mod(*f_coeff, *g_coeff));
    }

    res.span()
}

/// Multiply coefficients of two polynomials modulo Q
pub fn mul_ntt(mut f: Span<u16>, mut g: Span<u16>) -> Span<u16> {
    assert(f.len() == g.len(), 'f.len() != g.len()');
    let mut res = array![];

    while let Some(f_coeff) = f.pop_front() {
        let g_coeff = g.pop_front().unwrap();
        res.append(mul_mod(*f_coeff, *g_coeff));
    }

    res.span()
}

/// Multiply two polynomials using
pub fn mul_zq(f: Span<u16>, g: Span<u16>) -> Span<u16> {
    let f_ntt = ntt(f);
    let g_ntt = ntt(g);
    let res_ntt = mul_ntt(f_ntt, g_ntt);
    intt(res_ntt)
}

/// Split a polynomial f in two polynomials.
pub fn split_ntt(mut f_ntt: Span<u16>) -> (Span<u16>, Span<u16>) {
    let n = f_ntt.len();
    let mut roots_inv = get_even_roots_inv(n);
    let mut f0_ntt = array![];
    let mut f1_ntt = array![];

    while let Some(root_inv) = roots_inv.pop_front() {
        let even = *f_ntt.pop_front().unwrap();
        let odd = *f_ntt.pop_front().unwrap();
        let even_ntt = mul_mod(I2, add_mod(even, odd));
        let odd_ntt = mul3_mod(I2, sub_mod(even, odd), *root_inv);
        f0_ntt.append(even_ntt);
        f1_ntt.append(odd_ntt);
    }

    (f0_ntt.span(), f1_ntt.span())
}

/// Merge two polynomials in NTT representation.
pub fn merge_ntt(mut f0_ntt: Span<u16>, mut f1_ntt: Span<u16>) -> Span<u16> {
    assert(f0_ntt.len() == f1_ntt.len(), 'f0_ntt.len() != f1_ntt.len()');
    let n = 2 * f0_ntt.len();
    let mut roots = get_even_roots(n);
    let mut f_ntt = array![];

    while let Some(root) = roots.pop_front() {
        let f0 = *f0_ntt.pop_front().unwrap();
        let f1 = *f1_ntt.pop_front().unwrap();
        let even = add_mod(f0, mul_mod(*root, f1));
        let odd = sub_mod(f0, mul_mod(*root, f1));
        f_ntt.append(even);
        f_ntt.append(odd);
    }

    f_ntt.span()
}

/// Split a polynomial f in two polynomials.
pub fn split(mut f: Span<u16>) -> (Span<u16>, Span<u16>) {
    let mut f0 = array![];
    let mut f1 = array![];

    while let Some(even) = f.pop_front() {
        let odd = f.pop_front().unwrap();
        f0.append(*even);
        f1.append(*odd);
    }

    (f0.span(), f1.span())
}

/// Merge two polynomials into a single polynomial f.
pub fn merge(mut f0: Span<u16>, mut f1: Span<u16>) -> Span<u16> {
    let mut f = array![];

    while let Some(f0) = f0.pop_front() {
        let f1 = f1.pop_front().unwrap();
        f.append(*f0);
        f.append(*f1);
    }

    f.span()
}

// Compute the NTT of a polynomial
pub fn ntt(mut f: Span<u16>) -> Span<u16> {
    let n = f.len();
    if n > 2 {
        let (f0, f1) = split(f);
        let f0_ntt = ntt(f0);
        let f1_ntt = ntt(f1);
        merge_ntt(f0_ntt, f1_ntt)
    } else if n == 2 {
        let f1_j = mul_mod(SQR1, *f[1]);
        let even = add_mod(*f[0], f1_j);
        let odd = sub_mod(*f[0], f1_j);
        array![even, odd].span()
    } else {
        assert(false, 'n is not a power of 2');
        array![].span()
    }
}

// Compute the inverse NTT of a polynomial
pub fn intt(mut f_ntt: Span<u16>) -> Span<u16> {
    let n = f_ntt.len();
    if n > 2 {
        let (f0_ntt, f1_ntt) = split_ntt(f_ntt);
        let f0 = intt(f0_ntt);
        let f1 = intt(f1_ntt);
        merge(f0, f1)
    } else if n == 2 {
        let even = mul_mod(I2, add_mod(*f_ntt[0], *f_ntt[1]));
        let odd = mul3_mod(I2, sub_mod(*f_ntt[0], *f_ntt[1]), SQR1_INV);
        array![even, odd].span()
    } else {
        assert(false, 'n is not a power of 2');
        array![].span()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

   

    #[test]
    fn test_ntt_512() {
        let f: [u16; 512] = [
            1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
            25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46,
            47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68,
            69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90,
            91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109,
            110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126,
            127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143,
            144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160,
            161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177,
            178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194,
            195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211,
            212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228,
            229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245,
            246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262,
            263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274, 275, 276, 277, 278, 279,
            280, 281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295, 296,
            297, 298, 299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312, 313,
            314, 315, 316, 317, 318, 319, 320, 321, 322, 323, 324, 325, 326, 327, 328, 329, 330,
            331, 332, 333, 334, 335, 336, 337, 338, 339, 340, 341, 342, 343, 344, 345, 346, 347,
            348, 349, 350, 351, 352, 353, 354, 355, 356, 357, 358, 359, 360, 361, 362, 363, 364,
            365, 366, 367, 368, 369, 370, 371, 372, 373, 374, 375, 376, 377, 378, 379, 380, 381,
            382, 383, 384, 385, 386, 387, 388, 389, 390, 391, 392, 393, 394, 395, 396, 397, 398,
            399, 400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415,
            416, 417, 418, 419, 420, 421, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432,
            433, 434, 435, 436, 437, 438, 439, 440, 441, 442, 443, 444, 445, 446, 447, 448, 449,
            450, 451, 452, 453, 454, 455, 456, 457, 458, 459, 460, 461, 462, 463, 464, 465, 466,
            467, 468, 469, 470, 471, 472, 473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483,
            484, 485, 486, 487, 488, 489, 490, 491, 492, 493, 494, 495, 496, 497, 498, 499, 500,
            501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 512,
        ];
        let f_ntt = ntt(f.span());
        let expected: [u16; 512] = [
            5279, 3373, 4474, 2755, 3765, 9923, 3810, 3849, 7484, 7688, 2182, 10827, 1657, 11101,
            5792, 5625, 4853, 9981, 11391, 12151, 10356, 9385, 10254, 11882, 10065, 3166, 7284,
            2798, 349, 4115, 6604, 11810, 2817, 10275, 972, 7081, 2677, 10391, 4740, 10820, 2734,
            6842, 3379, 7232, 7901, 7378, 6672, 2193, 6983, 4798, 3246, 3154, 2388, 2203, 3144,
            11147, 10230, 9852, 11773, 986, 9864, 8821, 7362, 4616, 9305, 320, 3254, 624, 4672,
            11852, 4152, 566, 2582, 6448, 2940, 6022, 2616, 2667, 489, 9708, 11505, 8617, 6301,
            9398, 2968, 676, 11890, 9452, 8711, 5667, 9013, 12054, 1580, 6549, 8972, 3060, 3539,
            2634, 10641, 6588, 3692, 3511, 7128, 2410, 2154, 4879, 4081, 2636, 554, 7211, 618, 885,
            4523, 3683, 11146, 257, 3113, 6560, 5734, 3494, 583, 5564, 11385, 2231, 10313, 6010,
            1831, 8676, 2821, 12214, 2399, 6393, 5451, 10720, 5277, 10905, 2198, 7175, 122, 10473,
            3007, 10327, 10191, 5182, 791, 478, 4070, 7639, 1165, 5553, 11545, 2849, 9105, 10242,
            1914, 8351, 595, 6350, 912, 9715, 10676, 6391, 5189, 1381, 3646, 7142, 1086, 2225, 324,
            12221, 7615, 10926, 9304, 6072, 845, 2987, 5676, 6434, 11779, 2873, 1350, 6309, 10900,
            8506, 1023, 401, 2922, 11617, 7668, 939, 12157, 10224, 9585, 8925, 7816, 254, 3392,
            6480, 3036, 2505, 9012, 7124, 11487, 5059, 1630, 11412, 573, 7180, 5888, 6184, 8959,
            900, 9597, 4871, 3383, 3190, 1822, 2375, 925, 1548, 5365, 6352, 5404, 1988, 2110, 5276,
            4417, 11651, 8388, 10920, 10705, 10871, 9318, 7934, 9118, 9937, 5799, 11544, 4177, 7945,
            4605, 2359, 10417, 8643, 7502, 6405, 6647, 529, 1099, 3597, 3037, 7190, 3555, 1685,
            10546, 10903, 11127, 4350, 3939, 11493, 9290, 8504, 9290, 9826, 5304, 2747, 10624, 2441,
            4666, 3413, 1738, 1590, 4355, 597, 8902, 8058, 8469, 10669, 993, 14, 4576, 3338, 1336,
            2680, 9383, 5381, 8436, 10658, 11749, 8746, 4171, 4364, 8255, 3017, 8165, 5316, 11327,
            10625, 4810, 3579, 598, 9188, 414, 9696, 11117, 9780, 5374, 12285, 4932, 558, 9697,
            1979, 8155, 592, 7784, 257, 10670, 7169, 10686, 3153, 928, 6390, 3046, 5425, 12162,
            8395, 8141, 2461, 695, 4405, 11854, 9184, 6700, 7652, 11014, 7952, 4167, 6620, 11476,
            6950, 8669, 6263, 4309, 152, 9467, 10248, 1814, 10710, 9567, 10204, 2799, 10134, 2581,
            8233, 7679, 4664, 633, 9050, 1600, 9004, 2499, 6966, 2433, 5556, 3804, 1153, 5946, 3025,
            8277, 5117, 8233, 3633, 10913, 4163, 3960, 6135, 3599, 3315, 2727, 11110, 9779, 3280,
            5003, 7, 2264, 10060, 534, 10879, 10138, 6260, 5488, 2851, 11571, 4457, 4063, 4952,
            2578, 3732, 10464, 4856, 8811, 12150, 11528, 9063, 1206, 2564, 5788, 8921, 1848, 8939,
            11791, 4305, 7541, 10623, 12191, 4507, 10604, 4918, 83, 2336, 4015, 10256, 3156, 1025,
            1651, 1574, 297, 2479, 11729, 10623, 11854, 3589, 7904, 3445, 617, 3925, 1387, 6827,
            7313, 7259, 10286, 12036, 8992, 5205, 6567, 7046, 3562, 1031, 3246, 4438, 4541, 4969,
            5954, 2022, 4890, 6822, 8989, 6715, 4125, 6426, 11418, 10731, 3858, 4100, 4075, 1888,
            2102, 1235, 9804, 8848, 2643, 8015, 9697, 11626, 6607, 2679, 9373, 9835, 7933, 7467,
            1156, 8000, 4684, 1912, 5656, 8282, 7847, 12170, 4190, 3543, 4520, 11875, 448, 9298,
            2763, 2585, 763, 7630, 9128, 6642, 9370, 6551, 7537, 10502, 11107, 1994, 5545, 3744,
            12157, 11634, 7025, 2914,
        ];
        assert_eq!(f_ntt, expected.span());

       // let f_intt = intt(f_ntt);
       // assert_eq!(f_intt, f.span());
    }

}
