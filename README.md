# LabelStudio tooling

Set of tools and scripts to leverage `LabelStudio` to
import/export/check annotations made by CV models.

## Workflows

### Import and Review ultralytics YOLO predictions


1. Import the ultralytics dataset

```bash
uv run label-studio-converter import yolo \
  -i ./datasets/ultralytics/coco8/ \
  -o data/import/ls-tasks.json \
  --image-root-url "http://localhost:8000/ultralytics/coco8/images/"
```

2. Start the label-studio environment

```bash
docker compose up
```

3. Follow the instructions from the import command to import data into label
   studio

### Export LabelStudio Annotations from LabelStudio in YOLO format

1. Select the Export button in the Project > YOLO with Images
2. All the label txt files have their updated bbox coords

## Scaffolding

- The datasets are located in `./datasets` and the folder will be served
statically by the HTTP server.
- `./mydata` is used by label-studio to store data locally.
- `./docker` contains the Dockerfiles

## YOLO Datasets

This is the coco8-import dataset:

```txt
.
├── classes.txt
├── images
│   ├── 000000000009.jpg
│   ├── 000000000025.jpg
│   ├── 000000000030.jpg
│   └── 000000000034.jpg
└── labels
    ├── 000000000009.txt
    ├── 000000000025.txt
    ├── 000000000030.txt
    └── 000000000034.txt
```

The classes.txt file should contain all classes in the right order:

```txt
person
bicycle
car
motorcycle
airplane
...
teddy bear
hair drier
toothbrush
```

## Commands

Start label-studio and a local HTTP server to serve images from a dataset:

```bash
docker compose up
```

__Note__: Label Studio is started on port 8080 and the HTTP static server on
port 8000.

Import a Ultralytics dataset:

```bash
uv run label-studio-converter import yolo \
  -i ./datasets/ultralytics/coco8/ \
  -o data/import/ls-tasks.json \
  --image-root-url "http://localhost:8000/ultralytics/coco8/images/"
```

__Note__: It will generate a `ls-tasks.json` and a `ls-tasks.label_config.xml`
files that can be imported in a label studio project.

## Terraform Deployment

Deploy LabelStudio to AWS using the provided Terraform configuration:

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) installed
- AWS CLI configured with appropriate credentials
- An AWS account with necessary permissions

### Deployment Steps

1. **Navigate to the terraform directory:**
   ```bash
   cd terraform/
   ```

2. **Copy and configure variables:**
   ```bash
   cp terraform.template.tfVars terraform.tfVars
   ```
   
   Edit `terraform.tfVars` with your values:
   - `s3_bucket_name`: Unique S3 bucket name for storing LabelStudio data
   - `db_username`: PostgreSQL database username
   - `db_password`: Secure PostgreSQL database password
   - `db_name`: Database name (default: labelstudio)
   - `labelstudio_username`: Admin username for LabelStudio
   - `labelstudio_password`: Admin password for LabelStudio
   - `labelstudio_token`: Random token for API access
   - `aws_region`: AWS region (default: us-west-2)
   - `instance_type`: EC2 instance type (default: t3.small)

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Plan the deployment:**
   ```bash
   terraform plan -var-file="terraform.tfVars"
   ```

5. **Apply the configuration:**
   ```bash
   terraform apply -var-file="terraform.tfVars"
   ```

6. **Access LabelStudio:**
   After deployment, use the output `instance_ip` to access LabelStudio at `http://<instance_ip>`

### Infrastructure Components

The Terraform configuration creates:
- **EC2 Instance**: Runs LabelStudio in Docker container
- **RDS PostgreSQL**: Database for LabelStudio data
- **S3 Bucket**: Storage for uploaded files and exports
- **IAM Roles/Policies**: Secure access between services
- **Security Groups**: Network access controls

### Cleanup

To destroy the infrastructure:
```bash
terraform destroy -var-file="terraform.tfVars"
```

## Resources

- [LabelStudio Blog: Importing Local YOLO Pre-Annotated Images to Label Studio](https://labelstud.io/blog/tutorial-importing-local-yolo-pre-annotated-images-to-label-studio/)
