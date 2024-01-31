// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// This module contains the permutations functions for generating all possible permutations of a vector of vectors.
module multisig::utils {
    use std::vector;

    /// Generates all possible permutations of a vector of vectors.
    ///
    /// This function takes a vector of vectors `pks` as input and generates all possible permutations of the vectors in `pks`.
    /// The function uses a modified version of the Heap's algorithm to generate the permutations.
    /// It initializes an empty vector `perms` to store the permutations and a vector `c` to encode the stack state.
    /// The function iterates through the vectors in `pks` and swaps elements based on the parity of the iteration index.
    /// It outputs each new permutation and increments the stack state accordingly.
    /// Finally, it returns the vector `perms` containing all the generated permutations.
    ///
    /// # Arguments
    ///
    /// * `pks` - A vector of vectors representing the input vectors to generate permutations for.
    ///
    /// # Returns
    ///
    /// A vector of vectors representing all possible permutations of the input vectors.
    ///
    /// # Examples
    ///
    /// ```
    /// let pks = vector[
    ///     vector[1, 2, 3],
    ///     vector[4, 5],
    ///     vector[6, 7, 8, 9]
    /// ];
    ///
    /// let perms = permutations(pks);
    ///
    /// assert!(vector::length(&perms) == 6, 0);
    /// assert!(*vector::borrow(&perms, 0) == vector[1, 2, 3], 0);
    /// assert!(*vector::borrow(&perms, 1) == vector[4, 5], 0);
    /// assert!(*vector::borrow(&perms, 2) == vector[6, 7, 8, 9], 0);
    /// assert!(*vector::borrow(&perms, 3) == vector[2, 1, 3], 0);
    /// assert!(*vector::borrow(&perms, 4) == vector[5, 4], 0);
    /// assert!(*vector::borrow(&perms, 5) == vector[7, 6, 8, 9], 0);
    /// ```
    public fun permutations<T: copy>(
        pks: &mut vector<T>,
    ): vector<vector<T>> {
        // initialize an empty vector to store the permutations
        let perms = vector::empty<vector<T>>();
        // get the length of the pks vector
        let n = vector::length(pks);
        // c is an encoding of the stack state. c[k] encodes the for-loop counter for when permutations(k - 1, pks) is called
        let c = vector::empty<u64>();
        // initialize c with zeros
        let i = 0;
        while (i < n) {
            vector::push_back(&mut c, 0);
            i = i + 1
        };
        // output the first permutation
        vector::push_back(&mut perms, *pks);
        // i acts similarly to a stack pointer
        i = 1;
        // loop until i is equal to n
        while (i < n) {
            // check if c[i] is less than i
            if (*vector::borrow(&c, i) < i) {
                // swap elements depending on the parity of i
                if (i % 2 == 0) {
                    vector::swap(pks, 0, i);
                } else {
                    vector::swap(pks, *vector::borrow(&c, (i as u64)), i);
                };
                // output the new permutation
                vector::push_back(&mut perms, *pks);
                // increment c[i] by 1
                *vector::borrow_mut(&mut c, i) = *vector::borrow(&c, i) + 1;
                // reset i to 1
                i = 1;
            } else {
                // reset c[i] to 0, c[i] = 0;
                *vector::borrow_mut(&mut c, i) = 0;
                // increment i by 1
                i = i + 1;
            };
        };
        // return the perms vector
        perms
    }

}
