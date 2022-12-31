from unicodedata import decimal
import os
import json
from brownie import accounts, network, config, web3
import time

# FORKED_LOCAL_ENVIRONMENTS = ["mainnet-fork", "mainnet-fork-dev"]
# new comment
FORKED_LOCAL_ENVIRONMENTS = ["mainnet-fork"]
LOCAL_BLOCKCHAIN_ENVIRONMENTS = ["development", "ganache-local"]
TESTNET_ENVIRONMENTS = ["goerli"]

token_dict = {"dai": "DAI_ABI.json"}


def get_account(index=None, id=None, unlock_index=None):
    # accounts[0]
    # accounts.add("env")
    # accounts.load("id")

    if index:
        return accounts[index]

    if id:
        return accounts.load(id)

    if unlock_index:
        account = accounts.at(
            config["networks"][network.show_active()]["cmd_settings"]["unlock"][
                unlock_index
            ]
        )
        return account

    if (
        network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS
        or network.show_active() in FORKED_LOCAL_ENVIRONMENTS
    ):
        return accounts[0]

    return accounts.add(config["wallets"]["from_key"])


def get_contract_address(contractName):
    if network.show_active() in FORKED_LOCAL_ENVIRONMENTS:
        return config["networks"][network.show_active()][contractName]
    if network.show_active() in TESTNET_ENVIRONMENTS:
        return config["networks"][network.show_active()][contractName]
    else:
        return None


def get_ABI(token_name):
    token = token_dict[token_name]
    f = open(os.path.join(os.getcwd(), "ABI", network.show_active(), token))
    ABI = json.load(f)
    return ABI


def printParameters(token1, token2, AMOUNT_IN):
    print(
        "\n"
        + "Swap Parameters:"
        + "\n"
        + "Token In: "
        + token1
        + "\n"
        + "Token Out: "
        + token2
        + "\n"
        + "Amount In: "
        + str(web3.fromWei(AMOUNT_IN, "ether"))
        + "\n"
    )


def approve(token, spender_address, wallet_address, private_key):

    spender = spender_address
    max_amount = web3.toWei(2**64 - 1, "ether")
    nonce = web3.eth.getTransactionCount(wallet_address)

    tx = token.approve(spender, max_amount, {"from": wallet_address})
    tx.wait(1)

    # .buildTransaction({"from": wallet_address, "nonce": nonce})

    # signed_tx = web3.eth.account.signTransaction(tx, private_key)
    # tx_hash = web3.eth.sendRawTransaction(signed_tx.rawTransaction)
    # time.sleep(1)
    # tx_approve = token.events.Approval.createFilter(fromBlock="latest")

    # return web3.toHex(tx_hash)
    return tx


def approveWeb3Method(token, spender_address, wallet_address, private_key):

    spender = spender_address
    max_amount = web3.toWei(2**64 - 1, "ether")
    nonce = web3.eth.getTransactionCount(wallet_address)

    tx = token.functions.approve(spender, max_amount).buildTransaction(
        {"from": wallet_address, "nonce": nonce}
    )

    signed_tx = web3.eth.account.signTransaction(tx, private_key)
    tx_hash = web3.eth.sendRawTransaction(signed_tx.rawTransaction)

    return web3.toHex(tx_hash)
