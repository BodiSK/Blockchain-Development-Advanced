const { hashMessage, Wallet } = require("ethers");

task("sign45").setAction(async (taskArgs, { ethers }) => {
    const [signer] = await ethers.getSigners();

    const message = "Hello, world";
    
    const hashbytes = ethers.getBytes(
        ethers.keccak256(ethers.toUtf8Bytes(message))
    );
    const signature = await signer.signMessage(hashbytes);
    const signObj = ethers.Signature.from(signature);

    const factory = await ethers.getContractFactory("EIP191v45");
    const contract = await factory.deploy();
    await contract.waitForDeployment();

    const result = await contract.verifySignature(message, signObj.v, signObj.r, signObj.s);

    console.log("Recovered ", result);
    console.log("Signer ", signer.address);

    const messageHash = hashMessage(hashbytes);
    const recoveredAddress = ethers.recoverAddress(messageHash, signObj);
    console.log("Recovered Address ", recoveredAddress);    
    console.log("Signer Address ", signer.address);


  });



  task("sign712").setAction(async (taskArgs, { ethers }) => {
    const [signer] = await ethers.getSigners();

    const contractFactory = await ethers.getContractFactory("EIP712Verifier");
    const contract = await contractFactory.deploy();
    await contract.waitForDeployment();

    const contractAddress = await contract.getAddress();
    const operator = "0xC4973de5eE925b8219f1E74559FB217A8e355EcF";
    const value = ethers.parseEther("0.1");
    const chainId= await ethers.provider.getNetwork().then((network) => network.chainId);
    console.log("Chain ID ", chainId);

    const domain = {
        name: "EIP712Verifier",
        version: "1",
        chainId: chainId,
        verifyingContract: contractAddress,
    }

    const types ={
        Verification: [
            { name: "owner", type: "address"},
            { name: "operator", type: "address" },
            { name: "value", type: "uint256" },
        ]
    }

    const values ={
        owner: signer.address,
        operator,
        value,
    }

    const signature = await signer.signTypedData(domain, types, values);
    const signObj = ethers.Signature.from(signature);

    const result = await contract.verify(signer.address, operator, value, signObj.v, signObj.r, signObj.s);
    console.log("Verification result ", result);
  });