import json
import boto3
import unittest
from moto import mock_dynamodb

from lambda_function import lambda_handler

DYNAMODB_TABLE_NAME = "sites"
EXAMPLE_SITE = "example.com"

@mock_dynamodb
class TestLambdaFunction(unittest.TestCase):

    def setUp(self):
        self.dynamodb = boto3.client("dynamodb")
        try:
            self.table = self.dynamodb.create_table(
                TableName=DYNAMODB_TABLE_NAME,
                KeySchema=[{'AttributeName': 'url', 'KeyType': 'HASH'}],
                AttributeDefinitions=[{'AttributeName': 'url', 'AttributeType':
                    'S'}],
                ProvisionedThroughput={'ReadCapacityUnits': 5, 'WriteCapacityUnits':
                    5}
            )
        except self.dynamodb.exceptions.ResourceInUseException:
            self.table = boto3.resource('dynamodb').Table(DYNAMODB_TABLE_NAME)

        self.dynamodb.put_item(
            TableName=DYNAMODB_TABLE_NAME,
            Item={
                "url": {
                    'S': EXAMPLE_SITE
                }
            }
        )

    def tearDown(self):
        self.table = None
        self.dynamodb = None

    def test_lambda_handler(self):
        payload = {"table": DYNAMODB_TABLE_NAME, "url": EXAMPLE_SITE}
        test_event = {
            "body": json.dumps(payload)
        }

        response = lambda_handler(event=test_event, context={})
        self.assertEqual(response["statusCode"], 200)
        self.assertEqual(response["body"][1], '1') # remove quotes within string

if __name__ == '__main__':
    unittest.main()
