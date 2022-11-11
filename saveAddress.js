const path = require('path');
const fs = require('fs');

const addressesPath = 'addresses.json';

const addresses = require(path.join(__dirname, addressesPath));
const [network, contract, address] = process.argv.slice(2);
addresses[network][contract] = address;

fs.writeFileSync(path.join(__dirname, addressesPath), JSON.stringify(addresses, null, 2));
console.log('Updated `addresses.json`');
