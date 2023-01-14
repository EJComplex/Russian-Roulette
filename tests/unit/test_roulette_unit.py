from scripts.helpful_scripts import get_account
from scripts.deploy_and_pull import deploy, deployMock, fundWithLink, approveToken, pull
from brownie import (
    network,
    config,
)


from web3 import Web3
import pytest

# For global marker
pytestmark = [pytest.mark.require_network("mainnet-fork")]

# deploy erc-20 and mint to account
def token(ERC20Token):
    account = get_account(index=-2)
    token = account.deploy(ERC20Token, Web3.toWei(1000, "ether"))
    return token


# module wide deploy and mock.
@pytest.fixture(scope="module", autouse=True)
def default_deploy_and_mock(VRFCoordinatorMock, RussianRoulette, interface):
    account = get_account(index=-2)
    mockVRF = deployMock(account, VRFCoordinatorMock)

    RR = deploy(
        account,
        RussianRoulette,
        mockVRF.address,
        config["networks"][network.show_active()]["link"],
        config["networks"][network.show_active()]["keyhash"],
        Web3.toWei(config["networks"][network.show_active()]["fee"], "ether"),
    )

    txFund = fundWithLink(
        account,
        RR,
        Web3.toWei(config["networks"][network.show_active()]["fee"], "ether"),
    )

    DAI = config["networks"][network.show_active()]["dai"]
    amount = Web3.toWei(config["networks"][network.show_active()]["amount_in"], "ether")
    token_contract = interface.IERC20(DAI)

    txApprove = approveToken(account, DAI, RR.address, amount)

    starting_token_balance = Web3.fromWei(
        token_contract.balanceOf(account.address), "ether"
    )

    return account, mockVRF, RR, DAI, amount, token_contract, starting_token_balance


@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass


# test a random number that is divisible by 6. User should lose amount in, contract should burn amount in.
# mainnet-fork with index=-2 unlocked
# tested token is DAI
# @pytest.mark.require_network("mainnet-fork")
@pytest.mark.parametrize("RNG", [600, 601])
def test_positive_pull(default_deploy_and_mock, RNG):
    # Arrange

    (
        account,
        mockVRF,
        RR,
        DAI,
        amount,
        token_contract,
        starting_token_balance,
    ) = default_deploy_and_mock

    # Act
    txPull = pull(account, RR, amount, DAI)
    # STATIC_RNG = 601
    request_id = txPull.events["RequestRandomness"]["requestId"]

    # Assert contract balance == amount in. Assert user balance is amount in less.
    assert (
        Web3.fromWei(token_contract.balanceOf(RR.address), "ether")
        == config["networks"][network.show_active()]["amount_in"]
    )
    assert (
        starting_token_balance
        - Web3.fromWei(token_contract.balanceOf(account.address), "ether")
    ) == config["networks"][network.show_active()]["amount_in"]

    # can mock since vrfCoordinator is the only address that can call rawFullfillRandomness
    # mockVRF is deployed before RR, so mockVRF address can be input for RR constructor
    txRNG = mockVRF.callBackWithRandomness(
        request_id, RNG, RR.address, {"from": account}
    )

    txRNG.wait(1)

    # Assert contract balance is 0, token returned. Assert user balance == starting balance, tokens returned.
    if RNG % 6 != 0:
        assert Web3.fromWei(token_contract.balanceOf(RR.address), "ether") == 0
        assert (
            Web3.fromWei(token_contract.balanceOf(account.address), "ether")
            == starting_token_balance
        )

    # Assert contract balance is 0, token burned. Assert user balance == starting balance less amount in.
    else:
        assert Web3.fromWei(token_contract.balanceOf(RR.address), "ether") == 0
        assert (
            starting_token_balance
            - Web3.fromWei(token_contract.balanceOf(account.address), "ether")
        ) == config["networks"][network.show_active()]["amount_in"]


# test the fn_isolation works
def test_transfer(accounts):
    starting_balance = accounts[1].balance()
    accounts[0].transfer(accounts[1], "10 ether")
    assert (accounts[1].balance() - starting_balance) == Web3.toWei(10, "ether")


def test_chain_reverted(accounts):
    assert accounts[0].balance() == accounts[1].balance()
