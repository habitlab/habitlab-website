# habitlab-website

## Setting up and running

Get the code from github

```
git clone https://github.com/habitlab/habitlab-website.git
cd habitlab-website
```

Edit the file `.getsecret.yaml` and add in the following contents:

```
MONGODB_URI: mongodb://localhost:27017/default
roles: viewdata,logging,reportbug,intervention,debug
```

Install [Node.js](https://nodejs.org/en/) version 8, [MongoDB](https://docs.mongodb.com/manual/administration/install-community/) version 3.4.

Install dependencies:

```
yarn
sudo npm install -g mongosrv node-dev
```


## Extracting the Database

Extract the file `mongodb_backup_nov9.tar.gz` to a directory.

Go to the directory where you want the database to be stored. Run the command:

```
mongosrv
```

A folder called `mongodata` will be created containing the database.

Now run the following command to restore the database from the dump:

```
mongorestore mongodb_backup_nov9/dump
```

On subsequent runs, you just need to start the command `mongosrv` in that folder containing the `mongodata` command to start the server.

## Running the server

Make sure the mongodb server is running (using the `mongosrv` command, see section above), then run the following command from the `habitlab-website` directory:

```
./runserver
```

