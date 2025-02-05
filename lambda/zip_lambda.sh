# Step 1: Install dependencies into the same folder
pip install -r ../requirements.txt -t .

# Step 2: Zip everything for deployment
zip -r lambda_function.zip .