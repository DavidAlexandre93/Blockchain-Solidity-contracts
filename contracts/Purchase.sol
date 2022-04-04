pragma solidity >=0.4.22 <0.9.0;

contract Purchase {
    uint public value;
    address public seller;
    address public buyer;
    enum State { Created, Locked, Inactive }
    State public state;

    // Garantir que 'msg.value' é um número par.
    // Divisão será truncada se for um número impar.
    // Verificar via multiplicação que não é um número impar.

    function Purchase() payable {
        seller = msg.sender;
        value = msg.value / 2;
        require((2 * value) == msg.value);
    }

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer);
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller);
        _;
    }

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();

    /// Abortar a compra e reinvindicar os ether.
    /// Pode somente ser chamado pelo vendedor antes
    /// do contrato ser travado.

    function abort()
        onlySeller
        inState(State.Created)
    {
        Aborted();
        state = State.Inactive;
        seller.transfer(this.balance);
    }

    /// Confirme a compra como comprador.
    /// Transação tem que incluir '2 * valor' ether.
    /// Os ether ficarão presos até a função confirmReceived
    /// for chamada.

    function confirmPurchase()
        inState(State.Created)
        condition(msg.value == (2 * value))
        payable
    {
        PurchaseConfirmed();
        buyer = msg.sender;
        state = State.Locked;
    }

    /// Confirmar que você (o comprador) recebeu o item.
    /// Isto irá liberar os ether presos.

    function confirmReceived()
        onlyBuyer
        inState(State.Locked)
    {
        ItemReceived();
        // É importante mudar o estado primeiro porque
        // de outra forma, o contrato chamado usando 'send'
        // abaixo pode chamar novamente aqui.

        state = State.Inactive;

        // NOTA: Isto efetivamente permite o comprador e o vendedor
        // bloquear a restituição - a retirada padrão deve ser usada.

        buyer.transfer(value);
        seller.transfer(this.balance);
    }çp~´
}