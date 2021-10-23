// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// NFT contract to inherit from.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

// We need to import the helper functions from the contract that we copy/pasted.
import { Base64 } from "./libraries/Base64.sol";

contract MyEpicGame is ERC721 {
    struct CharacterAttributes {
        uint characterIndex;
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint attackDamage;
    }

    // counters to keep track of token Ids
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // our list of characters
    CharacterAttributes[] defaultCharacters;
    CharacterAttributes boss;

    // We create a mapping from the nft's tokenId => that NFTs attributes.
    mapping(uint256 => CharacterAttributes) public nftHolderAttributes;

    // A mapping from an address => the NFTs tokenId. Gives me an ez way
    // to store the owner of the NFT and reference it later.
    mapping(address => uint256) public nftHolders;

    // Events to know when actions are complete
    event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
    event AttackComplete(uint newBossHp, uint newPlayerHp);

    constructor(
        string[] memory characterNames,
        string[] memory characterImageURIs,
        uint[] memory characterHp,
        uint[] memory characterAttackDamage,
        string memory bossName,
        string memory bossImageURI,
        uint bossHp,
        uint bossAttackDamage


    ) ERC721("Squid Games", "SQDG") {
        boss = CharacterAttributes({
            characterIndex: 456,
            name: bossName,
            imageURI: bossImageURI,
            hp: bossHp,
            maxHp: bossHp,
            attackDamage: bossAttackDamage
        });

        console.log("Done initializing boss %s w/ HP %s, img %s", boss.name, boss.hp, boss.imageURI);


        for (uint i=0; i < characterNames.length; i++) {
            defaultCharacters.push(
                CharacterAttributes({
                    characterIndex: i,
                    name: characterNames[i],
                    imageURI: characterImageURIs[i],
                    hp: characterHp[i],
                    maxHp: characterHp[i],
                    attackDamage: characterAttackDamage[i]
                })
            );

            CharacterAttributes memory c = defaultCharacters[i];
            console.log("Done initializting %s w/ HP %s, img %s", c.name, c.maxHp, c.imageURI);
        }

        // I increment tokenIds here so that my first NFT has an ID of 1.
        _tokenIds.increment();
    }

    // Users would be able to hit this function and get their NFT based on the
    // characterId they send in!
    function mintCharacterNFT(uint _characterIndex) external {
        // Get current tokenId (starts at 1 since we incremented in the constructor).
        uint256 newItemId = _tokenIds.current();

        // The magical function! Assigns the tokenId to the caller's wallet address.
        _safeMint(msg.sender, newItemId);

        // We map the tokenId => their character attributes. More on this in
        // the lesson below.
        nftHolderAttributes[newItemId] = CharacterAttributes({
            characterIndex: _characterIndex,
            name: defaultCharacters[_characterIndex].name,
            imageURI: defaultCharacters[_characterIndex].imageURI,
            hp: defaultCharacters[_characterIndex].hp,
            maxHp: defaultCharacters[_characterIndex].hp,
            attackDamage: defaultCharacters[_characterIndex].attackDamage
        });

        console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _characterIndex);
        console.log("TokenURI: %s", tokenURI(newItemId));
        
        // Keep an easy way to see who owns what NFT.
        nftHolders[msg.sender] = newItemId;

        // Increment the tokenId for the next person that uses it.
        _tokenIds.increment();

        // emit event
        emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

        // convert everything to strings
        string memory hpStr = Strings.toString(charAttributes.hp);
        string memory maxHpStr = Strings.toString(charAttributes.maxHp);
        string memory atkStr = Strings.toString(charAttributes.attackDamage);

        // construct json string
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        charAttributes.name,
                        ' #',
                        Strings.toString(_tokenId),
                        '", "description": "This is an NFT that lets people play as the worker in the Squid Game", "image": "',
                        charAttributes.imageURI,
                        '", "attributes": [ { "trait_type": "Health Points", "value": ',hpStr,', "max_value":',maxHpStr,'}, { "trait_type": "Attack Damage", "value": ',
                        atkStr,'} ]}'
                    )
                )
            )
        );

        // pack the json data to acceptable URI
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function attackBoss() public {
        // Get the state of the player's NFT.
        uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
        CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];
        console.log("\nPlayer w/ character %s about to attack. Has %s HP and %s AD", player.name, player.hp, player.attackDamage);
        console.log("Boss %s has %s HP and %s AD", boss.name, boss.hp, boss.attackDamage);

        // Make sure the player has more than 0 HP.
        require(
            player.hp > 0,
            "Error: character must have HP to attack boss"
        );

        // Make sure the boss has more than 0 HP.
        require(
            boss.hp > 0,
            "Error: boss must have HP to be attacked"
        );

        // Allow player to attack boss.
        if (boss.hp < player.attackDamage) {
            // Since we're using uint, this avoid underflow
            // and sets the hp to 0 if it would have become 
            // negative
            boss.hp = 0;
        } else {
            boss.hp = boss.hp - player.attackDamage;
        }
        console.log("Player attaced boss. New boss hp: %s\n", boss.hp);

        // Allow boss to attack player.
        if (player.hp < boss.attackDamage) {
            player.hp = 0;
        } else {
            player.hp = player.hp - boss.attackDamage;
        }

        // End of round
        emit AttackComplete(boss.hp, player.hp);
        console.log("Boss attacked player. New player hp: %s\n", player.hp);
    }

    function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
        // Get the tokenId of the user's character NFT
        uint256 userNftTokenId = nftHolders[msg.sender];
        // If the user has a tokenId in the map, return thier character.
        if (userNftTokenId > 0) {
            return nftHolderAttributes[userNftTokenId];
        }
        // Else, return an empty character.
        else {
            CharacterAttributes memory emptyStruct;
            return emptyStruct;
        }
    }

    function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
        return defaultCharacters;
    }

    function getBigBoss() public view returns (CharacterAttributes memory) {
        return boss;
    }
}