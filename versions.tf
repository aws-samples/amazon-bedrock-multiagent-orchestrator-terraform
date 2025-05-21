/**
 * # Terraform and Provider Versions
 *
 * Specifies the required Terraform and provider versions.
 */

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.95.0"
    }
  }
}