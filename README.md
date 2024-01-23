# AWS Single Sign on Access from Azure Enterprise Application

## :abacus: Scope

The purpose of this document is to create an automation workflow that creates a single-sign-on access to AWS account through Azure Enterprise Applications.

## :warning: Prerequisites

Before using this pipeline, ensure you have the following prerequisites:

- Access and Secret key of an AWS IAM user with administrator role and Full IAM access, uploaded to 1Password in a specific format.
- 1Password CLI installed, or Repository to download from.
- Environment to run shell executable file.
- Registered App on Azure with the following permissions:

  | Permission Name                                  | Description                                                   |
  | -------------------------------------------------- | ------------------------------------------------------------- |
  | Application.ReadWrite.All                         | Read and write all applications                               |
  | AppRoleAssignment.ReadWrite.All                    | Manage app permission grants and app role assignments         |
  | Policy.Read.All                                    | Read your organization's policies                             |
  | Policy.ReadWrite.ApplicationConfiguration         | Read and write your organization's application configuration policies |
  | Synchronization.ReadWrite.All                      | Read and write all Azure AD synchronization data              |
  | User.ReadWrite.All                                 | Manage user read and write permissions in Azure AD            |

## :seedling: Solution 

### Pipeline Step 1

- Get an input such as account name from a Bitbucket Pipeline trigger.
- Get AWS account credentials and details from 1Password.
- Pass the credentials and details to an Azure function as body data in a web request.

### Pipeline Step 2

 [AWS SSO AZ FUNCTION](https://github.com/ahmedraufofficial/AWS-Single-Sign-On-Azure-AZFunction-2)

### Pipeline Step 3

- The federation Metadata XML is temporarily downloaded on the container to be used later by AWS.

### Pipeline Step 4

- Using AWS account name and details, download any existing tf.state file of that account in our Bitbucket downloads folder. If no file is found, then a new one is created.

### Pipeline Step 5

- Terraform script is executed:
  - `main.tf`

### Pipeline Step 6

- AWS created IAM user’s access and secret key are returned in the output.
- The tf.state file is uploaded to Bitbucket downloads.
- A new request body is made from the AWS credentials in step 5.
- The body is sent to the same Azure function again which performs:
  - AWS template creation
  - Credential validations
  - Storing credentials in the service principal
  - Creating a synchronization job
  - Starting the job to complete provisioning.

:feather: **Add Users**

Once provisioning is completed, we can make a few API calls to get the app roles and assign them to users using their Principal ID.
