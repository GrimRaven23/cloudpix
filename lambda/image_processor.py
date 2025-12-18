import json
import boto3
import os
from PIL import Image
import io

s3_client = boto3.client('s3')

TARGET_BUCKET = os.environ.get('PROCESSED_BUCKET_NAME')
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
        
        # Process image for ML Compatibility (Standardizing)
        # 1. Convert to RGB (Standardize channels)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # 2. Smart Resize & Pad to Square (Preserve Aspect Ratio)
        # This prepares the image for Neural Network classifiers which often expect square inputs
        target_size = MAX_SIZE
        
        # Calculate aspect maintaining resize
        ratio = min(target_size[0] / img.width, target_size[1] / img.height)
        new_size = (int(img.width * ratio), int(img.height * ratio))
        img = img.resize(new_size, Image.Resampling.LANCZOS)
        
        # Create new square canvas (black background is standard for padding)
        new_img = Image.new("RGB", target_size, (0, 0, 0))
        # Paste centered
        paste_pos = ((target_size[0] - new_size[0]) // 2, (target_size[1] - new_size[1]) // 2)
        new_img.paste(img, paste_pos)
        
        print(f"Processed to ML-Ready Square: {new_img.size}")
        
        # Save to buffer
        buffer = io.BytesIO()
        # Save as JPEG with high quality
        new_img.save(buffer, format='JPEG', quality=90, optimize=True)
        buffer.seek(0)
        
        # Create new filename
        name_without_ext = os.path.splitext(source_key)[0]
        # Adding 'ml-ready' to signify this is processed for machine learning
        new_key = f"processed-{name_without_ext}.jpg"
        
        # Upload to processed bucket
        s3_client.put_object(
            Bucket=TARGET_BUCKET,
            Key=new_key,
            Body=buffer,
            ContentType='image/jpeg',
            Metadata={'processing-type': 'ml-standardized-square'}
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

