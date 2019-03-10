A trustless and automatic delivery contract to be ran on Etheurem. 2 parties can enter into a delivery contract whose payment will be attached to the proper delivery of a certain good (on which an IoT sensor transmit GPS coordinates), in case of delay penalties start to kick in.

Values created:
- both parties: trustless contract detail execution without central monitoring (cheaper coordination costs)
- the provider: if reliable, demonstrable sales strongpoint to prospects

Next steps:

- add a front-end interface for 2 parties to enter into a agreement and track the progress of the delivery
- write a script that can be run by a pilot IoT tracker to connect with the contract
- make the contract more generic so that it can cover a wider range of deliveries and computed penalty scores. Examples include main door or temperature level of containers as well as any other IoT based measurable data. Automatically generated data by third parties like custom filing could also factor in.


How to run locally the contract:
- get truffle framework
- truffle develop
- migrate
- to list accounts truffle created locally:
  let accounts = web3.eth.getAccounts()
- to get a JS proxy object to the contract:
  let instance = DeliveryContract.deployed()
- then function creation does work...

Alternatively, use remix. Easier.
