# DNA Sequences Alignment

DNA (deoxyribonucleic acid) is a chain of nitrogenous bases
 - Adenine (A)
 - Timina (T)
 - Cytosine (C)
 - Guanina (G)

Since each item of the sequence differs from another by its position and its
base subtype, the DNA sequences are simply represented as text strings,
each character being the initial of its subtype.

    AATCAG

With the passage of time, a DNA sequence can undergo point mutations by
changing a base nitrogenated by another, may undergo removal (loss of bases) or
insertions (new bases are inserted).

Two DNA sequences will be similar if they have large subsequences of
nitrogenous bases in both chains and in the same positions or, in nearby
positions in such a way that additions/removals to align them is minimum.

In contrast, two sequences with few and small shared subsequences or
that require a greater number of movements during the alignment are less
similar to each other.

This problem is known as DNA Sequences Alignment.

## Smith-Waterman Algorithm

Let the two sequences to be compared ``S1 = a1, a2, ....`` and ``S2 = b1, b2, ....``
with lengths ``L1`` and ``L2``; a matrix ``H`` is constructed of dimensions
``(L1 + 1) x (L2 + 1)`` and the first row and the first column are initialized with
zeros
 - ``H(0, j) = 0 for all j``
 - ``H(i, 0) = 0 for all i``

Then, the rest of the values of the matrix ``H(i, j)`` are calculated as the
maximum value of
 - ``0``
 - ``H(i-1, j-1) + W(ai, bj)``
 - ``H(i-1, j  ) + W(ai, - )``
 - ``H(i,   j-1) + W( -, bj)``

The function ``W(ai, bj)`` determines the bonus for having a coincidence
(the elements ``ai`` and ``bj`` are equal) or a penalty for being different.

The special cases ``W(ai, -)`` and ``W( -, bj)`` allow to quantify the
penalty for each displacement we have to do (alignment).

Currently we support the following values:
 - ``W(ai, bj) = Wsame if ai == bj``
 - ``W(ai, bj) = Wdiff if ai != bj``
 - ``W(ai, - ) = W(­-, bj) = Wgap``

Finally, in the last value of the matrix ``H(L1, L2)`` is the final score,
a quantification of the similarity between both sequences.

## Usage

```
$ dna-seq-sort input
```

Where the ``input`` file has the following format:

```
<Wsame>,<Wdiff>,<Wgap>,<max-length>
<S>
<S1>
<S2>
...
```

The first line describe the ``W`` parameters; the last value define the max
length of the following sequences.

The second line describe the *target* DNA sequence, the point of comparison.

The next lines each one describe an another DNA sequence.

The output of the program gives the sequences sorted by their coincidence score.
