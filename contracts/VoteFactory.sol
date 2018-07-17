pragma solidity ^ 0.4 .24;

import "./Ownable.sol";

contract VoteFactory is Ownable {

    event StartVote(address indexed creator, uint256 indexed _voteId, uint timestamp);
    event StopVote(address indexed stopping, uint256 indexed _voteId, uint timestamp);
    event CreateQuestion(address indexed creator, uint256 indexed _voteId, string question);
    event CreateAnswer(address indexed creator, uint256 indexed _answerId, string answer);

    enum State {
        Initial,
        Started,
        Stopped
    }
    State stateVote;
 
    struct Vote {
        string question;
        string[] answers;
        State stateVote;
        mapping(uint256 => uint256) answerToCounter; // (_answerId => count)
        mapping(address => bool) voteCheck;
    }
    
    Vote[] public votes;
    mapping(uint256 => address) voteToOwner;

    modifier OnlyOwnerVote(uint _voteId){
        require(voteToOwner[_voteId] == msg.sender);
        _;
    }

    modifier Initialized(uint _voteId) {
        require(votes[_voteId].stateVote == State.Initial);
        _;
    }

    modifier Started(uint _voteId) {
        require(votes[_voteId].stateVote == State.Started);
        _;
    }

    modifier Stopped(uint _voteId) {
        require(votes[_voteId].stateVote == State.Stopped);
        _;
    }

    function createVote(string _question) external {
        uint256 voteId = votes.push(Vote(_question, new string[](0), State.Initial)) - 1;
        voteToOwner[voteId] = msg.sender;
        emit CreateQuestion(msg.sender, voteId, _question);
    }

    function addAnswer(uint _voteId, string _answer) external Initialized(_voteId) OnlyOwnerVote(_voteId) {
        votes[_voteId].answers.push(_answer);
        emit CreateAnswer(msg.sender, _voteId, _answer);
    }

    function startVote(uint _voteId) external Initialized(_voteId) OnlyOwnerVote(_voteId) {
        votes[_voteId].stateVote = State.Started;
        emit StartVote(msg.sender, _voteId, now);
    }

    function stopVote(uint _voteId) external Started(_voteId) OnlyOwnerVote(_voteId){
        votes[_voteId].stateVote = State.Stopped;
        emit StopVote(voteToOwner[_voteId], _voteId, now);
    }
    
    function changeQuestion(uint _voteId, string _changeQuestion) external OnlyOwnerVote(_voteId){
        votes[_voteId].question = _changeQuestion;
    }
    
    function changeAnswer(uint _voteId, uint _answerId, string _changeAnswer) external OnlyOwnerVote(_voteId){
        votes[_voteId].answers[_answerId] = _changeAnswer;
    }
    
    function cast(uint256 _voteId, uint256 _answerId) external Started (_voteId) {
        require(!votes[_voteId].voteCheck[msg.sender]);
        votes[_voteId].answerToCounter[_answerId] +=1; 
        votes[_voteId].voteCheck[msg.sender] = true;
        }
   
    function results(uint _voteId) external view returns(string) {
        uint256 max = votes[_voteId].answerToCounter[0];
        uint256 maxAnswerId =0;
        for(uint256 i=0; i < votes[_voteId].answers.length; i++){
            if(max < votes[_voteId].answerToCounter[i]){
            max = votes[_voteId].answerToCounter[i];
            maxAnswerId = i;
            }
       
        }
        return votes[_voteId].answers[maxAnswerId];
    }
    
    function getAnswer(uint _voteId, uint _answerId) external view returns(string) {
        return votes[_voteId].answers[_answerId];
    }

    function getState(uint _voteId) external view returns(State) {
        return votes[_voteId].stateVote;
    }

}