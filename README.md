# Dynamic System

Dynamic System utalizes the cloud greatest advantage: scalability.

![Alt text](DynamicSystem.png?raw=true "Diagram")

The System can take binary data into two different EC2 instances: A and B, that maintain inQueue and outQueue.<br />
An AutoScaler constantly checks to see if the inQueue is overloaded and if so lunches an EC2 Worker.<br />
The workers take jobs from both A and B's inQueues, process them, and when completed pushes back to the outQueue.<br />
If a Worker fails to take a job for too long he will automatically shut down.<br />
The completed jobs can be later retrieved, and if needed A and B will try to fill in from each other's outQueues. <br />

Possiable use cases for the system are web servers or labda functions.