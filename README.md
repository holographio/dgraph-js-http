# dgraph-js-http [![npm version](https://img.shields.io/npm/v/dgraph-js-http.svg?style=flat)](https://www.npmjs.com/package/dgraph-js-http) [![Build Status](https://img.shields.io/travis/dgraph-io/dgraph-js-http/master.svg?style=flat)](https://travis-ci.org/dgraph-io/dgraph-js-http) [![Coverage Status](https://img.shields.io/coveralls/github/dgraph-io/dgraph-js-http/master.svg?style=flat)](https://coveralls.io/github/dgraph-io/dgraph-js-http?branch=master)

A Dgraph client implementation for javascript using HTTP. It supports both
browser and Node.js environments.

**Looking for gRPC support? Check out [dgraph-js][grpcclient].**

This client follows the [Dgraph Javascript gRPC client][grpcclient] closely.

[grpcclient]: https://github.com/dgraph-io/dgraph-js

Before using this client, we highly recommend that you go through [docs.dgraph.io],
and understand how to run and work with Dgraph.

[docs.dgraph.io]: https://docs.dgraph.io

**Use [Discuss Issues](https://discuss.dgraph.io/c/issues/35) for reporting issues about this repository.**

## Table of contents

-   [Install](#install)
-   [Supported Versions](#supported-versions)
-   [Quickstart](#quickstart)
-   [Using a client](#using-a-client)
    -   [Create a client](#create-a-client)
    -   [Login into Dgraph](#login-into-dgraph)
    -   [Configure access tokens](#configure-access-tokens)
    -   [Alter the database](#alter-the-database)
    -   [Create a transaction](#create-a-transaction)
    -   [Run a mutation](#run-a-mutation)
    -   [Run a query](#run-a-query)
    -   [Commit a transaction](#commit-a-transaction)
    -   [Check request latency](#check-request-latency)
    -   [Debug mode](#debug-mode)
-   [Development](#development)
    -   [Building the source](#building-the-source)
    -   [Running tests](#running-tests)

## Install

Install using `yarn`:

```sh
yarn add dgraph-js-http
```

or npm:

```sh
npm install dgraph-js-http --save
```

You will also need a Promise polyfill for
[older browsers](http://caniuse.com/#feat=promises) and Node.js v5 and below.
We recommend [taylorhakes/promise-polyfill](https://github.com/taylorhakes/promise-polyfill)
for its small size and Promises/A+ compatibility.

## Supported Versions

Depending on the version of Dgraph that you are connecting to, you will have to
use a different version of this client.

| Dgraph version | dgraph-js-http version |
| :------------: | :--------------------: |
|   >= 21.03.0   |      >= _21.3.0_       |
|   >= 20.03.0   |      >= _20.3.0_       |
|     >= 1.1     |       >= _1.1.0_       |

## Quickstart

Build and run the [simple] project in the `examples` folder, which
contains an end-to-end example of using the Dgraph javascript HTTP client. Follow
the instructions in the README of that project.

[simple]: https://github.com/dgraph-io/dgraph-js-http/tree/master/examples/simple

## Using a client

### Create a client

A `DgraphClient` object can be initialised by passing it a list of
`DgraphClientStub` clients as variadic arguments. Connecting to multiple Dgraph
servers in the same cluster allows for better distribution of workload.

The following code snippet shows just one connection.

```js
const dgraph = require("dgraph-js-http");

const clientStub = new dgraph.DgraphClientStub(
    // addr: optional, default: "http://localhost:8080"
    "http://localhost:8080",
    // legacyApi: optional, default: false. Set to true when connecting to Dgraph v1.0.x
    false,
);
const dgraphClient = new dgraph.DgraphClient(clientStub);
```

To facilitate debugging, [debug mode](#debug-mode) can be enabled for a client.

### Multi-tenancy

In [multi-tenancy](https://dgraph.io/docs/enterprise-features/multitenancy) environments, `dgraph-js-http` provides a new method `loginIntoNamespace()`,
which will allow the users to login to a specific namespace.

In order to create a JavaScript client, and make the client login into namespace `123`:

```js
const dgraphClientStub = new dgraph.DgraphClientStub("localhost:9080");
await dgraphClientStub.loginIntoNamespace("groot", "password", 123); // where 123 is the namespaceId 
```

In the example above, the client logs into namespace `123` using username `groot` and password `password`.
Once logged in, the client can perform all the operations allowed to the `groot` user of namespace `123`.

### Create a Client for Dgraph Cloud Endpoint

If you want to connect to Dgraph running on your [Dgraph Cloud](https://cloud.dgraph.io) instance, then all you need is the URL of your Dgraph Cloud endpoint and the API key. You can get a client using them as follows:

```js
const dgraph = require("dgraph-js-http");

//here we pass the cloud endpoint
const clientStub = new dgraph.DgraphClientStub(
    "https://super-pail.us-west-2.aws.cloud.dgraph.io",
);

const dgraphClient = new dgraph.DgraphClient(clientStub);

//here we pass the API key
dgraphClient.setCloudApiKey("<api-key>");
```

**Note:** the `setSlashApiKey` method is deprecated and will be removed in the next release. Instead use `setCloudApiKey` method.

### Login into Dgraph

If your Dgraph server has Access Control Lists enabled (Dgraph v1.1 or above),
the clientStub must be logged in for accessing data:

```js
await clientStub.login("groot", "password");
```

Calling `login` will obtain and remember the access and refresh JWT tokens.
All subsequent operations via the logged in `clientStub` will send along the
stored access token.

Access tokens expire after 6 hours, so in long-lived apps (e.g. business logic servers)
you need to `login` again on a periodic basis:

```js
// When no parameters are specified the clientStub uses existing refresh token
// to obtain a new access token.
await clientStub.login();
```

### Configure access tokens

Some Dgraph configurations require extra access tokens.

1. Alpha servers can be configured with [Secure Alter Operations](https://dgraph.io/docs/deploy/dgraph-administration/#securing-alter-operations).
   In this case the token needs to be set on the client instance:

```js
dgraphClient.setAlphaAuthToken("My secret token value");
```

2. [Dgraph Cloud](https://cloud.dgraph.io) requires API key for HTTP access:

```js
dgraphClient.setCloudApiKey("Copy the Api Key from Dgraph Cloud admin page");
```

### Create https connection

If your cluster is using tls/mtls you can pass a node `https.Agent` configured with you
certificates as follows:

```js
const https = require("https");
const fs = require("fs");
// read your certificates
const cert = fs.readFileSync("./certs/client.crt", "utf8");
const ca = fs.readFileSync("./certs/ca.crt", "utf8");
const key = fs.readFileSync("./certs/client.key", "utf8");

// create your https.Agent
const agent = https.Agent({
    cert,
    ca,
    key,
});

const clientStub = new dgraph.DgraphClientStub(
    "https://localhost:8080",
    false,
    { agent },
);
const dgraphClient = new dgraph.DgraphClient(clientStub);
```

### Alter the database

To set the schema, pass the schema to `DgraphClient#alter(Operation)` method.

```js
const schema = "name: string @index(exact) .";
await dgraphClient.alter({ schema: schema });
```

> NOTE: Many of the examples here use the `await` keyword which requires
> `async/await` support which is not available in all javascript environments.
> For unsupported environments, the expressions following `await` can be used
> just like normal `Promise` instances.

`Operation` contains other fields as well, including drop predicate and drop all.
Drop all is useful if you wish to discard all the data, and start from a clean
slate, without bringing the instance down.

```js
// Drop all data including schema from the Dgraph instance. This is useful
// for small examples such as this, since it puts Dgraph into a clean
// state.
await dgraphClient.alter({ dropAll: true });
```

### Create a transaction

To create a transaction, call `DgraphClient#newTxn()` method, which returns a
new `Txn` object. This operation incurs no network overhead.

It is good practise to call `Txn#discard()` in a `finally` block after running
the transaction. Calling `Txn#discard()` after `Txn#commit()` is a no-op
and you can call `Txn#discard()` multiple times with no additional side-effects.

```js
const txn = dgraphClient.newTxn();
try {
    // Do something here
    // ...
} finally {
    await txn.discard();
    // ...
}
```

You can make queries read-only and best effort by passing `options` to `DgraphClient#newTxn`. For example:

```js
const options = { readOnly: true, bestEffort: true };
const res = await dgraphClient.newTxn(options).query(query);
```

Read-only transactions are useful to increase read speed because they can circumvent the usual consensus protocol. Best effort queries can also increase read speed in read bound system. Please note that best effort requires readonly.

### Run a mutation

`Txn#mutate(Mutation)` runs a mutation. It takes in a `Mutation` object, which
provides two main ways to set data: JSON and RDF N-Quad. You can choose whichever
way is convenient.

We define a person object to represent a person and use it in a `Mutation` object.

```js
// Create data.
const p = {
    name: "Alice",
};

// Run mutation.
await txn.mutate({ setJson: p });
```

For a more complete example with multiple fields and relationships, look at the
[simple] project in the `examples` folder.

For setting values using N-Quads, use the `setNquads` field. For delete mutations,
use the `deleteJson` and `deleteNquads` fields for deletion using JSON and N-Quads
respectively.

Sometimes, you only want to commit a mutation, without querying anything further.
In such cases, you can use `Mutation#commitNow = true` to indicate that the
mutation must be immediately committed.

```js
// Run mutation.
await txn.mutate({ setJson: p, commitNow: true });
```

### Run a query

You can run a query by calling `Txn#query(string)`. You will need to pass in a
GraphQL+- query string. If you want to pass an additional map of any variables that
you might want to set in the query, call `Txn#queryWithVars(string, object)` with
the variables object as the second argument.

The response would contain the `data` field, `Response#data`, which returns the response
JSON.

Let’s run the following query with a variable \$a:

```console
query all($a: string) {
  all(func: eq(name, $a))
  {
    name
  }
}
```

Run the query and print out the response:

```js
// Run query.
const query = `query all($a: string) {
  all(func: eq(name, $a))
  {
    name
  }
}`;
const vars = { $a: "Alice" };
const res = await dgraphClient.newTxn().queryWithVars(query, vars);
const ppl = res.data;

// Print results.
console.log(`Number of people named "Alice": ${ppl.all.length}`);
ppl.all.forEach(person => console.log(person.name));
```

This should print:

```console
Number of people named "Alice": 1
Alice
```

### Commit a transaction

A transaction can be committed using the `Txn#commit()` method. If your transaction
consisted solely of calls to `Txn#query` or `Txn#queryWithVars`, and no calls to
`Txn#mutate`, then calling `Txn#commit()` is not necessary.

An error will be returned if other transactions running concurrently modify the same
data that was modified in this transaction. It is up to the user to retry
transactions when they fail.

```js
const txn = dgraphClient.newTxn();
try {
    // ...
    // Perform any number of queries and mutations
    // ...
    // and finally...
    await txn.commit();
} catch (e) {
    if (e === dgraph.ERR_ABORTED) {
        // Retry or handle exception.
    } else {
        throw e;
    }
} finally {
    // Clean up. Calling this after txn.commit() is a no-op
    // and hence safe.
    await txn.discard();
}
```

### Check request latency

To see the server latency information for requests, check the
`extensions.server_latency` field from the Response object for queries or from
the Assigned object for mutations. These latencies show the amount of time the
Dgraph server took to process the entire request. It does not consider the time
over the network for the request to reach back to the client.

```js
// queries
const res = await txn.queryWithVars(query, vars);
console.log(res.extensions.server_latency);
// { parsing_ns: 29478,
//  processing_ns: 44540975,
//  encoding_ns: 868178 }

// mutations
const assigned = await txn.mutate({ setJson: p });
console.log(assigned.extensions.server_latency);
// { parsing_ns: 132207,
//   processing_ns: 84100996 }
```

### Debug mode

Debug mode can be used to print helpful debug messages while performing alters,
queries and mutations. It can be set using the`DgraphClient#setDebugMode(boolean?)`
method.

```js
// Create a client.
const dgraphClient = new dgraph.DgraphClient(...);

// Enable debug mode.
dgraphClient.setDebugMode(true);
// OR simply dgraphClient.setDebugMode();

// Disable debug mode.
dgraphClient.setDebugMode(false);
```

## Development

### Building the source

```sh
npm run build
```

### Running tests

Make sure you have a Dgraph server running on localhost before you run this task.

```sh
npm test
```
