const { ethers } = require("hardhat");
const config = require('../config/testnet/config.js');
const delay = ms => new Promise(res => setTimeout(res, ms));

async function main() {
    const [admin] = await ethers.getSigners();
    console.log("Admin account:", admin.address);
    console.log("Account balance:", (await admin.getBalance()).toString());

    //  Deploy Governance contract
    console.log('Deploy Governance Contract .........');
    const GOV = await ethers.getContractFactory('Governance', admin);
    const gov = await GOV.deploy(config.treasury, config.payments);

    console.log('Governance Contract: ', gov.address);

    delay(12000);

    //  Set MANAGER_ROLE
    let roleManager = await gov.MANAGER_ROLE();
    await gov.connect(admin).grantRole(roleManager, admin.address);
    console.log('Grant MANAGER_ROLE completed');

    //  Deploy Archive contract
    console.log('Deploy Archive Contract .........');
    const Archive = await ethers.getContractFactory('Archive', admin);
    const archive = await Archive.deploy(gov.address);

    console.log('Archive Contract: ', archive.address);

    //  Deploy Marketplace contract
    console.log('Deploy Marketplace Contract .........');
    const Marketplace = await ethers.getContractFactory('Marketplace', admin);
    const market = await Marketplace.deploy(gov.address, archive.address);

    console.log('Marketplace Contract: ', market.address);

    //  Deploy AirDropV2 contract
    console.log('Deploy AirDropV2 Contract .........');
    const AirDropV2 = await ethers.getContractFactory('AirDropV2', admin);
    const drop = await AirDropV2.deploy(gov.address);

    console.log('AirDropV2 Contract: ', drop.address);

    //  Deploy MetaFarm contract
    const baseURI = 'https://api.mymetafarm.com/items/';
    console.log('Deploy MetaFarm Contract .........');
    const MetaFarm = await ethers.getContractFactory('MetaFarm1155', admin);
    const farm = await MetaFarm.deploy(gov.address, baseURI);

    console.log('MetaFarm Contract: ', farm.address);

    delay(5000);

    //  Set Commission Fee rate
    console.log('Set Commission Fee Rate');
    const rate = 100;           // commission fee = 1% = 100 / 10,000
    await gov.connect(admin).setCommissionFee(rate);
    console.log('Done');

    //  Register MetaFarm contract
    console.log('Register MetaFarm contract');
    await gov.connect(admin).registerNFT(farm.address);
    console.log('Done');
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });