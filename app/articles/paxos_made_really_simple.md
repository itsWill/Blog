title: Paxos Made Really Simple
date:  2016-05-6
description: An annotated reading of Leslie Lamports "Paxos Made Simple" paper

## Preface

Paxos is hard, and implementing paxos is [really hard](http://research.google.com/archive/paxos_made_live.html). However it's not impossible we do a careful reading of Leslie Lamport's [Paxos Made Simple](http://research.microsoft.com/en-us/um/people/lamport/pubs/paxos-simple.pdf) paper explaining terms and ideas as we go along. The target audience here is a someone with a background in computer science but only a very basic understanding of distributed systems.

## Introduction

In the indroduction Lamport explains the motivation of the paper to exlain paxos as

> the original presentation was Greek to many readers

He comments how the Paxos algorithm naturally follows from the constraints we're trying to specifiy. Essentially the theory (the 'why') behind the algorithm. He then comments on the implementation of the algorithm (the 'how') with the following:

> The last section explains the complete Paxos algorithm which is obtained by the straightforward application of consensus to the state machine approach for building a distributed system

The state machine approach to build distributed systems is rooted in the concept of Determistic Finite Automata (DFA) these are a quintuple defined by:

1. A set of states that a DFA can be in
2. A start state
3. A set of final or accepting states
4. A set of transatitions describing how a given input changes the state of the DFA

When an input is fed to the DFA, the DFA will start at the start state and apply the transitions functions on the input until the input is fully read. If the DFA terminates on an accepting state then the DFA accepts the input as valid, otherwise it rejects the input. In the context of distributed systems this means that we create an instance of the distributed system on on various set of computers and each of these replicas is a taken to be a separate DFA. The input of is then fed to each of the replicas and we process the input, which is equivalent to performing the various transitions in a DFA. We then check what state each of the replicas is in monitoring for separate values.

If there is a separate value amongst the replicas we have to determine a single value for the system, since the DFA is determnistic each input should end in the same state. Lamport states that Paxos will naturally arise when we try to arrive at a consensus for a value for a given distributed system of state machines.

## The Consensus Algorithm

Assuming we have many processes that act like thes state machines that can propose various values Lamport mentions the three conditions necessary to chose a value amongst the state manchines:

1. Only a single value of the many proposed must be chosen
2. If no value is proposed then no value should be chosen
3. Once a value has been chosen a process should be able to learn about that value

Lamport then proposes the following safety requirements so that these conditions hold:

> 1. Only a value that has been proposed may be chosen
2. Only a single value may be chosen
3. If a value is chosen then another process should be able to learn it

He concisely summarizes the goal of the consensus algorithm

> However, the goal is to ensure that some proposed value is eventually chosen and, if a value has been chosen, then a process can eventually learn the value.

From these conditions we note the existance of three roles: proposers, acceptors and learners. Which are responsible for proposing a value, accepting and choosing a value, and learning the choosen value respectively.

> We let the three roles in the consensus algorithm be performed by three classes of agents: proposers, acceptors, and learners.

It's important to note as mentioned in the paper

> In an implementation, a single process may act as more than one agent

These agents communicate with one another using messages using the

> customary asynchronous, non-Byzantine model

The Byzantine fault tolerance model was actually first developed by Lamport himself (hes a bit of a giant in the distributed systems world). Imagine a group of generals each commanding a piece of the Byzantine army. They have encircled a city and have to decide wether to attack or reatreat between them. Ideally all generals attack or retreat because we assume that a healf hearted attack results in a rout a worse outcome than a full retreat or full attack. There are two problems here the messengers that deliver the messages between the generals and rogue generals. The messengers may fail to deliver a message or may not deliver a message in time. Rogue generals when voting can selectively vote towards the worst outcome, for example: 5 generals vote for attack, 5 vote for retreat, the 11th rogue general then votes for attack to the attacking generals and votes for retreat with the retreating generals, causing half of the non-rogue generals to attack and retreat.

In computer systems the generals are analogous to the computers and messengers are the links between the computers in which messages are delivered.
An asynchronous and non-Byzantine system is one where the agents communicate can receive and send messages at the same time, and in which there is no rogue general so to speak, i.e a process which goes rogue and can selectively act towards the worst outcome. Specifically we also assume:

> * Agents operate at arbitrary seped, may fail by stopping, and may restart. Since all agents may fail after a value is chosen and then restart, a solution is impossible unless some information can be remembered by an agent that has failed or restarted.
* Messages can take arbitrarily long to be delivered, can be duplicated, and can be lost, but they are not corrupted.

## Choosing a Value

Consider the case of one proposer and one acceptor. To choose a value the acceptor simply chooses the first value that it receives from the proposer. However if the acceptor fails the system fails and no progress in the protocol can be made. For fault tolerance then we create a set of acceptors.

> A proposer sends a proposed value to a set of acceptors. An acceptor may accept the proposed value. The value is chosen when a large enough set of acceptors have accepted it ... a large enough set consits of any majority of the agents.

As long as an acceptor can only accept one value then any two majorities picked from the set of acceptors will have a acceptor in common, this follows from the pigeon hole principle.
