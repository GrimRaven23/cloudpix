#!/bin/bash
set -e

echo "🚀 Starting CloudPix Deployment..."

# Function to check command existence
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "❌ Error: $1 is not installed."
        return 1
    fi
}

check_command terraform || exit 1
check_command aws || exit 1
check_command zip || { echo "❌ Zip is missing. Please run 'sudo apt-get install zip'"; exit 1; }

check_command python3 || { echo "❌ Python3 is missing."; exit 1; }

# Install pip if missing
if ! command -v pip3 &> /dev/null; then
    echo "⚠️  pip3 not found. Installing..."
    sudo apt-get install -y python3-pip
fi

# 1. Package Lambda
echo "📦 Packaging Lambda function..."
cd lambda
# Install Pillow locally
pip3 install Pillow -t . --upgrade

# Remove old zip if exists
rm -f function.zip
# Zip everything recursively
zip -r function.zip .
cd ..

# 2. Terraform Apply
echo "🏗️  Applying Terraform configuration..."
cd terraform
terraform init
terraform apply -auto-approve

# 3. Generate Config & Upload Frontend
echo "⚙️  Configuring Frontend..."
# Get outputs using terraform output
ORIGINAL_BUCKET=$(terraform output -raw original_bucket_name)
PROCESSED_BUCKET=$(terraform output -raw processed_bucket_name)
WEBSITE_BUCKET=$(terraform output -raw website_bucket_name)
WEBSITE_URL=$(terraform output -raw website_url)
API_URL=$(terraform output -raw api_url)
REGION=$(terraform output -raw region)

echo "   - Original Bucket: $ORIGINAL_BUCKET"
echo "   - Processed Bucket: $PROCESSED_BUCKET"
echo "   - Website Bucket: $WEBSITE_BUCKET"
echo "   - API URL: $API_URL"

# Create config.json
cat > ../frontend/config.json <<EOF
{
    "ORIGINAL_BUCKET": "$ORIGINAL_BUCKET",
    "PROCESSED_BUCKET": "$PROCESSED_BUCKET",
    "REGION": "$REGION",
    "API_URL": "$API_URL"
}
EOF

echo "📤 Uploading Frontend to $WEBSITE_BUCKET..."
cd ../frontend
# Upload files ensuring they are public
aws s3 sync . s3://$WEBSITE_BUCKET/

# Return to root for Git operations
cd ..

echo ""
echo "🔄 Updating Git Repository..."
# Add all changes (including deploy.sh and terraform)
git add .
# Commit with timestamp
git commit -m "Auto-deploy: $(date)" || echo "Nothing to commit"
# Push to main
git push origin main || echo "⚠️  Git push failed. Please check your credentials or pull first."

echo ""
echo "✅ Deployment & Git Sync Complete!"
echo "--------------------------------------------------"
echo "🌎 Open your website here: $WEBSITE_URL"
echo "--------------------------------------------------"
