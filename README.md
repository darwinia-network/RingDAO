# <h1 align="center"> RingDAO </h1>

## Koi
```
  Delegation Wall:  0x0980Bf75a38e8367B479c363432d1E91C6414727
  TokenVoting Plugin Setup:  0x73b3B8d450a3155feD62A74622b6E9139874CD1d
  TokenVoting Plugin Repo:  0x4c0729D8eB9B36F2040B8D0aE1F51B15B0D7BdF0
  Ring DAO:  0x005493b5658e6201F06FE2adF492610635505F4C
  Installed Plugins:
  -  0x1756B204a72e1B879D9C63b47f31640a57b8c727
```

## Crab
```
  Delegation Wall:  0x7479798bD9A2972afB4Da5FF9f88bd18Daf546a1
  Delegation Announcer:  0x05FFdA9C7FD9E30e49e420b0AA6c1772f94e83A7
  TokenVoting Plugin Setup:  0x879BD4Ca5158cE3b1Fc419D4e7789503923F3d76
  TokenVoting Plugin Repo:  0x5eB66e31b5Bf40D074aB149643E69ca3fee4Fb7A
  CrabDAO:  0x663fC3000f0101BF16FDc9F73F02DA6Efa8c5875
  Installed Plugins:
  -  0xFF335B8aF2B601d09A499199705Ed3E7bdADa66E
```

## Token Voting plugin

This plugin is an adapted version of Aragon's [Token Voting plugin](https://github.com/aragon/osx/tree/v1.3.0/packages/contracts/src/plugins/governance/majority-voting/token). 

Only community members(who owns enough tokens or has enough voting power from being a delegatee) can create proposals. 

Proposals can only be executed when the support threshold and minimum participation have been reached after a minimum period of time.

The governance settings need to be defined when the plugin is installed but the DAO can update them at any time.

### Permissions

- Only community members can create proposals on the plugin
- The plugin can execute actions on the DAO
- The DAO can update the plugin settings
- The DAO can upgrade the plugin

## DO's and DONT's

- Never grant `ROOT_PERMISSION` unless you are just trying things out
- Never uninstall all plugins, as this would brick your DAO
- Ensure that there is at least always one plugin with `EXECUTE_PERMISSION` on the DAO
- Ensure that the DAO is ROOT on itself
- Use the `_gap[]` variable for upgradeable plugins, as a way to reserve storage slots for future plugin implementations
  - Decrement the `_gap` number for every new variable (slot) you add in the future
