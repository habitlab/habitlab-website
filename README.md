# habitlab-website

## Setting up and running

Get the code from github

```
git clone git@github.com:habitlab/habitlab-website.git
cd habitlab-website
```

Edit the file `.getsecret.yaml` and add in the following contents:

```
MONGODB_URI: mongodb://localhost:27017/default
roles: viewdata,logging,reportbug,intervention,debug
```

Install [Node.js](https://nodejs.org/en/) version 8, [MongoDB](https://docs.mongodb.com/manual/administration/install-community/), then install dependencies and run the server:

```
yarn
sudo npm install -g mongosrv node-dev
./runserver
```
