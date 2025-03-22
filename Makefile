-include .env

.PHONY: deploy

deploy :; @forge script script/DAO.s.sol:DAOScript \
  --account wallet_test --rpc-url ${SEPOLIA_RPC_URL} \
  --priority-gas-price 1 --broadcast

verify :; @forge verify-contract \
  --rpc-url ${SEPOLIA_RPC_URL} \
  --verifier blockscout \
  --verifier-url ${SEPOLIA_VERIFIER_URL} \
  ${SEPOLIA_CONTRACT_NZDD_ADDRESS} \
  src/DAO.sol:DAO \
  --verifier-api-key ${SEPOLIA_VERIFIER_API_KEY}

# Projects on DAO with ETH
createProposal_1 :; @cast send --account wallet_test --rpc-url ${SEPOLIA_RPC_URL} ${SEPOLIA_CONTRACT_ETH_ADDRESS} \
  "createProposal(string,uint256,address)" "Project 1" '0.001 ether' ${PROJECT_WALLET_1} --priority-gas-price 1

createProposal_2 :; @cast send --account wallet_test --rpc-url ${SEPOLIA_RPC_URL} ${SEPOLIA_CONTRACT_ETH_ADDRESS} \
  "createProposal(string,uint256,address)" "Project 2" '0.002 ether' ${PROJECT_WALLET_2} --priority-gas-price 1

createProposal_3 :; @cast send --account wallet_test --rpc-url ${SEPOLIA_RPC_URL} ${SEPOLIA_CONTRACT_ETH_ADDRESS} \
  "createProposal(string,uint256,address)" "Project 3" '0.005 ether' ${PROJECT_WALLET_3} --priority-gas-price 1

# View total deposited DAO with ETH
depositBalance :; @cast call --rpc-url ${SEPOLIA_RPC_URL} ${SEPOLIA_CONTRACT_ETH_ADDRESS} \
  "totalDeposits()"

# Deposit ETH into DAO
deposit :; @cast send --account wallet_test --rpc-url ${SEPOLIA_RPC_URL} ${SEPOLIA_CONTRACT_ETH_ADDRESS} \
  "deposit()" '0.003 ether' --priority-gas-price 1

# Vote on a proposal
voteProposal :; @cast send --account wallet_test --rpc-url ${SEPOLIA_RPC_URL} ${SEPOLIA_CONTRACT_ETH_ADDRESS} \
  "vote(uint256,bool)" ${PROPOSAL_ID} true --priority-gas-price 1


#################################
# New DAO Contract with NZDD    #
#################################

# Projects on DAO with NZDD
createProposal1 :; @cast send --account wallet_test --rpc-url ${SEPOLIA_RPC_URL} ${SEPOLIA_CONTRACT_NZDD_ADDRESS} \
  "createProposal(string,uint256,address)" "Project 1" 100000000 ${PROJECT_WALLET_1} --priority-gas-price 1

createProposal2 :; @cast send --account wallet_test --rpc-url ${SEPOLIA_RPC_URL} ${SEPOLIA_CONTRACT_NZDD_ADDRESS} \
  "createProposal(string,uint256,address)" "Project 2" 200000000 ${PROJECT_WALLET_2} --priority-gas-price 1

createProposal3 :; @cast send --account wallet_test --rpc-url ${SEPOLIA_RPC_URL} ${SEPOLIA_CONTRACT_NZDD_ADDRESS} \
  "createProposal(string,uint256,address)" "Project 3" 150000000 ${PROJECT_WALLET_3} --priority-gas-price 1

# View total deposited DAO with NZDD
depositBalance_nzdd :; @cast call --rpc-url ${SEPOLIA_RPC_URL} ${SEPOLIA_CONTRACT_NZDD_ADDRESS} \
  "totalDeposits()" | cast --to-dec

# Approve NZDD tokens for DAO contract
approve_nzdd :; @cast send --account wallet_test --rpc-url ${SEPOLIA_RPC_URL} ${SEPOLIA_NZDD_TOKEN_ADDRESS} \
  "approve(address,uint256)" ${SEPOLIA_CONTRACT_NZDD_ADDRESS} 50000000000 --priority-gas-price 1

# Deposit NZDD into DAO (run approve_nzdd first!)
deposit_nzdd :; @cast send --account wallet_test --rpc-url ${SEPOLIA_RPC_URL} ${SEPOLIA_CONTRACT_NZDD_ADDRESS} \
  "deposit(uint256)" 50000000000 --priority-gas-price 1

# Vote on a proposal
voteProposal_nzdd :; @cast send --account wallet_test --rpc-url ${SEPOLIA_RPC_URL} ${SEPOLIA_CONTRACT_NZDD_ADDRESS} \
  "vote(uint256)" ${PROPOSAL_ID} --priority-gas-price 1