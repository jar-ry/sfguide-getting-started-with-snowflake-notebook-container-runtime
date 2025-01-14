ALTER SESSION SET query_tag = '{"origin":"sf_sit-is", "name":"aiml_notebooks_container_runtime", "version":{"major":1, "minor":0}, "attributes":{"is_quickstart":1, "source":"sql"}}';
USE ROLE accountadmin;
CREATE OR REPLACE DATABASE container_runtime_lab;
CREATE SCHEMA notebooks;

CREATE OR REPLACE ROLE container_runtime_lab_user;
GRANT ROLE container_runtime_lab_user to USER <YOUR_USER>;

GRANT USAGE ON DATABASE container_runtime_lab TO ROLE container_runtime_lab_user;
GRANT ALL ON SCHEMA container_runtime_lab.notebooks TO ROLE container_runtime_lab_user;
GRANT CREATE STAGE ON SCHEMA container_runtime_lab.notebooks TO ROLE container_runtime_lab_user;
GRANT CREATE NOTEBOOK ON SCHEMA container_runtime_lab.notebooks TO ROLE container_runtime_lab_user;
GRANT CREATE SERVICE ON SCHEMA container_runtime_lab.notebooks TO ROLE container_runtime_lab_user;

CREATE OR REPLACE WAREHOUSE CONTAINER_RUNTIME_WH AUTO_SUSPEND = 60;
GRANT ALL ON WAREHOUSE CONTAINER_RUNTIME_WH TO ROLE container_runtime_lab_user;

-- Create and grant access to compute pools
CREATE COMPUTE POOL IF NOT EXISTS cpu_xs_5_nodes
  MIN_NODES = 1
  MAX_NODES = 5
  INSTANCE_FAMILY = CPU_X64_XS;

CREATE COMPUTE POOL IF NOT EXISTS gpu_s_5_nodes
  MIN_NODES = 1
  MAX_NODES = 5
  INSTANCE_FAMILY = GPU_NV_S;

GRANT USAGE ON COMPUTE POOL cpu_xs_5_nodes TO ROLE container_runtime_lab_user;
GRANT USAGE ON COMPUTE POOL gpu_s_5_nodes TO ROLE container_runtime_lab_user;

-- Create and grant access to EAIs
-- Substep #1: create network rules (these are schema-level objects; end users do not need direct access to the network rules)

create network rule allow_all_rule
  TYPE = 'HOST_PORT'
  MODE= 'EGRESS'
  VALUE_LIST = ('0.0.0.0:443','0.0.0.0:80');

-- Substep #2: create external access integration (these are account-level objects; end users need access to this to access the public internet with endpoints defined in network rules)

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION allow_all_integration
  ALLOWED_NETWORK_RULES = (allow_all_rule)
  ENABLED = true;

CREATE OR REPLACE NETWORK RULE pypi_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('pypi.org', 'pypi.python.org', 'pythonhosted.org',  'files.pythonhosted.org');

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION pypi_access_integration
  ALLOWED_NETWORK_RULES = (pypi_network_rule)
  ENABLED = true;

GRANT USAGE ON INTEGRATION allow_all_integration TO ROLE container_runtime_lab_user;
GRANT USAGE ON INTEGRATION pypi_access_integration TO ROLE container_runtime_lab_user;

USE ROLE container_runtime_lab_user;

CREATE FILE FORMAT IF NOT EXISTS container_runtime_lab.notebooks.csvformat 
    SKIP_HEADER = 1 
    TYPE = 'CSV';

-- create external stage with the csv format to stage the diamonds dataset
CREATE STAGE IF NOT EXISTS container_runtime_lab.notebooks.diamond_assets 
    FILE_FORMAT = container_runtime_lab.notebooks.csvformat 
    URL = 's3://sfquickstarts/intro-to-machine-learning-with-snowpark-ml-for-python/diamonds.csv';

CREATE OR REPLACE TABLE CONTAINER_RUNTIME_LAB.NOTEBOOKS.DIAMONDS (
	CARAT NUMBER(38,2),
	CUT VARCHAR(16777216),
	COLOR VARCHAR(16777216),
	CLARITY VARCHAR(16777216),
	DEPTH NUMBER(38,1),
	"TABLE" NUMBER(38,1),
	PRICE NUMBER(38,0),
	X NUMBER(38,2),
	Y NUMBER(38,2),
	Z NUMBER(38,2)
);

COPY INTO CONTAINER_RUNTIME_LAB.NOTEBOOKS.DIAMONDS
FROM @CONTAINER_RUNTIME_LAB.NOTEBOOKS.DIAMOND_ASSETS;
