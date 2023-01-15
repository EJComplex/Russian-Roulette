from scripts.helpful_scripts import get_account
from brownie import (
    RussianRoulette,
    VRFCoordinatorMock,
    interface,
    network,
    config,
    accounts,
    Contract,
)

import time
from web3 import Web3

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


def deployMock(account, contract):
    # account = get_account(index=index)
    deployedContract = contract.deploy(
        config["networks"][network.show_active()]["link"], {"from": account}
    )
    time.sleep(1)
    return deployedContract


# @printTxInfo
# @balanceIs(get_account(index=-2), token="dai")
def pull(account, contract, amount, tokenAddress):
    # account = get_account(index=index)
    # account = accounts.add(config["wallets"]["from_key"])
    tx = contract.pull(amount, tokenAddress, {"from": account, "gas_limit": 1000000})
    return tx


def approveToken(account, tokenAddress, approveAddress, amount):
    # account = get_account(index=index)
    # account = accounts.add(config["wallets"]["from_key"])
    token = interface.IERC20(tokenAddress)
    tx = token.approve(approveAddress, amount, {"from": account})
    return tx


def fundWithLink(account, contractAddress, amount):
    # account = get_account(index=index)
    # account = accounts.add(config["wallets"]["from_key"])
    link = interface.IERC20(config["networks"][network.show_active()]["link"])
    tx = link.transfer(contractAddress, amount, {"from": account})
    return tx


def deploy(account, contract, vrfCoordinator, link, keyhash, fee, publish_source=False):
    # account = get_account(index=index)
    # account = accounts.add(config["wallets"]["from_key"])
    deployedContract = contract.deploy(
        vrfCoordinator,
        link,
        keyhash,
        fee,
        {"from": account},
        publish_source=publish_source,
    )
    time.sleep(1)
    return deployedContract


# local
# def main():
#     account = get_account(index=-2)
#     DAI = config["networks"][network.show_active()]["dai"]
#     amount = Web3.toWei(100, "ether")

#     mockVRF = deployMock(account, VRFCoordinatorMock)

#     RR = deploy(
#         account,
#         RussianRoulette,
#         mockVRF.address,
#         config["networks"][network.show_active()]["link"],
#         config["networks"][network.show_active()]["vrf_coordinator"],
#         Web3.toWei(config["networks"][network.show_active()]["fee"], "ether"),
#     )

#     txFund = fundWithLink(
#         account,
#         RR,
#         Web3.toWei(config["networks"][network.show_active()]["fee"], "ether"),
#     )

#     txApprove = approveToken(account, DAI, RR.address, amount)

#     txPull = pull(account, RR, amount, DAI)
#     STATIC_RNG = 601
#     request_id = txPull.events["RequestRandomness"]["requestId"]

#     txRNG = mockVRF.callBackWithRandomness(
#         request_id, STATIC_RNG, RR.address, {"from": account}
#     )

#     txRNG.wait(1)

#     token_contract = interface.IERC20(DAI)
#     print(
#         f"RR DAI balance is {Web3.fromWei(token_contract.balanceOf(RR.address), 'ether')}"
#     )

#     print(
#         f"User DAI balance is {Web3.fromWei(token_contract.balanceOf(account.address), 'ether')}"
#     )


def main():
    # account = accounts.add(config["wallets"]["from_key"])
    account = get_account(index=-2)
    DAI = config["networks"][network.show_active()]["dai"]
    amount = Web3.toWei(100, "ether")

    mockVRF = deployMock(account, VRFCoordinatorMock)
    # print(type(mockVRF))

    RR = deploy(
        account,
        RussianRoulette,
        mockVRF.address,
        config["networks"][network.show_active()]["link"],
        config["networks"][network.show_active()]["keyhash"],
        Web3.toWei(config["networks"][network.show_active()]["fee"], "ether"),
        publish_source=False,
    )

    # print(RR.requestIdToSender(request_id))

    # print(RR.burnAddress())

    # RR = Contract.from_abi(
    #     RussianRoulette._name,
    #     "0x200c3D8b240391D06ea3f96cF31C79Ba6458CDa8",
    #     RussianRoulette.abi,
    # )

    # txFund = fundWithLink(account, RR, Web3.toWei(1, "ether"))
    txFund = fundWithLink(
        account,
        RR,
        Web3.toWei(config["networks"][network.show_active()]["fee"], "ether"),
    )

    txApprove = approveToken(account, DAI, RR.address, 10 * amount)

    # i = 0
    # while i < 10:
    #     txPull = pull(account, RR, amount, DAI)
    #     i += 1

    txPull = pull(account, RR, amount, DAI)

    STATIC_RNG = 601
    request_id = txPull.events["RequestRandomness"]["requestId"]
    # # print(request_id)

    txRNG = mockVRF.callBackWithRandomness(
        request_id, STATIC_RNG, RR.address, {"from": account}
    )

    print(RR.requestIdToSender(request_id))

    # txPull.wait(10)

    # token_contract = interface.IERC20(DAI)
    # print(
    #     f"RR DAI balance is {Web3.fromWei(token_contract.balanceOf(RR.address), 'ether')}"
    # )

    # print(
    #     f"User DAI balance is {Web3.fromWei(token_contract.balanceOf(account.address), 'ether')}"
    # )

    # print()


# # Need to update deploy and pull to be basic functionality. Create unit and inegration tests.
# # Need to redeploy since v2 contracts are set in constructor
# # Need to add to contract where if random fails, then funds returned
# # How is the link token being approved?
