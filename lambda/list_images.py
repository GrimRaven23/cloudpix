import json
import boto3
import os

s3_client = boto3.client('s3')

PROCESSED_BUCKET = os.environ.get('PROCESSED_BUCKET_NAME')
REGION = os.environ.get('REGION', 'us-east-1')

def lambda_handler(event, context):
    try:
        print(f"Listing bucket: {PROCESSED_BUCKET}")
        
        response = s3_client.list_objects_v2(
            Bucket=PROCESSED_BUCKET,
            MaxKeys=100
        )
        
        files = []
        if 'Contents' in response:
            # Sort by last modified (newest first)
            contents = sorted(response['Contents'], key=lambda x: x['LastModified'], reverse=True)
            
            for obj in contents:
                files.append({
                    'key': obj['Key'],
                    'size': obj['Size'],
                    'last_modified': obj['LastModified'].isoformat(),
                    'url': f"https://{PROCESSED_BUCKET}.s3.{REGION}.amazonaws.com/{obj['Key']}"
                })
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'files': files})
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }
