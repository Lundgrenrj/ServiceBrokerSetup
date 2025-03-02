-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Server/Login Level
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Create Master Key if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPass2!';
GO

-- Create a server-level certificate
CREATE CERTIFICATE BrokerCertB_Server
WITH SUBJECT = 'Service Broker Endpoint Certificate for Instance B';
GO

-- Create a login for Service Broker
CREATE LOGIN BrokerLoginB FROM CERTIFICATE BrokerCertB_Server;
GO

-- Create a Service Broker endpoint for secure communication
CREATE ENDPOINT ServiceBrokerB
STATE = STARTED
AS TCP (LISTENER_PORT = 4023)
FOR SERVICE_BROKER (AUTHENTICATION = CERTIFICATE BrokerCertB_Server);
GO

-- Grant CONNECT permissions on the Service Broker endpoint
GRANT CONNECT ON ENDPOINT::ServiceBrokerB TO BrokerLoginB;
GO

-- Backup the server-level certificate for use on Instance A
BACKUP CERTIFICATE BrokerCertB_Server
TO FILE = 'C:\sqlservercerts\BrokerCertB_Server.cer';
GO


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Database/User Level
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE DATABASE TestDatabase1
ALTER DATABASE TestDatabase1 SET ENABLE_BROKER;
GO

USE TestDatabase1;
GO

-- Create a master key for database encryption (if it doesn't exist)
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'AnotherStrongPassword!';
GO


-------------------------------------------------------------------
CREATE USER BrokerUserB WITHOUT LOGIN
-----------------------------------------------------------------------------

-- Create a database-level certificate
CREATE CERTIFICATE BrokerCertB_User
AUTHORIZATION BrokerUserB
WITH SUBJECT = 'Database Certificate for Service Broker on Instance B';
GO

-- Backup the database certificate for import into Instance B
BACKUP CERTIFICATE BrokerCertB_User
TO FILE = 'C:\sqlservercerts\BrokerCertB_User.cer';
GO

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Import Instance A Server/Login Certificates
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


USE master;
GO

-- Import Instance A’s Server Certificate into Instance B
CREATE CERTIFICATE BrokerCertA_Server
FROM FILE = 'C:\sqlservercerts\BrokerCertA_Server.cer';
GO

-- Create a login from this certificate
CREATE LOGIN BrokerLoginA FROM CERTIFICATE BrokerCertA_Server;
GO

-- Grant the login access to the Service Broker endpoint on Instance A
GRANT CONNECT ON ENDPOINT::ServiceBrokerB TO BrokerLoginA;
GO

select a.service_broker_guid
from sys.databases a
where a.name = 'TestDatabase1'


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Import Instance A Database/User Certificates
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

USE TestDatabase1;
GO


-- Create a user for Service Broker
CREATE USER RemoteUserA WITHOUT LOGIN
GO

-- Import Instance B’s Server Certificate into Instance A
CREATE CERTIFICATE BrokerCertA_User
AUTHORIZATION RemoteUserA
FROM FILE = 'C:\sqlservercerts\BrokerCertA_User.cer';
GO

-- Define a message type
CREATE MESSAGE TYPE SB_MessageType AUTHORIZATION BrokerUserB  VALIDATION = WELL_FORMED_XML;
GO

-- Define a contract
CREATE CONTRACT SB_Contract AUTHORIZATION BrokerUserB (SB_MessageType SENT BY INITIATOR);
GO


-- Create a queue
CREATE QUEUE SB_ReceiveQueue;
GO


-- Create a service
CREATE SERVICE SB_ReceiveService AUTHORIZATION BrokerUserB ON QUEUE SB_ReceiveQueue (SB_Contract) 
GO



CREATE ROUTE SB_Route_To_InstanceA
AUTHORIZATION BrokerUserB 
WITH SERVICE_NAME = 'SB_SendService',
BROKER_INSTANCE = '2DAD8184-F810-43DE-9B9B-D16EE473E587',
ADDRESS = 'TCP://127.0.0.1:4022';


-- Recreate the remote service binding using the LOGIN instead of USER
CREATE REMOTE SERVICE BINDING RemoteBindingToInstanceA  
TO SERVICE 'SB_SendService'  
WITH USER = RemoteUserA, ANONYMOUS = OFF  -- Use the LOGIN, not the database user!
GO


-- Grant permissions to allow sending messages
GRANT SEND ON SERVICE::SB_ReceiveService TO RemoteUserA;
GO