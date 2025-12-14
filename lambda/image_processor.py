import json
import boto3
import os
from PIL import Image
import io

s3_client = boto3.client('s3')

TARGET_BUCKET = 'cloudpix'
MAX_SIZE = (800, 800)

def lambda_handler(event, context):
    try:
        # Get bucket and file info from S3 event
        source_bucket = event['Records'][0]['s3']['bucket']['name']
        source_key = event['Records'][0]['s3']['object']['key']
        
        print(f"Processing: {source_key} from {source_bucket}")
        
        # Download image
        response = s3_client.get_object(Bucket=source_bucket, Key=source_key)
        image_data = response['Body'].read()
        
        # Open with Pillow
        img = Image.open(io.BytesIO(image_data))
        
        print(f"Original size: {img.size}, format: {img.format}")
        
        # Convert RGBA to RGB if needed
        if img.mode in ('RGBA', 'LA', 'P'):
            background = Image.new('RGB', img.size, (255, 255, 255))
            if img.mode == 'P':
                img = img.convert('RGBA')
            background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
            img = background
        
        # Resize (maintains aspect ratio)
        img.thumbnail(MAX_SIZE, Image.Resampling.LANCZOS)
        
        print(f"Resized to: {img.size}")
        
        # Save to buffer
        buffer = io.BytesIO()
        img.save(buffer, format='JPEG', quality=85, optimize=True)
        buffer.seek(0)
        
        # Create new filename
        name_without_ext = os.path.splitext(source_key)[0]
        new_key = f"processed-{name_without_ext}.jpg"
        
        # Upload to processed bucket
        s3_client.put_object(
            Bucket=TARGET_BUCKET,
            Key=new_key,
            Body=buffer,
            ContentType='image/jpeg'
        )
        
        print(f"Success! Uploaded: {new_key}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Success',
                'processed_image': new_key
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

