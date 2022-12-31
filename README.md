# Spec - BowTiedPickle
 - Single base token
 - User calls "pull" and sends tokens to the Roulette contract
 - Use Chainlink VRF to roll a random number between 1 and 6
 - If the number is 6, burn the tokens
 - If the number is not 6, send the tokens back to the user
 - Permission-less contract with no owner functions
 - There are a lot of security considerations, make sure it's airtight

 Mix-ins:
 - Support arbitrary tokens
 - support NFTs