// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC1155 is IERC165 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

contract ERC1155 is IERC1155 {
    //address => tokenId => amount
    mapping(address => mapping(uint256 => uint256)) public balances;
    //real owner => account => is allowed to spend owners balance? yes | no
    mapping(address => mapping(address => bool)) public approvals;

    function balanceOf(address account, uint256 id)
        public
        view
        override
        returns (uint256)
    {
        return balances[account][id];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "The length of ids needs to be equal to length of ammounts"
        );
        uint256[] memory balances = new uint256[](accounts.length);
        for (uint256 i = 0; i <= accounts.length; i++) {
            balances[i] = balanceOf(accounts[i], ids[i]);
        }
        return balances;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        approvals[msg.sender][operator] = approved;
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        override
        returns (bool)
    {
        return approvals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public override {
        require(to != address(0), "You can't make a transfer to address 0");
        require(
            from == msg.sender || approvals[from][msg.sender] == true,
            "Your balance is insufficient"
        );
        require(balances[from][id] >= amount);
        balances[from][id] -= amount;
        balances[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);
        if (isContract(to)) {
            //do something
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override {
        require(to != address(0), "You can't make a transfer to address 0");
        require(
            ids.length == amounts.length,
            "The length of ids needs to be equal to length of ammounts"
        );
        for (uint256 i = 0; i <= ids.length; i++) {
            require(
                msg.sender == from || approvals[from][msg.sender] == true,
                "You are not allowed to do this!"
            );
            require(
                balances[from][ids[i]] >= amounts[i],
                "Your balance is insufficient!"
            );
            balances[from][ids[i]] -= amounts[i];
            balances[to][ids[i]] += amounts[i];
        }
        emit TransferBatch(msg.sender, from, to, ids, amounts);
    }

    function isContract(address _address) private returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
}
