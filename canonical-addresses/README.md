# Why this?

On production, the CrunaGuardian is deployed with parameters different than on localhost during tests. That causes that the canonical address of the CrunaGuardian is incompatible. To solve the issue, during tests we use a specific CanonicalAddresses.sol file, while publishing the package we use the original one.

Notice that only this repo must test setTrustedImplementation, i.e., need to manage the CrunaGuardian. Any implementer of the protocol, during dev and tests, can plug untrusted plugins.