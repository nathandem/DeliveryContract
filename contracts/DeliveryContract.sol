pragma solidity >=0.4.25 <0.6.0;

/*
** Trustless and automatic delivery contract to be run on Etheurem.
**
** Use cases/values:
** - both parties: trustless contract detail execution without central monitoring (cheaper coordination costs)
** - the provider: if reliable, demonstrable sales strongpoint to prospects
**
** Could be extended by making it more generic so the contract could cover a wider
** variety of deliveries. Examples include main door or temperature level of containers
** as well as any other IoT based measurable data. Automatically generated data by third
** parties like custom filing could also factor in the cost reduction.
*/

contract GeoHelpers {
  // Since we are working with ints we suggest passing in nanodegrees, which ~= 0.1 mm
  // But it will work with any consistent units, so long as they are ints.
  function boundingBoxBuffer (int[2] memory _point, int _buffer) internal pure returns (int[2][2] memory) {
      int[2] memory ll = [_point[0] - _buffer, _point[1] - _buffer];
      int[2] memory ur = [_point[0] + _buffer, _point[1] + _buffer];

      return ([ll, ur]);
  }

  function pointInBbox (int[2] memory _point, int[2][2] memory _bbox) internal pure returns (bool) {
      require(_bbox[0][0] < _bbox[1][0] && _bbox[0][1] < _bbox[1][1]);
      if ((_point[0] > _bbox[0][0]) && (_point[0] < _bbox[1][0]) && (_point[1] > _bbox[1][0]) && (_point[1] < _bbox[1][1]) ) {
          return true;
      } else {
          return false;
      }
  }
}

contract DeliveryContract is GeoHelpers {

  event NewContract(address recipient, address provider, uint start, uint contractId);
  event ReachCompletionPaid(uint contractId);
  // SignificantStepPassed

  int boudingBoxBufferSize = 100000;  // in nanodegrees, to equate 10 meters

  struct Contract {
    // Contractants information
    address recipient;
    address provider;  // the one who will receive the payment

    // Criteria for a good execution of the contract
    uint start;  // time at the agreement of the contract, a unix timestamp
    uint expectedCompletion;  // delta from start in seconds
    int[2] destination;  // in nanodegrees

    bool completed;  // basic state

    // Financials
    uint amount;  // could be pegged to a conventional currency (DAI)
    uint penalityAmount;
    uint penalityUnit;  // in seconds

    uint recipientShare;  // for historic purpose
    uint providerShare;

    // Optinal factors, measurable stuff (make it possible to have that different for each contract)
    // has the container been opened? (iot). Temperature variation? More? Only measurable stuff

  }

  mapping(uint => Contract) contracts;
  uint lastContractId = 0;


  // modifiers

  modifier contractIncomplete(uint _contractId) {
    Contract memory cont = contracts[_contractId];
    require(!cont.completed);
    _;
  }

  modifier contractMember(address _account, uint _contractId) {
    Contract memory cont = contracts[_contractId];
    require(_account == cont.recipient || _account == cont.provider);
    _;
  }


  // private functions

  function onTime(Contract storage _cont, uint _time) private view returns (bool) {
    if (_cont.start + _cont.expectedCompletion <= _time) {
      return true;
    } else {
      return false;
    }
  }

  function arrived(int[2] memory _pos) private view returns (bool) {
    int[2][2] memory bbb = boundingBoxBuffer(_pos, boudingBoxBufferSize);
    if (pointInBbox(_pos, bbb)) {
      return true;
    } else {
      return false;
    }
  }

  function timeDiscount(Contract storage _cont, uint _time) private view returns (uint) {
    uint diff = _cont.start + _cont.expectedCompletion - _time;
    return (diff / _cont.penalityUnit) * _cont.penalityAmount;
  }

  function getAmountToPay(Contract storage _cont, uint _time) private view returns (uint) {
    if (onTime(_cont, _time)) {
      return _cont.amount;
    } else {
      return timeDiscount(_cont, _time);
    }
  }

  function payParties(Contract storage _cont, uint _time) private {
    _cont.providerShare = getAmountToPay(_cont, _time);
    if (_cont.providerShare < _cont.amount) {
      _cont.recipientShare = _cont.amount - _cont.providerShare;
    }
  }

  function checkCompletion(uint _contractId, int[2] memory _pos, uint _time) private {
    Contract storage cont = contracts[_contractId];
    if (arrived(_pos)) {
      cont.completed = true;
      payParties(cont, _time);
      emit ReachCompletionPaid(_contractId);
    }
  }

  function createContract(
    address _recipient,
    address _provider,
    uint _start,
    uint _expectedCompletion,
    int[2] memory _destination,
    uint _amount,
    uint _penalityAmount,
    uint _penalityUnit
  ) public payable {
    // note: we don't have to instantiate all struct variables at declaration,
    // we can initialize a struct variable and only declare some of its inner
    // variables
    // important: transaction functions must include a `payable`
    Contract memory cont = Contract({
        recipient: _recipient,
        provider: _provider,
        start: _start,
        expectedCompletion: _expectedCompletion,
        destination: _destination,
        completed: false,
        amount: _amount,
        penalityAmount: _penalityAmount,
        penalityUnit: _penalityUnit,
        recipientShare: 0,
        providerShare: 0
    });
    contracts[lastContractId++] = cont;
    // methods which modify the state of the blockchain/require a transaction
    // can't return a value (maybe because it's not immediate), instead it gets
    // a transaction id. To get a feedback on the transaction, 1) call a public
    // view function after having received the transaction id, or 2) emit an
    // event that our client listen to (like below)
    emit NewContract(_recipient, _provider, _start, lastContractId - 1);
  }

  // called programmatically by IoT
  // _pos coords in nanodegrees, i.e. gps degrees * 10^9 with the remaining digits truncated (e.g. with Math.floor in JS)
  function recordNewCoor(uint _contractId, int[2] memory _pos, uint _time) public payable contractIncomplete(_contractId) {
    checkCompletion(_contractId, _pos, _time);
  }

  function getContractInformation(uint _contractId) public view contractMember(msg.sender, _contractId) returns (
    address recipient,
    address provider,
    uint start,
    uint expectedCompletion,
    int[2] memory destination,
    uint amount,
    uint penalityAmount,
    uint penalityUnit,
    bool completed
  ) {
    Contract memory cont = contracts[_contractId];
    return (cont.recipient, cont.provider, cont.start, cont.expectedCompletion, cont.destination,
    cont.amount, cont.penalityAmount, cont.penalityUnit, cont.completed
    );
  }

}
