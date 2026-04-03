import json


def handler(event, context):
    print(f"Event: {json.dumps(event)}")

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "message": "Hello from Lambda!",
            "path": event.get("rawPath", "/"),
            "method": event.get("requestContext", {}).get("http", {}).get("method", "UNKNOWN")
        })
    }
