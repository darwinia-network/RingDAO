// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Script, console2} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";

import {DAO, DAOFactory} from "@aragon/osx/framework/dao/DAOFactory.sol";
import {PluginRepoFactory} from "@aragon/osx/framework/plugin/repo/PluginRepoFactory.sol";
import {PluginRepo} from "@aragon/osx/framework/plugin/repo/PluginRepo.sol";
import {hashHelpers, PluginSetupRef} from "@aragon/osx/framework/plugin/setup/PluginSetupProcessorHelpers.sol";
import {MajorityVotingBase} from "@aragon/osx/plugins/governance/majority-voting/MajorityVotingBase.sol";

import {MultisigPluginSetup, Multisig} from "../src/plugins/multisig/MultisigPluginSetup.sol";
import {TokenVotingPluginSetup} from "../src/plugins/token-voting/TokenVotingPluginSetup.sol";
import {
    OptimisticTokenVotingPluginSetup,
    OptimisticTokenVotingPlugin
} from "../src/plugins/optimistic-token-voting/OptimisticTokenVotingPluginSetup.sol";

contract Deploy is Script {
    address gRING = 0x87BD07263D0Ed5687407B80FEB16F2E32C2BA44f;
    address multisigPlugin = 0x005D4B92F66dB792b375c274550b11BE41BD93eB;
    address maintainer = 0x0f14341A7f464320319025540E8Fe48Ad0fe5aec;

    address pluginRepoFactory;
    DAOFactory daoFactory;
    address[] pluginAddress;

    MultisigPluginSetup multisigPluginSetup;
    TokenVotingPluginSetup tokenVotingPluginSetup;
    OptimisticTokenVotingPluginSetup optimisticTokenVotingPluginSetup;

    PluginRepo multisigPluginRepo;
    PluginRepo tokenVotingPluginRepo;
    PluginRepo optimisticTokenVotingPluginRepo;

    DAO ringDAO;

    function setUp() public {
        pluginRepoFactory = vm.envAddress("PLUGIN_REPO_FACTORY");
        daoFactory = DAOFactory(vm.envAddress("DAO_FACTORY"));
    }

    function run() public {
        vm.startBroadcast();

        console2.log("Chain ID:", block.chainid);
        console2.log("Deploying from:", msg.sender);

        // 1. Deploying the Plugin Setup
        deployPluginSetup();

        // 2. Publishing it in the Aragon OSx Protocol
        deployPluginRepo();

        // 3. Defining the DAO Settings
        DAOFactory.DAOSettings memory daoSettings = getDAOSettings();

        // 4. Defining the plugin settings
        DAOFactory.PluginSettings[] memory pluginSettings = getPluginSettings();

        // 5. Deploying the DAO
        vm.recordLogs();
        ringDAO = daoFactory.createDao(daoSettings, pluginSettings);

        // 6. Getting the Plugin Address
        Vm.Log[] memory logEntries = vm.getRecordedLogs();

        for (uint256 i = 0; i < logEntries.length; i++) {
            if (logEntries[i].topics[0] == keccak256("InstallationApplied(address,address,bytes32,bytes32)")) {
                pluginAddress.push(address(uint160(uint256(logEntries[i].topics[2]))));
            }
        }

        vm.stopBroadcast();

        // 7. Logging the resulting addresses
        console2.log("Multisig Plugin Setup: ", address(multisigPluginSetup));
        console2.log("TokenVoting Plugin Setup: ", address(tokenVotingPluginSetup));
        console2.log("OptimisticTokenVoting Plugin Setup: ", address(optimisticTokenVotingPluginSetup));
        console2.log("Multisig Plugin Repo: ", address(multisigPluginRepo));
        console2.log("TokenVoting Plugin Repo: ", address(tokenVotingPluginRepo));
        console2.log("OptimisticTokenVoting Plugin Repo: ", address(optimisticTokenVotingPluginRepo));
        console2.log("Ring DAO: ", address(ringDAO));
        console2.log("Installed Plugins: ");
        for (uint256 i = 0; i < pluginAddress.length; i++) {
            console2.log("- ", pluginAddress[i]);
        }
    }

    function deployPluginSetup() public {
        multisigPluginSetup = new MultisigPluginSetup();
        tokenVotingPluginSetup = new TokenVotingPluginSetup();
        optimisticTokenVotingPluginSetup = new OptimisticTokenVotingPluginSetup();
    }

    function deployPluginRepo() public {
        multisigPluginRepo = PluginRepoFactory(pluginRepoFactory).createPluginRepoWithFirstVersion(
            string.concat("ringdao-multisig-", vm.toString(block.timestamp)),
            address(multisigPluginSetup),
            msg.sender,
            hex"12", // TODO: Give these actual values on prod
            hex"34"
        );

        tokenVotingPluginRepo = PluginRepoFactory(pluginRepoFactory).createPluginRepoWithFirstVersion(
            string.concat("ringdao-token-voting-", vm.toString(block.timestamp)),
            address(tokenVotingPluginSetup),
            msg.sender,
            hex"12", // TODO: Give these actual values on prod
            hex"34"
        );

        optimisticTokenVotingPluginRepo = PluginRepoFactory(pluginRepoFactory).createPluginRepoWithFirstVersion(
            string.concat("ringdao-optimistic-token-voting-", vm.toString(block.timestamp)),
            address(optimisticTokenVotingPluginSetup),
            msg.sender,
            hex"12", // TODO: Give these actual values on prod
            hex"34"
        );
    }

    function getDAOSettings() public view returns (DAOFactory.DAOSettings memory) {
        return DAOFactory.DAOSettings(address(0), "", string.concat("governance-", vm.toString(block.timestamp)), "");
    }

    function getPluginSettings() public view returns (DAOFactory.PluginSettings[] memory pluginSettings) {
        pluginSettings = new DAOFactory.PluginSettings[](3);
        pluginSettings[0] = getMultisigPluginSetting();
        pluginSettings[1] = getTokenVotingPluginSetting();
        pluginSettings[2] = getOptimisticTokenVotingPluginSetting();
    }

    function getMultisigPluginSetting() public view returns (DAOFactory.PluginSettings memory) {
        address[] memory members = new address[](1);
        members[0] = maintainer;
        bytes memory pluginSettingsData = abi.encode(
            members,
            Multisig.MultisigSettings({onlyListed: true, minApprovals: 1, destinationProposalDuration: 60 minutes})
        );
        PluginRepo.Tag memory tag = PluginRepo.Tag(1, 1);
        return DAOFactory.PluginSettings(PluginSetupRef(tag, multisigPluginRepo), pluginSettingsData);
    }

    function getTokenVotingPluginSetting() public view returns (DAOFactory.PluginSettings memory) {
        bytes memory pluginSettingsData = abi.encode(
            MajorityVotingBase.VotingSettings({
                votingMode: MajorityVotingBase.VotingMode.Standard,
                supportThreshold: 500_000, // 50%
                minParticipation: 1, // 0.0001%
                minDuration: 60 minutes,
                minProposerVotingPower: 1e18
            }),
            TokenVotingPluginSetup.TokenSettings({addr: gRING, underlyingTotalSupply: 1_000_000_000e18})
        );
        PluginRepo.Tag memory tag = PluginRepo.Tag(1, 1);
        return DAOFactory.PluginSettings(PluginSetupRef(tag, tokenVotingPluginRepo), pluginSettingsData);
    }

    function getOptimisticTokenVotingPluginSetting() public view returns (DAOFactory.PluginSettings memory) {
        address[] memory proposers = new address[](1);
        proposers[0] = multisigPlugin;
        bytes memory pluginSettingsData = abi.encode(
            OptimisticTokenVotingPlugin.OptimisticGovernanceSettings({
                minVetoRatio: 500_000, // 50%
                minDuration: 60 minutes
            }),
            OptimisticTokenVotingPluginSetup.TokenSettings({addr: gRING, underlyingTotalSupply: 1_000_000_000e18}),
            proposers
        );
        PluginRepo.Tag memory tag = PluginRepo.Tag(1, 1);
        return DAOFactory.PluginSettings(PluginSetupRef(tag, optimisticTokenVotingPluginRepo), pluginSettingsData);
    }
}
