# microns-nda-access

This guide will walk you through setting up the database container and the access methods for the [21617_data_release](https://github.com/cajal/21617_data_release) data.

The data and files for these can be found in the microns-explorer [here (link pending)]().

or

you can download the container image tar file using the [aws cli tool](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)

```bash
aws s3 cp s3://bossdb-open-data/iarpa_microns/interneuron/functional_data/two_photon_processed_data_and_metadata/database_v2/functional_data_database_container_image_v2.tar . --no-sign-request
```

# Prerequisites

- More than 35 GB of free disk space (around double that, ~70 GB, to load the image from the tar archive the first time, and potentially up to that amount to query from the database)
- [Docker](https://docs.docker.com/desktop/)
- [docker-compose](https://docs.docker.com/compose/)

# Setup

This section comes in two parts, the first is the database containing the `release_nda_db` schema and the second is for the container to access that data with DataJoint in a Jupyter notebook server that will come with tutorials or with the mysql-client.

If you wish to handle importing the SQL file into an existing database yourself you can skip this next `Database` section, and view the basic instructions for ingesting the database into an existing MySQL instance in the `Manual SQL Ingesting` section below. Then go back to the `Access` section.

# Database

The docker image must first be downloaded from the microns-explorer (in a tar archive format, link is at the top).
Save this to an accessible location.

In the location where you've stored the downloaded image archive you then will load the image to your local filesystem:

```bash
docker load < functional_data_database_container_image_v2.tar
```

OR

```bash
docker load --input functional_data_database_container_image_v2.tar
```

To start the database you can either `Docker` or `docker-compose`:

The data is this database, started with both Docker or docker-compose, is not persistent and changes will be lost when exiting the container.

## docker-compose

This would be the preferred method for starting the service as it is more fully configured.
```bash
docker-compose up -d database
```

## Docker

Running the container without docker-compose is also an option.

```bash
docker run --network="host" --detach 21617-release-nda-database:latest
```

# Access

The data can be accessed in two ways, either with the mysql-client or through DataJoint in a Jupyter notebook service.

The default user and password for the database are:

`username:` root  
`password:` microns123

The first accesses of the data may take awhile, but should be fast after that.

## Jupyter Notebook (DataJoint)

You can use this access repository and build the notebook image yourself with `Docker` and `docker-compose`.

Using the docker-compose you can start the container with:

```bash
docker-compose up -d notebook
```

which can then be accessed at http://localhost:8888/tree (this uses the default port of 8888).

http://localhost:8888 will send to Jupyter Lab, but the plots/graphics might not all work out-of-the-box without enabling jupyter lab extensions.

The database host will default to http://localhost:3306, or from the notebook container it can be accessed via the `database` link.

An external, persistent workspace can be mounted to the internal `workspace` folder by settings the `EXTERNAL_NOTEBOOKS` env variable to a folder of choice.

By **default**  the notebooks will connect with the database using the environment variable defaults set in `.env`, so you should be able to access the data and python modules.

However, if it's wanted to manually set the connection credentials and/or host in a notebook, below is an example of that:

```python
import datajoint as dj

dj.config['database.host'] = 'database'
dj.config['database.user'] = 'root'
df.config['database.password'] = 'microns123'
```

The pre-built image of the access container, microns-phase3-nda-notebook, can be downloaded from the microns-explorer linked above and loaded as a docker image the same way as the database archive above instead of building it yourself.

```bash
docker load --input functional_data_notebook_container_image_v2.tar
```

## mysql-client

From the local machine you can access it this way

```bash
mysql -h 127.0.0.1 -u root -p
```

which will then prompt for the password (the default from above is `microns123`) and will open an interactive mysql terminal.

## .env file

This docker-compose file is optimized to get a single machine up and running quickly with the database and notebook server.
However, you  might want to run a server and let many other clients connect to it, rather than having all the clients run their own database.

If so, you only need to run the notebook portion of the docker-compose file, but then you must modify the existing .env file to point to the host of an working database.  To do so you need to modify the DJ_HOST variable of the .env file provided.

replacing the "\<hostname>" with the hostname of the machine hosting the database (can use `127.0.1.1` if the notebook service has `network_mode: 'host'` enabled, but otherwise must use the network ip of the computer hosting the database container).

You can also replace the ./notebooks reference to a folder of your choice.

The links section of the notebook service in docker-compose.yml will also need to be commented out or it'll expect the database container image to be present.

## Manual SQL Ingesting

If you want to ingest/import the SQL file into an existing MySQL instance you must first directly download the SQL dump file, this can be done with:

```bash
aws s3 cp s3://bossdb-open-data/iarpa_microns/interneuron/functional_data/two_photon_processed_data_and_metadata/database_v2/functional_data_database_sql_dump_v2.sql . --no-sign-request
```

Then to ingest it into your existing database, you first must create an empty schema by the name of `release_nda_db`, then run this command (the `--compress` flag is optional) after replacing `[your-custom-databse-ip]` and `[your-username]` with your own info:

```bash
mysql --compress --max_allowed_packet=2147483648 -h[your-custom-database-ip] -u[your-username] -p release_nda_db < functional_data_database_sql_dump_v2.sql
```

This should take several hours.

## Known Issues

- For Windows and Mac (where you have to allocate memory ahead of time for Docker) you might need to allocate 8-12 GB to Docker to ensure you aren't running into the upper limits of the default allocated memory limits. Otherwise you might run into a "Lost Connection to MYSQL database" exception, which can be temporarily fixed by restarting the notebook kernel.
