// The 'flipflap' program.
program flipflap.aleo {
    mapping is_voted: Voted => bool;
    mapping nodes: field => Node;
    mapping node_exist: field => bool;
    mapping node_votes: field => u32;

    record Vote {
        owner: address,
        gates: u64,
        sender: address,
        node_id: field,
        mov: u8,
    }

    struct Voted {
        voter: address,
        node_id: field,
    }

    struct Node {
        node_id: field,
        state: u128,
        parent_id: field,
        node_type: u8,
        game_status: u8,
    }

    inline get_contract_onwer () -> address {
        return aleo1gq3kd85wran4xhfh7hvnxkgee9wxq0vpg7r43tf6t3cafhqnkqrs76ssf0;
    }

    transition move_to_next (node_id: field, new_state: u128, valid_pos: u32, game_status: u8) {
        return then finalize(node_id, new_state, valid_pos, game_status);
    }

    finalize move_to_next (node_id: field, new_state: u128, valid_pos: u32, game_status: u8) {
        // check if is owner
        assert_eq(self.caller, get_contract_onwer());

        // check if is exist
        let is_exist: bool = Mapping::get_or_init(node_exist, node_id, false);
        assert_eq(is_exist, true);

        // check if is enough votes to move
        let votes: u32 = Mapping::get_or_init(node_votes, node_id, 0u32);
        let valid_cnt: u32 = valid_pos / 2u32;
        let is_enough: bool = votes >= valid_cnt;
        assert(is_enough);

        let parent: Node = Mapping::get(nodes, node_id);

        // update node
        let new_parent: Node = Node {
            node_id: parent.node_id,
            state: parent.state,
            parent_id: parent.parent_id,
            node_type: 1u8, // to simple node
            game_status: game_status,
        };
        Mapping::set(nodes, node_id, new_parent);

        // create new node
        let son: Node = Node {
            node_id: BHP512::hash(node_id),
            state: new_state,
            parent_id: node_id,
            node_type: 2u8, // to leaf node
            game_status: game_status,
        };
        Mapping::set(nodes, son.node_id, son);
        Mapping::set(node_exist, son.node_id, true);
    }

    transition open_game (start_id: field) {
        return then finalize(start_id);
    }

    finalize open_game (start_id: field) {
        // check if is owner
        assert_eq(self.caller, get_contract_onwer());

        // check if is exist
        let is_exist: bool = Mapping::get_or_init(node_exist, start_id, false);
        assert_eq(is_exist, false);

        let node: Node = Node {
            node_id: start_id,
            state: 7083711853891053158400u128,
            parent_id: BHP512::hash(get_contract_onwer()),
            node_type: 0u8,
            game_status: 0u8,
        };
        Mapping::set(nodes, start_id, node);
    }

    // Client Operations
    transition vote (node_id: field, mov: u8) -> Vote {
        let caller_vote: Vote = Vote {
            owner: get_contract_onwer(),
            gates: 0u64,
            sender: self.caller,
            node_id: node_id,
            mov: mov,
        };
        return caller_vote then finalize(node_id, mov);
    }

    finalize vote (node_id: field, mov: u8) {
        // check if is exist
        let is_exist: bool = Mapping::get_or_init(node_exist, node_id, false);
        assert_eq(is_exist, true);

        // check if is voted
        let voted: Voted = Voted {
            voter: self.caller,
            node_id: node_id,
        };
        let is_vote: bool = Mapping::get_or_init(is_voted, voted, false);
        assert_eq(is_vote, false);

        // check is valid
        let node: Node = Mapping::get(nodes, node_id);
        let is_valid: bool = mov <= 63u8;
        let square: u128 = node.state.shr(mov * 2u8);
        let square_mod: u128 = square & 3u128;
        assert_eq(is_valid, true);
        assert_eq(square_mod, 0u128);


        Mapping::set(is_voted, voted, true);
        let votes: u32 = Mapping::get_or_init(node_votes, node_id, 0u32);
        Mapping::set(node_votes, node_id, votes + 1u32);
    }
}
