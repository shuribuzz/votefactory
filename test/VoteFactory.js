const expect = require('chai').expect;
const should = require('chai')
    .use(require('chai-as-promised'))
    .use(require('chai-bignumber')(web3.BigNumber))
    .should();

//import expectThrow from "./helpers/expectThrow.js";

var VoteFactory = artifacts.require("./VoteFactory.sol");

expectThrow =  async promise => {
    try {
        await promise;
    } catch (error) {
        // TODO: Check jump destination to destinguish between a throw
        //       and an actual invalid jump.
        const invalidOpcode = error.message.search('invalid opcode') >= 0;
        // TODO: When we contract A calls contract B, and B throws, instead
        //       of an 'invalid jump', we get an 'out of gas' error. How do
        //       we distinguish this from an actual out of gas event? (The
        //       ganache log actually show an 'invalid jump' event.)
        const outOfGas = error.message.search('out of gas') >= 0;
        const revert = error.message.search('revert') >= 0;

        assert(
            invalidOpcode || outOfGas || revert,
            'Expected throw, got \'' + error + '\' instead',
        );
        
        return;
    }

    assert(false, 'Expected throw not received');
};

contract('VoteFactory', function(accounts) {
    var voteFactory;

    const owner = accounts[0];
    const creator = accounts[1];
    const user = accounts[2];

    const question0 = "Question 0";
    const questionCh = "Question Change";
    const answer0 = "Answer 0";
    const answerCh = "Answer Change";

    beforeEach('setup contract for each test', async function () {
        voteFactory = await VoteFactory.new({from: owner});
    });

    it('vote created', async function () {
        await voteFactory.createVote(question0, {from: creator});
        let vote = await voteFactory.votes(0);
        vote[0].should.be.equal(question0);
    });

    it('answer added by creator', async function () {
        await voteFactory.createVote(question0, {from: creator});
        await voteFactory.addAnswer(0, answer0, {from: creator}); 
        let answer = await voteFactory.getAnswer(0,0);
        answer.should.be.equal(answer0);      
    });

    it('answer added by user', async function () {
        await voteFactory.createVote(question0, {from: creator});
        await expectThrow(voteFactory.addAnswer(0, answer0, {from: user}));       
    });

    it('start&stop vote by user', async function() {
        await voteFactory.createVote(question0, {from: creator});
        await expectThrow(voteFactory.startVote(0, {from: user})); 
        await expectThrow(voteFactory.stopVote(0, {from: user})); 
    })

    it('change question by creator', async function() {
        await voteFactory.createVote(question0, {from: creator});
        await voteFactory.changeQuestion(0, questionCh,  {from: creator}); 
        let vote = await voteFactory.votes(0);
        vote[0].should.be.equal(questionCh); 
    })

    it('change answer by creator', async function() {
        await voteFactory.createVote(question0, {from: creator});
        await voteFactory.addAnswer(0, answer0, {from: creator}); 
        await voteFactory.changeAnswer(0, 0, answerCh,  {from: creator}); 
        let answer = await voteFactory.getAnswer(0,0);
        answer.should.be.equal(answerCh);  
    })

    it('change vote by user', async function() {
        await voteFactory.createVote(question0, {from: creator});
        await voteFactory.addAnswer(0, answer0, {from: creator});
        await expectThrow(voteFactory.changeQuestion(0, questionCh, {from: user})); 
        await expectThrow(voteFactory.changeAnswer(0, 0, answerCh, {from: user})); 
    })
 
});