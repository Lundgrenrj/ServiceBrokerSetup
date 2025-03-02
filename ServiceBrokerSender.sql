-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Server/Login Level
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Create Master Key if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPass2!';
GO

-- Create a server-level certificate
CREATE CERTIFICATE BrokerCertA_Server
WITH SUBJECT = 'Service Broker Endpoint Certificate for Instance A';
GO

-- Create a login for Service Broker
CREATE LOGIN BrokerLoginA FROM CERTIFICATE BrokerCertA_Server;
GO

-- Create a Service Broker endpoint for secure communication
CREATE ENDPOINT ServiceBrokerA
STATE = STARTED
AS TCP (LISTENER_PORT = 4022)
FOR SERVICE_BROKER (AUTHENTICATION = CERTIFICATE BrokerCertA_Server);
GO

-- Grant CONNECT permissions on the Service Broker endpoint
GRANT CONNECT ON ENDPOINT::ServiceBrokerA TO BrokerLoginA;
GO

-- Backup the server-level certificate for use on Instance A
BACKUP CERTIFICATE BrokerCertA_Server
TO FILE = 'C:\sqlservercerts\BrokerCertA_Server.cer';
GO

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Database/User Level
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE DATABASE TestDatabase1
ALTER DATABASE TestDatabase1 SET ENABLE_BROKER
GO

USE TestDatabase1;
GO

-- Create a master key for database encryption (if it doesn't exist)
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'AnotherStrongPassword!';
END
GO

-------------------------------------------------------------------
CREATE USER BrokerUserA WITHOUT LOGIN
-----------------------------------------------------------------------------

-- Create a database-level certificate
CREATE CERTIFICATE BrokerCertA_User
AUTHORIZATION BrokerUserA
WITH SUBJECT = 'Database Certificate for Service Broker on Instance A';
GO

-- Backup the database certificate for import into Instance B
BACKUP CERTIFICATE BrokerCertA_User
TO FILE = 'C:\sqlservercerts\BrokerCertA_User.cer';
GO

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Import Instance B Server/Login Certificates
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

USE master;
GO

-- Import Instance B’s Server Certificate into Instance A
CREATE CERTIFICATE BrokerCertB_Server
FROM FILE = 'C:\sqlservercerts\BrokerCertB_Server.cer';
GO

-- Create a login from this certificate
CREATE LOGIN BrokerLoginB FROM CERTIFICATE BrokerCertB_Server;
GO

-- Grant the login access to the Service Broker endpoint on Instance A
GRANT CONNECT ON ENDPOINT::ServiceBrokerA TO BrokerLoginB;
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
CREATE USER RemoteUserB WITHOUT LOGIN
GO

-- Import Instance B’s Server Certificate into Instance A
CREATE CERTIFICATE BrokerCertB_User
AUTHORIZATION RemoteUserB
FROM FILE = 'C:\sqlservercerts\BrokerCertB_User.cer';
GO

-- Define a message type
CREATE MESSAGE TYPE SB_MessageType AUTHORIZATION BrokerUserA VALIDATION = WELL_FORMED_XML;
GO

-- Define a contract
CREATE CONTRACT SB_Contract AUTHORIZATION BrokerUserA (SB_MessageType SENT BY INITIATOR);
GO


-- Create a queue
CREATE QUEUE SB_SendQueue;
GO

-- Create a service
CREATE SERVICE SB_SendService AUTHORIZATION BrokerUserA ON QUEUE SB_SendQueue (SB_Contract);
GO

CREATE ROUTE SB_Route_To_InstanceB
AUTHORIZATION BrokerUserA
WITH SERVICE_NAME = 'SB_ReceiveService',
BROKER_INSTANCE = 'C1A559D5-1B82-4D76-BE3F-0D3BE6B26BCE',
ADDRESS = 'TCP://127.0.0.1:4023';


-- Recreate the remote service binding using the LOGIN instead of USER
CREATE REMOTE SERVICE BINDING RemoteBindingToInstanceB  
TO SERVICE 'SB_ReceiveService'  
WITH USER = RemoteUserB, ANONYMOUS = OFF;  -- Use the LOGIN, not the database user!
GO



-- Grant permissions to allow sending messages
GRANT SEND ON SERVICE::SB_SendService TO RemoteUserB;
GO



-- Begin a conversation
DECLARE @ConversationHandle UNIQUEIDENTIFIER;
BEGIN TRANSACTION;
BEGIN DIALOG CONVERSATION @ConversationHandle
    FROM SERVICE SB_SendService
    TO SERVICE 'SB_ReceiveService'
    ON CONTRACT SB_Contract
    WITH ENCRYPTION = ON;

-- Send a test message
SEND ON CONVERSATION @ConversationHandle
    MESSAGE TYPE SB_MessageType ('<Message>Hello, Service Broker!</Message>');
COMMIT TRANSACTION;
GO


select *
from sys.transmission_queue a

select name from sys.database_principals where principal_id = 1

 SELECT *
   FROM sys.databases
   WHERE name = DB_NAME()
   AND is_master_key_encrypted_by_server = 0