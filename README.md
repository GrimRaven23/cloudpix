# CloudPix - Serverless Image Processing Platform

![Architecture](docs/architecture.png)

## 🚀 Overview

CloudPix is a production-grade serverless image processing platform built on AWS infrastructure. It automatically resizes, optimizes, and transforms images using event-driven architecture with Lambda functions triggered by S3 uploads.

## 🏗️ Architecture

### AWS Services Used:
1. **Amazon S3** - Object storage for original and processed images
2. **AWS Lambda** - Serverless compute for image processing
3. **IAM** - Identity and access management
4. **CloudWatch** - Monitoring and logging

### Data Flow:
```
User Upload → S3 (Original) → Lambda Trigger → Process Image → S3 (Processed) → Display
```

## 🛠️ Technologies

- **Backend**: Python 3.11 (AWS Lambda)
- **Image Processing**: Pillow (PIL)
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Infrastructure**: AWS (S3, Lambda, IAM, CloudWatch)
- **Version Control**: Git & GitHub
- **Deployment**: Manual/GitHub Actions

## 📋 Features

- ✅ Drag-and-drop image upload
- ✅ Automatic image resizing (max 800x800px)
- ✅ JPEG optimization (85% quality)
- ✅ Real-time processing status
- ✅ Side-by-side comparison
- ✅ File size reduction statistics
- ✅ Download processed images
- ✅ Responsive design
- ✅ Professional UI/UX

## 🚀 Deployment Instructions
 
 ### Prerequisites
 - AWS Account
 - AWS CLI configured
 - Terraform installed
 - Zip utility installed (`sudo apt-get install zip`)
 
 ### Automated Deployment
 
 We have provided a `deploy.sh` script to automate the entire deployment process.
 
 1. **Clone Repository**
    ```bash
    git clone https://github.com/yourusername/serverless-image-processor.git
    cd serverless-image-processor
    ```
 
 2. **Run Deployment Script**
    ```bash
    chmod +x deploy.sh
    ./deploy.sh
    ```
 
    This script will:
    - Package the Lambda function
    - Create all AWS resources (S3, Lambda, IAM) using Terraform
    - Configure the Frontend with the new Bucket names
    - Upload the Frontend to the S3 Website bucket
    - Output your live Website URL
 
 3. **Access Your App**
    - Click the URL provided at the end of the script!


## 🧪 Testing

### Test Lambda Function
```bash
# Upload test image
aws s3 cp test-image.jpg s3://your-name-original-images-2024/

# Check CloudWatch logs
aws logs tail /aws/lambda/ImageProcessor --follow
```

### Test Frontend
```bash
cd frontend
python3 -m http.server 8000
# Open http://localhost:8000
```

## 📊 Monitoring

### CloudWatch Metrics
- Lambda execution duration
- Error rates
- Invocation count
- S3 bucket metrics

### View Logs
```bash
aws logs tail /aws/lambda/ImageProcessor --follow
```

## 💰 Cost Estimation

| Service | Free Tier | Monthly Cost (After) |
|---------|-----------|---------------------|
| S3 | 5GB storage | $0.023/GB |
| Lambda | 1M requests | $0.20/1M requests |
| CloudWatch | 5GB logs | $0.50/GB |

**Estimated Monthly Cost**: ~$0-5 for typical usage

## 🔒 Security

- S3 buckets use IAM policies for access control
- Lambda function has least-privilege permissions
- CORS configured for web access
- No sensitive data stored in code

## 📈 Performance

- Average processing time: 2-5 seconds
- Supported formats: JPG, PNG, GIF, WebP
- Max file size: 10MB
- Output format: JPEG (optimized)

## 🐛 Troubleshooting

### Upload fails
- Check bucket permissions in IAM
- Verify CORS configuration
- Check bucket names in config

### Lambda timeout
- Increase timeout in Lambda settings
- Check Pillow layer is attached
- Verify IAM role permissions

### Image not processing
- Check CloudWatch logs for errors
- Verify S3 trigger is configured
- Test Lambda function manually

## 📚 Project Structure

```
serverless-image-processor/
├── frontend/
│   └── index.html          # Main web interface
├── lambda/
│   └── image_processor.py  # Lambda function code
├── docs/
│   └── architecture.png    # Architecture diagram
├── README.md               # This file
└── .gitignore             # Git ignore rules
```

## 👨‍💻 Author

**Your Name**  
Cloud Computing Final Project  
Course: Introduction to Cloud Computing  
Date: December 2024

## 📄 License

This project is for educational purposes as part of a university course.

## 🙏 Acknowledgments

- AWS Documentation
- Pillow (PIL) Library
- Professor [Name]
- Cloud Computing Course Materials

## 🔗 Links

- [AWS Lambda Docs](https://docs.aws.amazon.com/lambda/)
- [S3 Documentation](https://docs.aws.amazon.com/s3/)
- [Pillow Documentation](https://pillow.readthedocs.io/)

---

**Built Using AWS Serverless Architecture**
