# Shared Space

Test out a new concept where we use multisig functionality to create a shared space where objects inside it are owned by multiple people.

The objects owned by the multisig address are available from every public key(s) that can combine above threshold.

But, we use multisig contract to check which public keys have signed and issue `MemberProof` to the sender of the transaction.

Using this `MemberProof` we can authorize different combinations of public keys for different actions with these objects.

In this example we have a `MintCap` that is transferrable and updatable only by the 1st member of the multisig (`AdminAuth`),
while usable for minting only by the 2nd member (`MintAuth`).
