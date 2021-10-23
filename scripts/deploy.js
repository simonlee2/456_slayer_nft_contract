const names = [
    "Circle",
    "Triangle",
    "Square",
];
const imgs = [
    "https://i.ibb.co/bFX7B6C/circle.jpg",
    "https://i.ibb.co/2WhwZJV/triangle-worker.jpg",
    "https://i.ibb.co/hFRDG70/E-m-Js7-EXs-AAv-Mc-A-134e338.jpg"
];
const hp = [
    100,
    200,
    300,
]
const attack = [
    10,
    30,
    20,
]

const boss = {
    name: "456",
    imageURI: "https://i.ibb.co/tZVF24v/456.jpg",
    hp: 1000,
    attack: 20
}

const main = async () => {
    const gameContractFactory = await hre.ethers.getContractFactory('MyEpicGame');
    const gameContract = await gameContractFactory.deploy(
        names,
        imgs,
        hp,
        attack,
        boss.name,
        boss.imageURI,
        boss.hp,
        boss.attack
    );
    await gameContract.deployed();
    console.log(`Contract deployed to: ${gameContract.address}`);
};

const runMain = async () => {
    try {
        await main()
        process.exit(0);
    } catch (error) {
        console.log(error);
        process.exit(1);
    }
};

runMain();