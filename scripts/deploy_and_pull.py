from scripts.helpful_scripts import get_account
from brownie import (
    RussianRoulette,
    VRFCoordinatorMock,
    interface,
    network,
    config,
)

import time
from web3 import Web3
import pandas as pd
import numpy as np

# Decorator to print tx.info() after transaction
def printTxInfo(func):
    def wrap(*args, **kwargs):
        result = func(*args, **kwargs)

        if type(result) == network.contract.ProjectContract:
            print(result.tx.info())

        if type(result) == network.transaction.TransactionReceipt:
            print(result.info())

        return result

    return wrap


# Decorator to print balance before and after transaction.
# ETH by default, token if given.
def balanceIs(account, token=None):
    def balanceIsInner(func):
        def wrap(*args, **kwargs):
            if not token:
                print(Web3.fromWei(account.balance(), "ether"))
            if token:
                token_address = config["networks"][network.show_active()][token]
                token_contract = interface.IERC20(token_address)
                print(
                    f"{token} balance is {Web3.fromWei(token_contract.balanceOf(account.address), 'ether')}"
                )

            result = func(*args, **kwargs)

            if not token:
                print(Web3.fromWei(account.balance(), "ether"))
            if token:
                token_address = config["networks"][network.show_active()][token]
                token_contract = interface.IERC20(token_address)
                print(
                    f"{token} balance is {Web3.fromWei(token_contract.balanceOf(account.address), 'ether')}"
                )

            return result

        return wrap

    return balanceIsInner


def deployMock(contract):
    account = get_account(index=-2)
    deployedContract = contract.deploy(
        config["networks"][network.show_active()]["link"], {"from": account}
    )
    time.sleep(1)
    return deployedContract


# @printTxInfo
@balanceIs(get_account(index=-2), token="dai")
def pull(contract, amount, tokenAddress):
    account = get_account(index=-2)
    tx = contract.pull(amount, tokenAddress, {"from": account})
    return tx


def approveToken(tokenAddress, approveAddress, amount):
    account = get_account(index=-2)
    token = interface.IERC20(tokenAddress)
    tx = token.approve(approveAddress, amount, {"from": account})
    return tx


def fundWithLink(contractAddress, amount):
    account = get_account(index=-2)
    link = interface.IERC20(config["networks"][network.show_active()]["link"])
    tx = link.transfer(contractAddress, amount, {"from": account})
    return tx


def deploy(contract, vrfCoordinator, link, keyhash, fee):
    account = get_account(index=-2)
    deployedContract = contract.deploy(
        vrfCoordinator, link, keyhash, fee, {"from": account}
    )
    time.sleep(1)
    return deployedContract


def main():
    account = get_account(index=-2)
    DAI = config["networks"][network.show_active()]["dai"]
    amount = Web3.toWei(100, "ether")

    mockVRF = deployMock(VRFCoordinatorMock)

    RR = deploy(
        RussianRoulette,
        mockVRF.address,
        config["networks"][network.show_active()]["link"],
        "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc",
        Web3.toWei(0.1, "ether"),
    )

    txFund = fundWithLink(RR, Web3.toWei(1, "ether"))

    txApprove = approveToken(DAI, RR.address, amount)

    txPull = pull(RR, amount, DAI)
    STATIC_RNG = 601
    request_id = txPull.events["RequestRandomness"]["requestId"]

    txRNG = mockVRF.callBackWithRandomness(
        request_id, STATIC_RNG, RR.address, {"from": account}
    )

    txRNG.wait(1)

    token_contract = interface.IERC20(DAI)
    print(
        f"RR DAI balance is {Web3.fromWei(token_contract.balanceOf(RR.address), 'ether')}"
    )

    print(
        f"User DAI balance is {Web3.fromWei(token_contract.balanceOf(account.address), 'ether')}"
    )
