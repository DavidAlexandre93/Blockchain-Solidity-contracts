pragma solidity >=0.4.22 <0.9.0;

    /// @title Votação com delegação.
contract Ballot {
    // Aqui é declarado um novo tipo complexo que será
            // usado pelas variáveis mais tarde.
            // Represntará um votante único.

    struct Voter {
        uint weight; // peso é acumulado por delegação // weight is accumulated by delegation
        bool voted;  // se for verdadeiro, aquela pessoa já votou // if true, that person already voted
        address delegate; // pessoa a quem será delegado // person delegated to
        uint vote;   // índice do voto proposto // index of the voted proposal
    }

    // Este é um tipo de proposta única

            struct Proposal {
        bytes32 name;   // nome curto (até 32 bytes) // short name (up to 32 bytes)
        uint voteCount; // número de votos acumulados // number of accumulated votes
    }

            address public chairperson;

    // Aqui é declarada a variável de estado que
    // armazena uma estrutura de "Votante" para cada possível endereço.

    mapping(address => Voter) public voters;

            // Uma estrutura de "Proposta" tipo array dinamicamente dimensionada.

    Proposal[] public proposals;

    /// Criar uma nova cédula para escolher uma das "proposalNames".

            function Ballot(bytes32[] proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        // Para cada nome de proposta, criar um novo
        // objeto proposta e adicione este objeto ao
        // fim do array.

        for (uint i = 0; i < proposalNames.length; i++) {

            // "Proposal({...})" cria um objeto temporário
            // e "proposal.push(...)" adiciona este objeto
            // ao fim das "propostas"

            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // Dar ao "votante"  o direito de voto nesta cédula.
    // Pode somente ser chamada pelo "Presidente".

    function giveRightToVote(address voter) {

        // Se o argumento de "require" for determinado como "false",
        // é terminado e todas alterações são revertidas assim
        // como o saldo de Ether retorna ao valor antes da operação.
        // É normalmente uma boa ideia usar isto se funções são
        // chamadas incorretamente. Mas fique atento, isso pode
        // também consumir todo o "gas" disponível.
        // (está planejado para ser mudado no futuro).

        require((msg.sender == chairperson) && !voters[voter].voted && (voters[voter].weight == 0));
        voters[voter].weight = 1;
    }

            /// Delegar seu voto ao votante "to".

    function delegate(address to) {
                    // atribuir referência

        Voter storage sender = voters[msg.sender];
        require(!sender.voted);

                    // Auto-delegação não é permitida.

        require(to != msg.sender);

                    // Encaminhar a atribuição desde que "to" também seja atribuido.

        // Em geral, estes tipos de loops são muito perigosos,
                    // porque se demorarem muito tempo executando, podem
                    // causar necessidade de mais "gas" do que é disponível
                    // para o bloco.
                    // Neste caso, a atribuição não será executada, mas,
                    // em outras situações, estes loops podem causar o
                    // "travamento" completo do contrato.

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // Se encontramos um loop na atribuição, não permitido.

                            // We found a loop in the delegation, not allowed.
            require(to != msg.sender);
        }

        // Desde que "sender" é uma referência, este
                    // modifica "voters[msg.sender].voted"

                    sender.voted = true;
        sender.delegate = to;
        Voter storage delegate = voters[to];
        if (delegate.voted) {
            // Se o atribuido já votou,
                            // some diretamente no número de votos.

                        proposals[delegate.vote].voteCount += sender.weight;
        } else {
            // Se o atribuido ainda não votou,
                            // some ao seu peso.

                        delegate.weight += sender.weight;
        }
    }

    /// Dê o seu voto (incluindo votos atribuidos a você)
            /// a proposta "proposals[proposal].name".

            function vote(uint proposal) {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted);
        sender.voted = true;
        sender.vote = proposal;

                    // Se "proposal" está fora do range do array,
                    // será rejeitada automaticamente e todas as
                    // alterações revertidas.

        proposals[proposal].voteCount += sender.weight;
    }

    /// @dev calcula a proposta vencedora levando todos
            /// os votos prévios em consideração.

            function winningProposal() constant
            returns (uint winningProposal)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal = p;
            }
        }
    }

    /// Chama a função "winningProposal()" para selecionar
            /// o indíce do vencedor contido no array de propostas e
            /// então retorna o nome do vencedor.

            function winnerName() constant
            returns (bytes32 winnerName)
    {
        winnerName = proposals[winningProposal()].name;
    }
}