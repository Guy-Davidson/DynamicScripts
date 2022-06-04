# Dynamic System

Dynamic System utalizes the cloud greatest advantage: scalability.

The System can take binary data into two different EC2 instances: A and B, that maintain inQueue and outQueue.
An AutoScaler constantly checks to see if the inQueue is overloaded and if so lunches an EC2 Worker.
The workers take jobs from both A and B's inQueues, process them, and when completed pushes back to the maching outQueue.
If a Worker fails to take a job for too long he will automatically shut down.
The completed jobs can be later retrieved, and if needed A and B will try to fill in from each other's outQueues. 

Possiable use cases for the system are web servers or labda functions.

