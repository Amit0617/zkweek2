pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n]; // leaves -> 8 (say, for n = 3)
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    
    // Since one component can be used only once in circom we will need 2^n-1 hashing components
    var numHashingComponents = 2**n - 1;

    // Declaring required no. of hashers
    component hasher[numHashingComponents]; //length -> 7

    // Defining all hashers
    for (var i = 0; i < numHashingComponents; i++){
        hasher[i] = Poseidon(2);
    }
    
    // Hash levels above leaves (parents and ancestors).
    // Sum of all above hashes will be leafhashes - 1.
    
    // Hashes just above the hashedleaves will be half of them
    //  2**(n-1) hashers are already used up by hashedleaves only

    for (var i = 0; i < 2**(n-1); i++){  // 0 to 3 (i < 4)
        hasher[i].inputs[0] <== leaves[i*2];
        hasher[i].inputs[1] <== leaves[i*2 + 1];
    }

    // Hashes above in the tree will be hash of hashes below them
    var j = 0;
    for (var i = 2**(n-1); i < 2**n - 1; i++){  // 4 to 6 (4 =< i < 7)
        hasher[i].inputs[0] <== hasher[j*2].out;
        hasher[i].inputs[1] <== hasher[j*2 + 1].out;
        j++;
    }

    // return finally root output
    root <== hasher[numHashingComponents - 1].out; //hasher[6] 0 to 6 length -> 7

}

template Selector() {
    signal input input_elem;
    signal input path_elem;
    signal input path_index;

    signal output left;
    signal output right;

    path_index * (1-path_index) === 0;

    component mux = MultiMux1(2);
    mux.c[0][0] <== input_elem;
    mux.c[0][1] <== path_elem;

    mux.c[1][0] <== path_elem;
    mux.c[1][1] <== input_elem;

    mux.s <== path_index;

    left <== mux.out[0];
    right <== mux.out[1];
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path

    // Hasher with two inputs
    component hasher2[n];

    //Selector
    component selectors[n];
    
    //
    for (var i = 0; i < n; i++){
        hasher2[i] = Poseidon(2);
        selectors[i] = Selector();

        path_index[i] ==> selectors[i].path_index;
        path_elements[i] ==> selectors[i].path_elem;
    }

    leaf ==> selectors[0].input_elem;

    for (var i = 0; i < n; i++){
        selectors[i].left ==> hasher2[i].inputs[0];
        selectors[i].right ==> hasher2[i].inputs[1];
        if (i != n-1) {
            hasher2[i].out ==> selectors[i+1].input_elem;
        }
    }
    
    root <== hasher2[n - 1].out;

}
