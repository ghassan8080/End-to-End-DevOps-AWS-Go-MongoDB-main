terraform {
  required_version = ">= 1.0"

  required_providers {
    # Use AWS provider v3.x for compatibility with the module and resources
    # Bump to match module requirements (eks module requires aws >= 6.23)
    aws        = ">= 6.23"
    kubernetes = "~> 2.10"
    helm       = "~> 2.5"
    google     = "~> 4.34"
  }
}
