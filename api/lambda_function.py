import json
import boto3

def lambda_handler(event, context):
    client = boto3.client('dynamodb', region_name='ap-southeast-1')
    data = json.loads(event['body'])

    response = client.update_item(
        TableName=data["table"],
        Key={
            "url": {
                'S': data["url"]
                }
            },
        UpdateExpression='SET visits = if_not_exists(visits, :start) + :inc',
        ExpressionAttributeValues={
            ':inc': {'N': '1'},
            ':start': {'N': '0'},
            },
        ReturnValues="UPDATED_NEW"
    )

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Content-Type': 'application/json'
        },
        'body': json.dumps(response["Attributes"]["visits"]["N"])
    }
