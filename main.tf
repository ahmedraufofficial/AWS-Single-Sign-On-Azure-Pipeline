provider "aws" {
  region     = "us-east-1"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

resource "aws_iam_saml_provider" "saml" {
  name                   = "CLIENT-SSO"
  saml_metadata_document = file("/certificate.xml")
}

resource "aws_iam_policy" "organization-policy" {
  name        = "Organizations-Limit-Access"
  description = "Organizations Limit Access"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "organizations:InviteAccountToOrganization",
                "organizations:DeclineHandshake",
                "organizations:ListRoots",
                "organizations:ListDelegatedServicesForAccount",
                "organizations:DescribeAccount",
                "organizations:UntagResource",
                "organizations:CreateAccount",
                "organizations:DescribePolicy",
                "organizations:ListChildren",
                "organizations:TagResource",
                "organizations:EnableAWSServiceAccess",
                "organizations:ListCreateAccountStatus",
                "organizations:DescribeResourcePolicy",
                "organizations:DescribeOrganization",
                "organizations:CreateGovCloudAccount",
                "organizations:EnableAllFeatures",
                "organizations:EnablePolicyType",
                "organizations:UpdatePolicy",
                "organizations:DescribeOrganizationalUnit",
                "organizations:AttachPolicy",
                "organizations:RegisterDelegatedAdministrator",
                "organizations:MoveAccount",
                "organizations:DescribeHandshake",
                "organizations:CreatePolicy",
                "organizations:DescribeCreateAccountStatus",
                "organizations:CreateOrganization",
                "organizations:ListPoliciesForTarget",
                "organizations:DescribeEffectivePolicy",
                "organizations:ListTargetsForPolicy",
                "organizations:ListTagsForResource",
                "organizations:DetachPolicy",
                "organizations:ListAWSServiceAccessForOrganization",
                "organizations:AcceptHandshake",
                "organizations:ListPolicies",
                "organizations:ListDelegatedAdministrators",
                "organizations:ListAccountsForParent",
                "organizations:ListHandshakesForOrganization",
                "organizations:ListHandshakesForAccount",
                "organizations:CancelHandshake",
                "organizations:ListAccounts",
                "organizations:UpdateOrganizationalUnit",
                "organizations:PutResourcePolicy",
                "organizations:ListParents",
                "organizations:ListOrganizationalUnitsForParent",
                "organizations:CreateOrganizationalUnit"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "account:PutAlternateContact",
                "account:GetAlternateContact",
                "account:GetContactInformation",
                "account:PutContactInformation",
                "account:ListRegions",
                "account:EnableRegion",
                "account:DisableRegion"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": "organizations.amazonaws.com"
                }
            }
        }
    ]
  })
}

resource "aws_iam_policy" "user-policy" {
  name        = "AzureAD_SSOUserRole_Policy"
  description = "Azure AD SSO User Role Policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:ListRoles",
            ],
            "Resource": "*"
        }
    ]
})
}

resource "aws_iam_role" "bespin-admin" {
  name               = "Bespin-Admin"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement: [
            {
                "Effect": "Allow",
                "Action": "sts:AssumeRoleWithSAML",
                "Principal": {
                    "Federated": "arn:aws:iam::${var.account}:saml-provider/CLIENT-SSO"
                },
                "Condition": {
                    "StringEquals": {
                        "SAML:aud": [
                            "https://signin.aws.amazon.com/saml"
                        ]
                    }
                }
            }
        ]
  })
}

resource "aws_iam_role_policy_attachment" "bespin-admin-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.bespin-admin.name
}

resource "aws_iam_role" "bespin-finops" {
  name               = "Bespin-Finops"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.account}:saml-provider/CLIENT-SSO"
        }
        Action    = "sts:AssumeRoleWithSAML"
        Condition = {
          StringEquals = {
            "SAML:aud" = ["https://signin.aws.amazon.com/saml"]
          }
        }
      }
    ]
  })
  depends_on = [ aws_iam_policy.organization-policy ]
}

data "aws_iam_policy" "support_user" {
  arn = "arn:aws:iam::aws:policy/job-function/SupportUser"
}

data "aws_iam_policy" "billing" {
  arn = "arn:aws:iam::aws:policy/job-function/Billing"
}

data "aws_iam_policy" "readonly_access" {
  arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy" "aws_marketplace_full_access" {
  arn = "arn:aws:iam::aws:policy/AWSMarketplaceFullAccess"
}

data "aws_iam_policy" "aws_organizations_full_access" {
  arn = "arn:aws:iam::aws:policy/AWSOrganizationsFullAccess"
}

data "aws_iam_policy" "aws_marketplace_seller_full_access" {
  arn = "arn:aws:iam::aws:policy/AWSMarketplaceSellerFullAccess"
}

resource "aws_iam_role_policy_attachment" "custom_role_attachment" {
  role       = aws_iam_role.bespin-finops.name
  policy_arn = aws_iam_policy.organization-policy.arn
}

resource "aws_iam_role_policy_attachment" "support_user-policy-attachment" {
  role       = aws_iam_role.bespin-finops.name
  policy_arn = data.aws_iam_policy.support_user.arn
}

resource "aws_iam_role_policy_attachment" "billing-policy-attachment" {
  role       = aws_iam_role.bespin-finops.name
  policy_arn = data.aws_iam_policy.billing.arn
}

resource "aws_iam_role_policy_attachment" "readonly_access-policy-attachment" {
  role       = aws_iam_role.bespin-finops.name
  policy_arn = data.aws_iam_policy.readonly_access.arn
}

resource "aws_iam_role_policy_attachment" "aws_marketplace_full_access-policy-attachment" {
  role       = aws_iam_role.bespin-finops.name
  policy_arn = data.aws_iam_policy.aws_marketplace_full_access.arn
}

resource "aws_iam_role_policy_attachment" "aws_organizations_full_access-policy-attachment" {
  role       = aws_iam_role.bespin-finops.name
  policy_arn = data.aws_iam_policy.aws_organizations_full_access.arn
}

resource "aws_iam_role_policy_attachment" "aws_marketplace_seller_full_access-policy-attachment" {
  role       = aws_iam_role.bespin-finops.name
  policy_arn = data.aws_iam_policy.aws_marketplace_seller_full_access.arn
}

resource "aws_iam_group" "CLIENT-group" {
  name = "CLIENT-SSO"
}

resource "aws_iam_group_policy_attachment" "group-policy" {
  group      = aws_iam_group.CLIENT-group.name
  policy_arn = aws_iam_policy.user-policy.arn
  depends_on = [ aws_iam_policy.user-policy ]
}

resource "aws_iam_user" "CLIENT-user" {
  name = "CLIENT-SSO"
  depends_on = [ aws_iam_group.CLIENT-group ]
}

resource "aws_iam_user_group_membership" "membership" {
  user    = aws_iam_user.CLIENT-user.name
  groups  = [aws_iam_group.CLIENT-group.name]
}


output "access_key" {
  value = aws_iam_access_key.CLIENT-keys.id
}

output "secret_key" {
  value = aws_iam_access_key.CLIENT-keys.secret
  sensitive = true
}

resource "aws_iam_access_key" "CLIENT-keys" {
  user = aws_iam_user.CLIENT-user.name
}
