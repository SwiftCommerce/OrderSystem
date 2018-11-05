# Order System

## Overview

Order System is a micro-service written in Vapor, a server-side Swift framework, that handles the purchasing of merchandise for an e-commerce platform. It has third-party payments with providers like PayPal and Stripe, order histories for users, guest checkout, and customizable user attributes for any additional features you want to build in.

This service _does not_ manage a store's products and inventory, user accounts, or customer service.

## Setup

Once you have the Order System service forked and downloaded, you will want to do specific configurations so it works with your app.

First, there are a few environment variables you will have to declare and configuration values to set.

### JWT

Since Order System use JWT for authenticating users, you will need to create `JWT_PUBLIC` and `JWT_SECRET` variables, which will be the `n` and `d` values respectively. If you don't have values yet for these variables, you can create them with the OpenSSL command-line tool (instructions from [Google Cloud docs](https://cloud.google.com/iot/docs/how-tos/credentials/keys#generating_an_rs256_key)):

```bash
openssl genrsa -out rsa_private.pem 2048
openssl rsa -in rsa_private.pem -pubout -out rsa_public.pem
```

Note that these values must be RSA compatible.

### PayPal

If you are going to keep the built-in PayPal integration, you will need to set the `PAYPAL_CLIENT_ID` and `PAYPAL_CLIENT_SECRET` variables. You can see where to get these values in the [skelpo/PayPal package README](https://github.com/skelpo/PayPal#configuration)

In the `Sources/App/Configuration/OrderService.swift` file, you will need to set the `paypalPayeeEmail`, `paypalRedirectApprove`, `paypalRedirectCancel` to replace the default values with the ones your app will use.

### Stripe

If you are going to use the built-in Stripe integration, you will need to set the `STRIPE_KEY` or `STRIPE_TEST_KEY` variables depending on your environment.

### ProductManager

The Order System service relies on a different service to handle the store's products and inventory. To connect to it, you will need to have a service that has a URL structure of `uri/:id` and returns a JSON structure that follows this pattern:

```
{
	"id": Int?,
	"sku": String,
	"name": String,
	"description": String?,
	"prices": ([Price]?) [
		{
			"id": Int?,
			"cents": Int,
			"active": Bool,
			"currency": String
		}
	]
}
```

Skelpo provides a [`ProductManager`](https://github.com/skelpo/ProductManager) that handles this that you can use.

The `uri` variable needs to be set to the route of the product management service you are hosting that a product can be accessed from when a forward slash and the product's ID (`/:id`) are appended to the route path. The variable is in the `Sources/App/Configuration/ProductManager.swift` file.

### MySQL Database

Order System is built on a MySQL database. The configuration is in the `Sources/App/Configuration/databases.swift` file.

The configuration values are fetched from the environment variables used by [Vapor Cloud](https://vapor.cloud/) with development variables as the default values. If you want a dev MySQL database to connect to the service without any changes, it will need to:

 - Have `localhost` as its hostname.
 - Created under the user `root`.
 - Its password set to `password`.
 - Its name is `order_system`.

Order System assumes the database will always be on port `3306`.


