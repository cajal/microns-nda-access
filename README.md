# microns-nda-access

This guide will walk you through setting up the `nda` database locally. The `nda` database contains the functional data for the MICrONS project.

An overview of the functional data and other access options can be found in [MICrONS Explorer](https://www.microns-explorer.org/cortical-mm3#f-data).

The current version of this repository and the database is v8.

This repo is synchronized with the [`microns_phase3_nda`](https://github.com/cajal/microns_phase3_nda) repo, which contains the Jupyter notebooks and utilities to interact with the functional data. The Jupyter Docker environment launched by following this tutorial will install `microns_phase3_nda` and make the tutorials easily accessible.

# Database Setup

There are two main MySQL database setup options covered here.

1. Set up a Docker container environment with the database and all data pre-ingested. [Skip to section](#database-container)

2. Download a data dump for manual ingestion into an existing MySQL database. [Skip to section](#manual-sql-ingesting)

After the database is set up, continue on to the [Access](#access) section to begin working with the data.

## Database container

### Requirements

- More than 120 GB of free disk space (around double that, ~222 GB, to load the image from the tar archive for the first time, and potentially up to that amount to query from the database)
- [Docker](https://docs.docker.com/desktop/)
- [docker-compose](https://docs.docker.com/compose/)

### Step 1: Download the container image tar file to an accessible location. There are two methods:

1. Use the [aws command line tool](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
    ```bash
    aws s3 cp s3://bossdb-open-data/iarpa_microns/minnie/functional_data/two_photon_processed_data_and_metadata/database_v8/functional_data_database_container_image_v8.tar . --no-sign-request
    ```
2. Download the file directly by clicking [here](https://bossdb-open-data.s3.amazonaws.com/iarpa_microns/minnie/functional_data/two_photon_processed_data_and_metadata/database_v8/functional_data_database_container_image_v8.tar). (Warning: download will start automatically.)


### Step 2: In the directory where you've stored the downloaded image archive you then will load the image to your local filesystem:

```bash
docker load --input functional_data_database_container_image_v8.tar
```

To start the database run:

```bash
docker-compose up -d database
```
`WARNING`: Any changes made to the database are not persistent and changes will be lost when exiting the container.

The default username and password for the database are:

`username:` root  
`password:` microns123

To access the database, continue on to the [Access](#access) section.

NOTE: The first accesses of the data may take awhile, but should be fast after that.

## Manual SQL Ingesting

### Requirements

- 115GB of free disk space (around double that ~230 GB during ingest if the database is on the same disk. The SQL dump file can be deleted after ingest to recover space.)

To download the SQL dump file with the [aws command line tool](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) run:

```bash
aws s3 cp s3://bossdb-open-data/iarpa_microns/minnie/functional_data/two_photon_processed_data_and_metadata/database_v8/functional_data_database_sql_dump_v8.sql . --no-sign-request
```

Then to ingest it into your existing database, you first must create an empty schema by the name of `microns_phase3_nda`, then run this command (the `--compress` flag is optional) after replacing `[your-custom-databse-ip]` and `[your-username]` with your own info:

```bash
mysql --compress --max_allowed_packet=2147483648 -h[your-custom-database-ip] -u[your-username] -p microns_phase3_nda < functional_data_database_sql_dump_v8.sql
```

This should take several hours.

# Access
This section describes how to launch a a Jupyter Docker container that contains tutorials on how to use [DataJoint](https://datajoint.com/) to access the database. 

If you performed a manual SQL ingest described above continue on [here](#run-the-jupyter-notebook-environment-with-your-own-database).

## Run the Jupyter Notebook (DataJoint) with the database container

To start the container run:

```bash
docker-compose up -d notebook
```

NOTE: it will take several minutes to build on the first run

Continue on [here](#launch-the-jupyter-environment) to launch the jupyter environment.

## Run the Jupyter Notebook environment with your own database

By **default**  the notebooks will connect with the database using the environment variable defaults set in `.env`.

To input the credentials to your own database, either:

1. modify the `.env` file in this directory by pointing `DJ_HOST` the IP address of your database, and `DJ_USER` and `DJ_PASS` to your database username and password.

OR 

2. Continue on and adjust these later using DataJoint

In this repository directory run:

```bash
docker-compose up -d notebook-only
```

To launch the Jupyter environment continue [here](#launch-the-jupyter-environment).

To adjust credentials using DataJoint, in a notebook run the following after replacing the angle bracket placeholders with your information as a `str`:

```python
import datajoint as dj

dj.config['database.host'] = <YOUR DATABASE IP ADDRESS>
dj.config['database.user'] = <YOUR USERNAME>
dj.config['database.password'] = <YOUR PASSWORD>
```

## Launch the Jupyter environment

The Jupyter environment can then be accessed at http://localhost:8888/tree (this uses the default port of 8888).

http://localhost:8888 will send to Jupyter Lab, but the plots/graphics might not all work out-of-the-box without enabling jupyter lab extensions.

Once inside the Jupyter environment, navigate to the `tutorial_notebooks` folder and run through the tutorials to ensure everything is configured properly.

NOTE: The `notebook` folder in this repo is mounted by default to a folder called `workspace` in the container. To modify which folder is mapped to `notebook` see [here](#modify-external_notebooks-in-env)

# Additional Notes

## Modify EXTERNAL_NOTEBOOKS in .env
To change which directory is mapped to the `notebooks` folder in the container, point the`EXTERNAL_NOTEBOOKS` variable in the `.env` file of this repo to a different directory of choice. To apply the changes in the `.env` file if the container is already up, then the `docker-compose up -d notebook` or `docker-compose up -d notebook-only` command would need to be rerun. 

## Default database host for the `notebook` docker-compose service

The database host will default to http://localhost:3306, or from the notebook container it can be accessed via the `database` link as `DJ_HOST` value.

## .env file

This docker-compose file is optimized to get a single machine up and running quickly with the database and notebook server.
However, you  might want to run a server and let many other clients connect to it, rather than having all the clients run their own database.

If so, you only need to run the notebook portion of the docker-compose file, but then you must modify the existing .env file to point to the host of a working database.  To do so you need to modify the DJ_HOST variable of the .env file provided.

replacing the "\<hostname>" with the hostname of the machine hosting the database (can use `127.0.1.1` if the notebook service has `network_mode: 'host'` enabled, but otherwise must use the network ip of the computer hosting the database container).

## Access database with mysql-client

See detailed instructions on the [mysql website](https://dev.mysql.com/doc/mysql-getting-started/en/)

The default user and password for the database in the container are:

`username:` root  
`password:` microns123

# Known Issues

- For Mac (where you have to allocate memory ahead of time for Docker) you might need to allocate 8-12 GB to Docker to ensure you aren't running into the upper limits of the default allocated memory limits. Otherwise you might run into a "Lost Connection to MYSQL database" exception, which can be temporarily fixed by restarting the notebook kernel.
