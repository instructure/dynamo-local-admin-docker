# dynamo-local-admin

This project builds a Docker image with [DynamoDB Local](http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.html) and [dynamo-admin](https://github.com/aaronshaf/dynamodb-admin) installed and hooked up.

## Usage

```
docker pull instructure/dynamo-local-admin
docker run -p 8000:8000 -it --rm instructure/dynamo-local-admin
```

Now open http://localhost:8000/ in your browser, and you'll see the admin UI. You can also hit port 8000 with Dynamo API requests:

```
AWS_ACCESS_KEY_ID=key AWS_SECRET_ACCESS_KEY=secret aws --region us-east-1 dynamodb --endpoint http://localhost:8000/ list-tables
```

A proxy is included which differentiates between Dynamo requests and web requests, and proxies to the appropriate server.

## Why?

It's just very convenient if you do a lot of Dynamo development.

## Dinghy Users

If you're using Dinghy and its automatic proxy, `VIRTUAL_HOST` and `VIRTUAL_PORT` are already set, so you don't have to specify any ports in the `docker run` and can just open http://dynamo.docker/ in your browser.
