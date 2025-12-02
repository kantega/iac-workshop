# Getting started

## IaC AWS account
You should all have been given access to the `IaC Workshop` aws account.

To find it:
1. Go to the microsoft [Apps Dashboard](https://myapps.microsoft.com/)
2. Log in with Kantega SSO
3. Here your should see the `AWS` app under Kantega.
4. Click on it to be redirected to the AWS access portal.
5. Here you should see the `IaC Workshop` app.
6. By clicking on it, you should see that you have access to `PowerUserAccess` role for that account.
7. Click on the role to log in with it.

## Install AWS CLI
To install the AWS Command Line Interface (CLI), run the following command in your terminal:

```bash
brew install awscli
```

## Configure AWS SSO
After installing the AWS CLI, configure it with your AWS credentials by running:
```bash
aws configure sso
```

And give the following details when prompted:
- SSO session name: `iacws`
- SSO start URL: `https://d-c36770014c.awsapps.com/start`
- SSO region: `eu-north-1`
- SSO registration scopes [sso:account:access]: Press enter to accept `sso:account:access`

- CLI default output format (json if not specified) [None]: Press enter to accept `json`
- Profile name [PowerUserAccess-************]: `iacws`

You can find this config in the `~/.aws/config` file. So if you managed to make a mistake, you can always remove the config from the file and start over.

## Login with AWS SSO
To log in using AWS SSO, run the following command:
```bash
aws sso login --profile iacws
```

## Install OpenTofu cli
To install the OpenTofu CLI, run the following command in your terminal:

```bash
brew install opentofu
```

That's all!


# Setting up the state bucket
We will now set up our remote state backend and provider configuration for OpenTofu.

In the start we have a bit of a chicken and egg problem, as we want to store our terraform state in an S3 bucket, but we need terraform to create the S3 bucket for us.

## Creating a provider configuration

We create `_provider.tf` file to specify that we will be using the `opentofu/aws` provider and configure it to use the `iacws` profile and the `eu-north-1` region.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20"
    }
  }
}

provider "aws" {
  region  = "eu-north-1"
  profile = "iacws"
}
```

Here we are using `hashicorp/aws` as the provider source, which is the official AWS provider maintained by HashiCorp.
There are also providers for other cloud providers like Azure and GCP. You can see which are available at https://search.opentofu.org/providers.


## Create an S3 bucket to store state

We will then create a `_state_backend.tf` to create an S3 bucket to store our terraform state files.
```hcl
# S3 bucket for storing Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "iacws-state-test"

  tags = {
    Name        = "OpenTofu State Bucket"
    Environment = "Test"
    ManagedBy   = "OpenTofu"
  }
}

# Enable versioning for state history
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

## The OpenTofu commands

### Initialize OpenTofu
The next step is to initialize our opentofu configuration by running `tofu init` in the terminal, which will then download the required providers.

### Review the planned changes
You can then run `tofu plan` to see what changes will be made to the existing configuration. OpenTofu will perform some validation to see that the configuration is valid, but some validations will only occur during the apply phase.

### Apply the changes
Finally, run `tofu apply` to apply the changes to your infrastructure. OpenTofu will show you a summary of the changes that will be made and ask for your confirmation before proceeding.

While waiting for user input the workspace will be locked to prevent other users from making changes at the same time. Once the changes are applied, the workspace will be unlocked.

## Remote state backend
We have now provisioned a S3 bucket in AWS. But for the time being, we are using local state, as evident by our new terraform.tfstate file that now exists in our working directory.

To start using the S3 bucket to store our remote state, we need to set up a `_backend.tf` with the following configuration:

```hcl
terraform {
  backend "s3" {
    bucket       = "iacws-state-test"
    key          = "test/terraform.tfstate"
    region       = "eu-north-1"
    profile      = "iacws"
    use_lockfile = true
    encrypt      = true
  }
}
```

Here we specify:
- `bucket`: The name of the S3 bucket we created earlier.
- `key`: The path within the bucket where the state file will be stored.
- `region`: The AWS region where the bucket is located.
- `profile`: The AWS CLI profile to use for authentication.
- `use_lockfile`: Enables state locking to prevent concurrent modifications.
- `encrypt`: Ensures that the state file is encrypted at rest.


After creating the file, we run `tofu init --migrate-state` to move the state storage from local to the S3 bucket.

After we have done the miration, we can simply delete the local *.tfstate* files, as they are no longer needed.

## Default tags (... and locals)
When managing cloud resources with IaC, it is often a good idea to tag them as managed by OpenTofu/Terraform. This helps to avoid confusion about which resources are managed by IaC and which are manually managed.
And a good way to achieve that is with the help of default tags.

And this is also a good place to introduce the usage of locals.

We create a file called `_locals.tf` with the following content:
```hcl
locals {
  environment = "test"
}
```

And then we add the following to our provider configuration in `_provider.tf`:
```hcl
provider "aws" {
  # ... existing configuration ...
  default_tags {
    tags = {
      Environment = "aws-${local.environment}"
      Managed_by  = "OpenTofu"
    }
  }
}

```

If you now run `tofu plan` and `tofu apply`, you will see that the state bucket will be updated in-place to include the new tags.

## The project we will be working on
In this workshop we will set up a simple system that will process files uploaded to a s3 bucket and store the data in a DynamoDB table.

So we will be making a S3 bucket, which will notify a Lambda function when a new file is uploaded.
The Lambda function will then read the file from the S3 bucket, process the data, and store it in a DynamoDB table.


# Create your own workspace.
Under the `terraform/environemnts` folder, you will see three different folders representing different environments: `test`, `stage`, and `prod`.
We will be focusing on the `test` environment for this workshop.

To avoid state collisions, each user will create their own workspace under the `test` environment following the steps:
1. Navigate to the `terraform/environments/test` folder.
2. Create a new folder with your username (e.g. `jolan`).
3. Create a `_provider.tf` file inside your newly created folder with the following content:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "opentofu/aws"
      version = "~> 6.20"
    }
  }
}

provider "aws" {
  region  = "eu-north-1"
  profile = "iacws"
}
```

This tells OpenTofu that we will be using the hashicorp/aws provider and configures it to use the `iacws` sso profile and the `eu-north-1` region.
If you were using Azure or GCP, you would configure their respective providers here instead.

4. Create a `_backend.tf` file inside your newly created folder with the following content:
```hcl
terraform {
  backend "s3" {
    bucket       = "iacws-state-test"
    key          = "test/<username>/terraform.tfstate"
    region       = "eu-north-1"
    profile      = "iacws"
    use_lockfile = true
    encrypt      = true
  }
}
```

This will configure OpenTofu to use the `iacws-state-test` bucket we created earlier to store the state for your workspace.

The `_` underscore in front of the filename is just a personal preference to indicate that this is just part of the terraform rigging.

NB: Replace `<username>` with your actual username.

When this is done, you can run the `tofu init` command to initialize your workspace.

# 1. Create a s3 bucket
On its own a s3 bucket is one of the simplest resources to create in AWS. So we will start by creating one in our newly created workspace.

You can create a bucket by using the [aws_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/6.20.0/docs/resources/s3_bucket) resource.

**And remember we have created a lambda execution role that is only allowed to access resources that start with an `iacws-` prefix. And to avoid conflicts, it is recommended to also add your name in the resource name as well. I.e. `iacws-jolan-input`. This goes for all resources we create in this workshop.**

Create a file called `s3_bucket.tf` in your workspace with the relevant terraform code, and run `tofu plan` to view the tofu plan or `tofu apply` to create the bucket in AWS.

# 2. Related configuration resources
Quite often configuration of a resource is managed as a separate resource in opentofu. For s3 buckets, there are several related resources that you can use to configure your bucket further.

We will be using a couple of them to configure our bucket properly:
- [aws_s3_bucket_versioning](https://registry.terraform.io/providers/hashicorp/aws/6.20.0/docs/resources/s3_bucket_versioning), which allows you to enable versioning on your bucket.
- [aws_s3_bucket_server_side_encryption_configuration](https://registry.terraform.io/providers/hashicorp/aws/6.20.0/docs/resources/s3_bucket_server_side_encryption_configuration), which allows you to enable server-side encryption on your bucket.
- [aws_s3_bucket_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/6.20.0/docs/resources/s3_bucket_public_access_block), which allows you to limit public access to your bucket.

# 3. Create a DynamoDB table
Next, we will create a DynamoDB table to store our data.

Creating a DynamoDB table is just as easy as creating a s3 bucket. You can create one using the [aws_dynamodb_table](https://registry.terraform.io/providers/hashicorp/aws/6.20.0/docs/resources/dynamodb_table) resource in a separate `dynamodb.tf` file in your workspace.

Some important settings we need to configure for our table are:
```
billing_mode = "PAY_PER_REQUEST" # On-demand pricing, no capacity planning needed
hash_key     = "id"

attribute {
    name = "id"
    type = "S"
}

attribute {
    name = "s3Key"
    type = "S"
}

global_secondary_index {
    name            = "S3KeyIndex"
    hash_key        = "s3Key"
    projection_type = "ALL"
}
```

# 4. Create a Lambda function
Next we will create the lambda that will do the actual processing of the files uploaded to the s3 bucket.

For this we will create a `lambda.tf` file in our workspace and use the [aws_lambda_function](https://registry.terraform.io/providers/hashicorp/aws/6.20.0/docs/resources/lambda_function) resource.

And a lambda needs to set the execution role it will run with. In this case we have already created a role we will use, named `iacws-lambda-role`

To reference this role, we can use a `data` block like this:
```hcl
data "aws_iam_role" "lambda_execution_role" {
  name = "iacws-lambda-role"
}
```

And then we can reference it in the lambda function resource like this:
```hcl

role = data.aws_iam_role.lambda_execution_role.arn

```

Remember to set the following settings:
- s3_bucket should be `iacws-package-bucket`
- s3_key should be `s3-to-dynamo/package.zip`
- Runtime should be `nodejs22.x`
- Handler should be `index.handler`
- Environment variable `DYNAMODB_TABLE_NAME` should be set to the name of your DynamoDB table.

If wanted we can also configure the lambda logging to CloudWatch by adding a `aws_cloudwatch_log_group` resource.
```hcl
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.<your_function>.function_name}"
  retention_in_days = 7
}
```

Here we are just saying that we want a 7 day retention on the logs.

# 5. Additional configurations to trigger the lambda
We also need to set up the S3 bucket to notify the lambda function when a new file is uploaded.

To do this we need to create a lambda permission resource and an s3 bucket notification resource.
```hcl
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.<your_function>.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.<your_bucket>.arn
}
```

And the s3 bucket notification resource:
```hcl
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.<your_bucket>.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.<your_function>.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
```

Here we need to replace `<your_function>` and `<your_bucket>` with the actual names of our lambda function and s3 bucket resources.

# TEST THE THING!
Now that we have provisioned all the necessary resources, feel free to test the setup by uploading a json file to your s3 bucket.

You will either be able to enjoy a new entry in the dynamo table or some fresh new error messages in the cloudwatch logs!


# Modules
Modules are a way to organize and reuse terraform code. They allow you to group related resources together and manage them as a single unit.

Normally we would create a module folder at a more central location (for instance directly under the environments folder), but to avoid everony stepping on each other toes, we will create the module directly in our own workspace for this workshop.

Let's create a module for our lambda function.

1. Create a folder called `modules` in your workspace.
2. Inside the `modules` folder, create another folder called `lambda_function`.
3. Inside the `lambda_function` folder, create a file called `main.tf` with
4. Inside the `main.tf` file, add the following code:

```hcl

data "aws_iam_role" "lambda_execution_role" {
  name = "iacws-lambda-role"
}

locals {
  username = "jolan" # Replace with your username
  prefix = "iacws-${local.username}"
  s3_bucket = "iacws-package-bucket"
  default_handler = "index.handler"
  default_runtime = "nodejs22.x"
}

resource "aws_lambda_function" "this" {
  function_name = "${local.prefix}-${var.function_name}"
  s3_bucket     = local.s3_bucket
  s3_key        = "${var.package_name}/package.zip"
  handler       = local.default_handler
  runtime       = local.default_runtime
  role          = data.aws_iam_role.lambda_execution_role.arn
    environment {
        variables = var.environment_variables
    }
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  count = var.enable_logging ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = 7
}
```

5. Create a file called `variables.tf` in the `lambda_function` folder with the following content:

```hcl
variable "function_name" { 
  description = "The name of the lambda function"
  type        = string
}
variable "package_name" {
  description = "The name of the package in the s3 bucket"
  type        = string
}
variable "environment_variables" {
    description = "A map of environment variables for the lambda function"
    type        = map(string)
    default     = {}
}
variable "enable_logging" {
    description = "Whether to enable CloudWatch logging for the lambda function"
    type        = bool
    default     = true
}
```

6. And finally create a file called `outputs.tf` in the `lambda_function` folder with the following content:

```hcl
output "lambda_function_arn" {
  description = "The ARN of the lambda function"
  value       = aws_lambda_function.this.arn
}
output "lambda_function_name" {
  description = "The name of the lambda function"
  value       = aws_lambda_function.this.function_name
}
```

Let's replace our previous lambda function resource in our workspace with a module call instead.

Remove the previous lambda function and cloudwatch resource from your `lambda.tf` file and replace it with the following module call:

```hcl
module "process_s3_to_dynamo" {
  source = "./modules/lambda_function"
    function_name = "s3-to-dynamo"
    package_name  = "s3-to-dynamo"
    environment_variables = {
        DYNAMODB_TABLE_NAME = aws_dynamodb_table.<your_table>.name
    }
    enable_logging = true
}
```

And to reference the lambda function created by the module in the s3 bucket notification and lambda permission resources, you can use `module.process_s3_to_dynamo.lambda_function_name` and `module.process_s3_to_dynamo.lambda_function_arn` respectively.

See if you can create a module for the s3 bucket as well, with an is_public parameter to conditionally create the `aws_s3_bucket_public_access_block` resource.

Otherwise, feel free to experiment with the modules by adding more parameters or changing the implementation.

## Premade community modules
There are also many premade community modules available that you can use to speed up your development process.

A good resource for finding modules is the [library.tf](https://library.tf/modules) website, which has a large collection of modules for various cloud providers.

I can personally recommend the terraform community modules for AWS.

# Some useful commands
Apart from the basic `tofu init`, `tofu plan`, and `tofu apply` commands, there are a few other useful commands that you might find helpful:
- `tofu fmt`: This command formats your terraform code according to the standard terraform style. It is a good idea to run this command before committing your code to ensure that it is properly formatted.
- `tofu validate`: This command validates your terraform configuration files. It checks for syntax errors and other issues that might prevent your configuration from being applied successfully.
- `tofu destroy`: This command destroys the resources managed by your terraform configuration. Use this command with caution, as it will delete all resources created by your configuration.
- `tofu state list`: This command lists all resources in the current state file. It is useful for checking which resources are being managed by terraform.
- `tofu state mv`: This command moves a resource in the state file. It is useful for renaming resources or moving them between modules.
